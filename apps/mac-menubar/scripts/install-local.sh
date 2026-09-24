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

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
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
  <string>「昼间」仅在你打开 3D 月相模型时使用你的位置，用于计算当地观测的月亮高度角、方位角与相位朝向。简单月相无需定位。</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>「昼间」仅在你打开 3D 月相模型时使用你的位置，用于计算当地观测的月亮高度角、方位角与相位朝向。简单月相无需定位。</string>
  <key>NSCalendarsUsageDescription</key>
  <string>「昼间」读取你的系统日历，用于在日历网格上标出有日程的日子并列出当天的安排。数据仅在本机使用，不会上传。</string>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>「昼间」只读取你的系统日历，用于在日历网格上标出有日程的日子并列出当天的安排。数据仅在本机使用，不会上传。</string>
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
