# macOS Auto-Update (Sparkle)

The menu bar app ships with the same Sparkle integration as the sibling
project CMView: `Sparkle.framework` is loaded dynamically from the app bundle
at startup, so development builds (`swift run`, `scripts/install-local.sh`)
carry no Sparkle dependency and every updater call no-ops. "检查更新" in the
settings About section falls back to the GitHub releases page in such builds.

## Pieces

- `Sources/DaylightMenuBar/Updater.swift` — runtime bridge. `start()` is
  called from `applicationDidFinishLaunching` (arms scheduled checks in
  release bundles); `checkForUpdates()` backs the settings row.
- `scripts/vendor-sparkle.sh` — fetches Sparkle (framework + tools) into
  `vendor/Sparkle/` (gitignored).
- `scripts/setup-sparkle.sh` — one-time: generates the EdDSA keypair (private
  key stays in the macOS Keychain under "daylight Sparkle EdDSA Key") and
  writes `packaging/SparklePublicEDKey.txt` + `packaging/SparkleFeedURL.txt`
  (both public, committed).
- `scripts/release-macos.sh` — builds `dist/Daylight.app` (stable bundle id
  `group.tiny.daylight.menubar`, version from `VERSION`), embeds and signs
  Sparkle, creates the DMG, and optionally notarizes, generates the signed
  appcast, uploads to R2, and mirrors to a GitHub release (`mac-v<VERSION>`).
  Every distribution step degrades gracefully when its prerequisite (identity,
  keys, wrangler, gh) is missing.

## Release flow

```bash
cd apps/mac-menubar
scripts/setup-sparkle.sh                     # once; commit the two packaging/ files
SPARKLE_EDDSA_KEYCHAIN_ACCOUNT="daylight Sparkle EdDSA Key" \
  scripts/release-macos.sh --notarize        # per release
```

Host `dist/appcast/appcast.xml` and the DMG at the feed URL (R2 upload is
built in via `R2_BUCKET` + `CLOUDFLARE_ACCOUNT_ID`). Bump `VERSION` per
release; `CFBundleVersion` is stamped from the timestamp automatically.
