#!/usr/bin/env bash
#
# Download Sparkle into vendor/Sparkle/ so the release script can embed
# Sparkle.framework into the app bundle and call generate_appcast /
# sign_update. Sparkle is not committed — it's vendored on demand here.
# Mirrors the sibling project (CMView).
#
# Idempotent: re-runs are no-ops once the expected version is unpacked.
#
# Usage: scripts/vendor-sparkle.sh [VERSION]   (default: 2.6.4)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-2.6.4}"
VENDOR_DIR="vendor/Sparkle"
TARBALL_URL="https://github.com/sparkle-project/Sparkle/releases/download/${VERSION}/Sparkle-${VERSION}.tar.xz"
STAMP="$VENDOR_DIR/.version"

if [[ -d "$VENDOR_DIR/Sparkle.framework" && -f "$STAMP" && "$(cat "$STAMP")" == "$VERSION" ]]; then
    echo "Sparkle ${VERSION} already vendored at $VENDOR_DIR"
    exit 0
fi

echo "Fetching Sparkle ${VERSION}"
rm -rf "$VENDOR_DIR"; mkdir -p "$VENDOR_DIR"
TMPDIR="$(mktemp -d)"; trap 'rm -rf "$TMPDIR"' EXIT
curl -fL "$TARBALL_URL" -o "$TMPDIR/Sparkle.tar.xz"
tar -xJf "$TMPDIR/Sparkle.tar.xz" -C "$VENDOR_DIR"

[[ -d "$VENDOR_DIR/Sparkle.framework" ]] || { echo "Sparkle.framework missing after extraction" >&2; exit 1; }
echo "$VERSION" > "$STAMP"
echo "Sparkle ${VERSION} vendored: framework + bin/{generate_appcast,generate_keys,sign_update}"
