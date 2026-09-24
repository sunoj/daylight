#!/usr/bin/env bash
set -euo pipefail
#
# Build, sign, and package the Daylight menu bar app for macOS — with
# optional Sparkle auto-update (appcast generation + EdDSA signing) and
# distribution. Mirrors the sibling project (CMView).
#
# Degrades gracefully:
#   • No Developer ID identity  → ad-hoc signs (-), local-only build.
#   • No Sparkle keys           → skips framework embed + appcast.
#   • No R2 / gh                → skips upload + GitHub release.
#
# Usage:
#   scripts/release-macos.sh [--notarize] [--profile NAME] [--identity ID] [--no-sparkle]
#
# Env:
#   VERSION                          marketing version (else VERSION file, else 2.0.0)
#   BUILD                            monotonic build number (else yyyymmddHHMM)
#   CODESIGN_IDENTITY                Developer ID Application identity
#   SPARKLE_PUBLIC_ED_KEY / _FILE    EdDSA pub key (else packaging/SparklePublicEDKey.txt)
#   SPARKLE_FEED_URL / _FILE         appcast URL (else packaging/SparkleFeedURL.txt)
#   SPARKLE_EDDSA_KEYCHAIN_ACCOUNT   account for generate_appcast/sign_update
#   SPARKLE_ED_KEY_FILE              private-key file (CI signing without Keychain)
#   R2_BUCKET / CLOUDFLARE_ACCOUNT_ID  Cloudflare R2 upload
#   NO_GH_RELEASE=1                  skip GitHub release mirror

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="daylight"
DIST_DIR="$ROOT_DIR/dist"
APP="$DIST_DIR/Daylight.app"
PLIST="$APP/Contents/Info.plist"
BUNDLE_ID="group.tiny.daylight.menubar"

VERSION="${VERSION:-$( [[ -f VERSION ]] && tr -d '[:space:]' < VERSION || echo '2.0.0' )}"
BUILD="${BUILD:-$(date +%Y%m%d%H%M)}"
IDENTITY="${CODESIGN_IDENTITY:-}"
NOTARIZE=0
NOTARY_PROFILE="${NOTARY_PROFILE:-daylight-notary}"
EMBED_SPARKLE=1

SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-}"
PUB_KEY_FILE="$ROOT_DIR/packaging/SparklePublicEDKey.txt"
FEED_URL_FILE="$ROOT_DIR/packaging/SparkleFeedURL.txt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notarize) NOTARIZE=1; shift ;;
    --profile) NOTARY_PROFILE="${2:?}"; shift 2 ;;
    --identity) IDENTITY="${2:?}"; shift 2 ;;
    --no-sparkle) EMBED_SPARKLE=0; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }
need swift; need codesign; need hdiutil; need /usr/libexec/PlistBuddy

# ─── Build the .app (install-local bundle, re-homed for release) ────────
echo "▸ Building Daylight $VERSION (build $BUILD)"
"$ROOT_DIR/scripts/install-local.sh" release >/dev/null
mkdir -p "$DIST_DIR"
rm -rf "$APP"
cp -R "$ROOT_DIR/.build/local/DaylightMenuBar.app" "$APP"

# Ship both Mac architectures using the current SDK. The default Xcode SwiftPM
# backend can stamp an older SDK version, so use the native backend explicitly.
RELEASE_SCRATCH="$ROOT_DIR/.build/direct-release"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
for ARCH in arm64 x86_64; do
  swift build --package-path "$ROOT_DIR" --scratch-path "$RELEASE_SCRATCH/$ARCH" \
    --build-system native --triple "$ARCH-apple-macosx13.0" --sdk "$SDK_PATH" -c release
