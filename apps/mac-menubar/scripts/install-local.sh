#!/usr/bin/env bash
# Builds a local DaylightMenuBar.app bundle for development runs.
# Exports: .build/local/DaylightMenuBar.app
# Deps: SwiftPM, macOS app bundle layout, optional codesign

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
APP_DIR="$ROOT_DIR/.build/local/DaylightMenuBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_DIR/DaylightMenuBar" "$MACOS_DIR/DaylightMenuBar"
cp -R "$BIN_DIR/DaylightMenuBar_DaylightMenuBarKit.bundle" "$RESOURCES_DIR/"
cp "$ROOT_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
# Localized permission prompts: macOS picks the .lproj matching the system language.
cp -R "$ROOT_DIR/packaging/Localizations/"*.lproj "$RESOURCES_DIR/"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleExecutable</key>
  <string>DaylightMenuBar</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>group.tiny.daylight.menubar.local</string>
  <key>CFBundleName</key>
  <string>Daylight Menu Bar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>2.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSLocationUsageDescription</key>
  <string>Daylight uses your location only when you open the 3D moon model, to compute the moon's altitude, azimuth and phase orientation as seen from where you are. The simple moon phase does not need your location.</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Daylight uses your location only when you open the 3D moon model, to compute the moon's altitude, azimuth and phase orientation as seen from where you are. The simple moon phase does not need your location.</string>
  <key>NSCalendarsUsageDescription</key>
  <string>Daylight reads your system calendars to mark days that have events on the calendar grid and list that day's schedule. The data is used only on this Mac and is never uploaded.</string>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>Daylight only reads your system calendars to mark days that have events on the calendar grid and list that day's schedule. The data is used only on this Mac and is never uploaded.</string>
</dict>
</plist>
PLIST

# A stable signing identity matters because macOS privacy permissions are tied
# to the app's designated requirement. Ad-hoc signing has no Team ID, so each
# rebuilt binary gets a new cdhash and TCC treats it as a new app.
IDENTITY="${CODESIGN_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -n 1)"
fi

if command -v codesign >/dev/null 2>&1; then
  if [[ -n "$IDENTITY" && "$IDENTITY" != "-" ]]; then
    echo "▸ Signing local bundle with identity: $IDENTITY"
    codesign --force --entitlements "$ROOT_DIR/packaging/Daylight.entitlements" \
      --sign "$IDENTITY" "$APP_DIR" >/dev/null 2>&1
  else
    echo "▸ Signing local bundle ad-hoc (-); privacy permissions will reset on every rebuild."
    codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
  fi
fi

printf '%s\n' "$APP_DIR"
