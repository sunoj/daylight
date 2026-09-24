#!/usr/bin/env bash
# Build a universal, sandboxed Mac App Store package without altering the local app.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEAM_ID="${TEAM_ID:-JHH9GC8Y8C}"
BUNDLE_ID="${BUNDLE_ID:-com.mings.daylight}"
VERSION="${VERSION:-$(cat "$ROOT_DIR/VERSION")}"
BUILD="${BUILD:-1}"
APP_IDENTITY="${APP_IDENTITY:-Apple Distribution: Ming Sun (JHH9GC8Y8C)}"
INSTALLER_IDENTITY="${INSTALLER_IDENTITY:-3rd Party Mac Developer Installer: Ming Sun (JHH9GC8Y8C)}"
PROFILE_PATH="${PROFILE_PATH:-$HOME/.appstoreconnect/daylight-signing/Daylight.provisionprofile}"
OUTPUT_DIR="$ROOT_DIR/dist/app-store"
SCRATCH_DIR="$ROOT_DIR/.build/app-store"
APP="$OUTPUT_DIR/Daylight.app"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

test -f "$PROFILE_PATH"
mkdir -p "$OUTPUT_DIR"
security cms -D -i "$PROFILE_PATH" > "$OUTPUT_DIR/profile.plist"
python3 - "$OUTPUT_DIR/profile.plist" "$TEAM_ID" "$BUNDLE_ID" <<'PY'
import datetime, plistlib, sys
profile = plistlib.load(open(sys.argv[1], 'rb'))
assert sys.argv[2] in profile['TeamIdentifier'], 'Provisioning team mismatch'
assert profile['Entitlements']['com.apple.application-identifier'] == sys.argv[2] + '.' + sys.argv[3], 'Bundle ID mismatch'
assert profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Profile expired'
PY

for ARCH in arm64 x86_64; do
    swift build --package-path "$ROOT_DIR" --scratch-path "$SCRATCH_DIR/$ARCH" \
        --build-system native --triple "$ARCH-apple-macosx13.0" --sdk "$SDK_PATH" \
        -c release -Xswiftc -DAPP_STORE
done
bin_dir() {
    swift build --package-path "$ROOT_DIR" --scratch-path "$SCRATCH_DIR/$1" \
        --build-system native --triple "$1-apple-macosx13.0" -c release --show-bin-path
}
BIN_DIR="$(bin_dir arm64)"
INTEL_BIN_DIR="$(bin_dir x86_64)"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$BIN_DIR/DaylightMenuBar" "$INTEL_BIN_DIR/DaylightMenuBar" -output "$APP/Contents/MacOS/DaylightMenuBar"
cp -R "$BIN_DIR/DaylightMenuBar_DaylightMenuBarKit.bundle" "$APP/Contents/Resources/"
cp "$ROOT_DIR/AppIcon.icns" "$APP/Contents/Resources/"
cp "$ROOT_DIR/packaging/PrivacyInfo.xcprivacy" "$APP/Contents/Resources/"
cp "$PROFILE_PATH" "$APP/Contents/embedded.provisionprofile"

python3 - "$ROOT_DIR" "$APP" "$TEAM_ID" "$BUNDLE_ID" "$VERSION" "$BUILD" "$OUTPUT_DIR" <<'PY'
from pathlib import Path
import plistlib, re, subprocess, sys
root, app, team, bundle, version, build, output = sys.argv[1:]
# Share permission descriptions with the local build without rebuilding or modifying it.
script = (Path(root) / 'scripts/install-local.sh').read_text()
info = plistlib.loads(re.search(r"<<'PLIST'\n(.*?)\nPLIST", script, re.S)[1].encode())
sdk = Path(subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'], text=True).strip())
sdk_info = plistlib.load(open(sdk / 'SDKSettings.plist', 'rb'))
xcode = subprocess.check_output(['xcodebuild', '-version'], text=True).splitlines()
info.update(CFBundleIdentifier=bundle, CFBundleName='Daylight', CFBundleDisplayName='Daylight',
            CFBundleShortVersionString=version, CFBundleVersion=build,
            LSApplicationCategoryType='public.app-category.productivity',
            CFBundleSupportedPlatforms=['MacOSX'], NSHighResolutionCapable=True,
            ITSAppUsesNonExemptEncryption=False, DaylightDistribution='AppStore',
            NSHumanReadableCopyright='Copyright © 2026 Ming Sun',
            DTPlatformName='macosx', DTSDKName='macosx' + sdk_info['Version'],
            DTSDKBuild=subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-build-version'], text=True).strip(),
            DTXcodeBuild=xcode[1].split()[-1])
plistlib.dump(info, open(Path(app) / 'Contents/Info.plist', 'wb'))
entitlements = plistlib.load(open(Path(root) / 'packaging/Daylight-AppStore.entitlements', 'rb'))
entitlements.update({'com.apple.application-identifier': team + '.' + bundle,
                     'com.apple.developer.team-identifier': team})
plistlib.dump(entitlements, open(Path(output) / 'signed.entitlements', 'wb'))
PY

codesign --force --timestamp --options runtime --entitlements "$OUTPUT_DIR/signed.entitlements" --sign "$APP_IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"
python3 - "$APP/Contents/MacOS/DaylightMenuBar" <<'PY'
import subprocess, sys
architectures = subprocess.check_output(['lipo', '-archs', sys.argv[1]], text=True).split()
assert set(architectures) == {'arm64', 'x86_64'}, architectures
PY
productbuild --sign "$INSTALLER_IDENTITY" --component "$APP" /Applications "$OUTPUT_DIR/Daylight-$VERSION-$BUILD.pkg"
pkgutil --check-signature "$OUTPUT_DIR/Daylight-$VERSION-$BUILD.pkg"
printf '%s\n' "$OUTPUT_DIR/Daylight-$VERSION-$BUILD.pkg"