done
release_bin_dir() {
  swift build --package-path "$ROOT_DIR" --scratch-path "$RELEASE_SCRATCH/$1" \
    --build-system native --triple "$1-apple-macosx13.0" -c release --show-bin-path
}
ARM_BIN_DIR="$(release_bin_dir arm64)"
INTEL_BIN_DIR="$(release_bin_dir x86_64)"
lipo -create "$ARM_BIN_DIR/DaylightMenuBar" "$INTEL_BIN_DIR/DaylightMenuBar" \
  -output "$APP/Contents/MacOS/DaylightMenuBar"
rm -rf "$APP/Contents/Resources/DaylightMenuBar_DaylightMenuBarKit.bundle"
cp -R "$ARM_BIN_DIR/DaylightMenuBar_DaylightMenuBarKit.bundle" "$APP/Contents/Resources/"

# release identity: stable bundle id + human name + version stamp
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Daylight" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$PLIST"

# ─── Resolve signing identity ───────────────────────────────────────────
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -n 1)"
fi
if [[ -z "$IDENTITY" ]]; then
  echo "⚠ No Developer ID found — ad-hoc signing (local build, not distributable/notarizable)."
  IDENTITY="-"
fi

# ─── Resolve Sparkle config ─────────────────────────────────────────────
if [[ "$EMBED_SPARKLE" -eq 1 ]]; then
  [[ -z "$SPARKLE_PUBLIC_ED_KEY" && -f "$PUB_KEY_FILE" ]] && SPARKLE_PUBLIC_ED_KEY="$(tr -d '[:space:]' < "$PUB_KEY_FILE")"
  [[ -z "$SPARKLE_FEED_URL" && -f "$FEED_URL_FILE" ]] && SPARKLE_FEED_URL="$(tr -d '[:space:]' < "$FEED_URL_FILE")"
  if [[ ! -d "$ROOT_DIR/vendor/Sparkle/Sparkle.framework" ]]; then
    echo "▸ Vendoring Sparkle"; "$ROOT_DIR/scripts/vendor-sparkle.sh"
  fi
  if [[ -z "$SPARKLE_PUBLIC_ED_KEY" || -z "$SPARKLE_FEED_URL" ]]; then
    echo "⚠ Sparkle keys/feed not configured (run scripts/setup-sparkle.sh) — skipping auto-update embed."
    EMBED_SPARKLE=0
  fi
fi

# ─── Embed Sparkle.framework ────────────────────────────────────────────
if [[ "$EMBED_SPARKLE" -eq 1 ]]; then
  echo "▸ Embedding Sparkle.framework"
  mkdir -p "$APP/Contents/Frameworks"
  cp -a "$ROOT_DIR/vendor/Sparkle/Sparkle.framework" "$APP/Contents/Frameworks/"
  for k in SUFeedURL SUPublicEDKey SUEnableAutomaticChecks SUEnableInstallerLauncherService; do
    /usr/libexec/PlistBuddy -c "Delete :$k" "$PLIST" 2>/dev/null || true
  done
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string $SPARKLE_FEED_URL" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $SPARKLE_PUBLIC_ED_KEY" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :SUEnableAutomaticChecks bool true" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :SUEnableInstallerLauncherService bool true" "$PLIST"
fi

# ─── Sign (innermost first) ─────────────────────────────────────────────
ENTITLEMENTS="$ROOT_DIR/packaging/Daylight.entitlements"
sign() { codesign --force --options runtime --timestamp --sign "$IDENTITY" "$@"; }
# The main app needs the location entitlement: under the Hardened Runtime the
# 3D moon's Core Location request is denied (and no prompt shows) without it.
signApp() {
  if [[ "$IDENTITY" != "-" && -f "$ENTITLEMENTS" ]]; then
    codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS" --sign "$IDENTITY" "$@"
  else
    sign "$@"
  fi
}
# ad-hoc can't use --timestamp/--options runtime reliably; simplify for "-".
if [[ "$IDENTITY" == "-" ]]; then
  sign() { codesign --force --sign - "$@"; }
  signApp() { codesign --force --sign - "$@"; }
fi

if [[ "$EMBED_SPARKLE" -eq 1 ]]; then
  SPK_VER="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
  for xpc in "$SPK_VER/XPCServices/"*.xpc; do
    [ -d "$xpc" ] && { echo "  sign $(basename "$xpc")"; sign --preserve-metadata=entitlements,flags "$xpc"; }
  done
  [[ -d "$SPK_VER/Updater.app" ]] && sign --preserve-metadata=entitlements,flags "$SPK_VER/Updater.app"
  [[ -f "$SPK_VER/Autoupdate" ]] && sign --preserve-metadata=entitlements,flags "$SPK_VER/Autoupdate"
  echo "  sign Sparkle.framework"; sign "$APP/Contents/Frameworks/Sparkle.framework"
fi
echo "▸ Signing app"
signApp "$APP/Contents/MacOS/DaylightMenuBar"
signApp "$APP"
codesign --verify --deep --strict "$APP" && echo "  ✓ signature valid"

# ─── Notarize the app, and staple it BEFORE the DMG is built ────────────
# Order matters. Building the DMG first and stapling only the outer image
# leaves the copy inside it — the one the user drags to /Applications —
# without a ticket, so its first launch has to reach Apple. Offline, that
# fails. A second submission is the price of a build that opens with no
# network.
DMG="$DIST_DIR/$APP_NAME-$VERSION-macos.dmg"
if [[ "$NOTARIZE" -eq 1 && "$IDENTITY" != "-" ]]; then
  echo "▸ Notarizing app"
  APP_ZIP="$DIST_DIR/$APP_NAME-app.zip"
  rm -f "$APP_ZIP"
  ditto -c -k --keepParent "$APP" "$APP_ZIP"
  xcrun notarytool submit "$APP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  rm -f "$APP_ZIP"
  xcrun stapler staple "$APP" && echo "  ✓ ticket stapled to the app"
elif [[ "$NOTARIZE" -eq 1 ]]; then
  echo "⚠ --notarize requires a Developer ID identity; skipped."
fi

# ─── DMG, built from the stapled app ────────────────────────────────────
echo "▸ Creating $(basename "$DMG")"
rm -f "$DMG"
STAGING="$DIST_DIR/dmg-staging"; rm -rf "$STAGING"; mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Daylight" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"
sign "$DMG"

# ─── Notarize the DMG too, so the image itself is clean on mount ────────
if [[ "$NOTARIZE" -eq 1 && "$IDENTITY" != "-" ]]; then
  echo "▸ Notarizing dmg"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG" && echo "  ✓ stapled app + dmg"
fi

# ─── Appcast (optional) ─────────────────────────────────────────────────
if [[ "$EMBED_SPARKLE" -eq 1 && ( -n "${SPARKLE_EDDSA_KEYCHAIN_ACCOUNT:-}" || -n "${SPARKLE_ED_KEY_FILE:-}" ) ]]; then
  APPCAST_DIR="$DIST_DIR/appcast"; mkdir -p "$APPCAST_DIR"
  # Keep historical archives available while building deltas, but publish only
  # the newest full update. Older binaries may contain retired integrations.
  cp "$DIST_DIR"/daylight-*-macos.dmg "$APPCAST_DIR/"
  # generate_appcast adds to whatever appcast.xml it finds rather than
  # rebuilding it, so re-cutting a version that is already listed leaves two
  # <item>s for it — same version, different hash, and Sparkle picking either.
  # Delete the file and let it be regenerated from the DMGs actually present.
  rm -f "$APPCAST_DIR/appcast.xml"
  # release notes: body of the "## [VERSION]" CHANGELOG section → HTML
  if [[ -f CHANGELOG.md ]]; then
    awk -v ver="$VERSION" '
      index($0,"## ["ver"]")==1 {g=1;next} g&&index($0,"## [")==1{exit}
      g{print}' CHANGELOG.md | awk '
      function flush(){if(i){printf"<li>%s</li>\n",it;i=0;it=""}}
      /^### /{flush();if(u){print"</ul>";u=0};h=$0;sub(/^### /,"",h);printf"<h4>%s</h4>\n",h;next}
      /^- /{flush();if(!u){print"<ul>";u=1};it=$0;sub(/^- /,"",it);i=1;next}
      /^[[:space:]]*$/{next}
      {flush();if(u){print"</ul>";u=0};printf"<p>%s</p>\n",$0}
      END{flush();if(u)print"</ul>"}' > "$APPCAST_DIR/$(basename "$DMG" .dmg).html" || true
  fi
  echo "▸ Generating Sparkle appcast"
  # SPARKLE_ED_KEY_FILE (a private-key file) signs without Keychain prompts —
  # preferred for CI. Otherwise read the key from the Keychain account (the
  # first run prompts for "Always Allow").
  if [[ -n "${SPARKLE_ED_KEY_FILE:-}" && -f "$SPARKLE_ED_KEY_FILE" ]]; then
    cat "$SPARKLE_ED_KEY_FILE" | "$ROOT_DIR/vendor/Sparkle/bin/generate_appcast" --maximum-versions 1 --ed-key-file - "$APPCAST_DIR"
  else
    "$ROOT_DIR/vendor/Sparkle/bin/generate_appcast" --maximum-versions 1 --account "$SPARKLE_EDDSA_KEYCHAIN_ACCOUNT" "$APPCAST_DIR"
  fi
  [[ -f "$APPCAST_DIR/appcast.xml" ]] && echo "  ✓ appcast.xml generated"

  if [[ -n "${R2_BUCKET:-}" && -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    export CLOUDFLARE_ACCOUNT_ID
    echo "▸ Uploading to R2 ($R2_BUCKET)"
    npx --yes wrangler r2 object put --remote "$R2_BUCKET/$(basename "$DMG")" --file "$DMG"
    npx --yes wrangler r2 object put --remote "$R2_BUCKET/$APP_NAME-latest.dmg" --file "$DMG"
    npx --yes wrangler r2 object put --remote "$R2_BUCKET/appcast.xml" --file "$APPCAST_DIR/appcast.xml" --content-type application/xml
    printf '%s' "$VERSION" > "$DIST_DIR/version.txt"
    npx --yes wrangler r2 object put --remote "$R2_BUCKET/version.txt" --file "$DIST_DIR/version.txt" --content-type text/plain
  else
    echo "  (skip R2 upload — R2_BUCKET / CLOUDFLARE_ACCOUNT_ID not set)"
  fi
fi

# ─── GitHub release (optional) ──────────────────────────────────────────
if [[ "${NO_GH_RELEASE:-0}" != "1" ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  TAG="mac-v$VERSION"
  echo "▸ GitHub release $TAG"
  if gh release view "$TAG" >/dev/null 2>&1; then
    gh release upload "$TAG" "$DMG" --clobber 2>&1 | tail -2
  else
    gh release create "$TAG" "$DMG" --title "Daylight for macOS $VERSION" --notes-file <(
      [[ -f CHANGELOG.md ]] && awk -v ver="$VERSION" 'index($0,"## ["ver"]")==1{g=1;next} g&&index($0,"## [")==1{exit} g{print}' CHANGELOG.md
      echo; echo "Auto-update: Sparkle embedded (when keys are configured)."
    ) 2>&1 | tail -2
  fi
fi

echo
echo "✓ Release complete: $DMG"
# Note: keep this as an `if`, not `[[…]] && echo`. With `set -e`, a trailing
# `[[ false ]] && …` makes the script exit 1 even on a fully successful release.
if [[ "$IDENTITY" == "-" ]]; then
  echo "  (ad-hoc signed — for distribution, set CODESIGN_IDENTITY + run with --notarize)"
fi
