#!/usr/bin/env bash
#
# One-time setup for Sparkle auto-update keys (mirrors CMView).
#
# 1. Vendors Sparkle (downloads tools if missing).
# 2. Generates an EdDSA keypair (private key → macOS Keychain, public key
#    printed). Keychain account name: "daylight Sparkle EdDSA Key".
# 3. Saves the public key to packaging/SparklePublicEDKey.txt and asks for
#    the appcast feed URL, writing it to packaging/SparkleFeedURL.txt.
#
# After this runs, scripts/release-macos.sh auto-picks both files. They are
# public — only the private key is sensitive and it stays in the Keychain.
set -euo pipefail
cd "$(dirname "$0")/.."

VENDOR_BIN="vendor/Sparkle/bin"
PUB_KEY_FILE="packaging/SparklePublicEDKey.txt"
FEED_URL_FILE="packaging/SparkleFeedURL.txt"
KEYCHAIN_ACCOUNT="daylight Sparkle EdDSA Key"

mkdir -p packaging
[[ -x "$VENDOR_BIN/generate_keys" ]] || scripts/vendor-sparkle.sh

if [[ -f "$PUB_KEY_FILE" ]]; then
  echo "$PUB_KEY_FILE already exists. To regenerate, delete it first."
  exit 0
fi

echo "Generating Sparkle EdDSA keypair (account: $KEYCHAIN_ACCOUNT)"
"$VENDOR_BIN/generate_keys" --account "$KEYCHAIN_ACCOUNT" || true

PUB_KEY="$("$VENDOR_BIN/generate_keys" -p --account "$KEYCHAIN_ACCOUNT" | tail -n 1 | tr -d '[:space:]')"
[[ -n "$PUB_KEY" ]] || { echo "failed to read public key" >&2; exit 1; }

printf '%s\n' "$PUB_KEY" > "$PUB_KEY_FILE"
echo "Wrote public key to $PUB_KEY_FILE"

if [[ ! -f "$FEED_URL_FILE" ]]; then
  read -rp "Appcast feed URL [https://daylight.mings.work/appcast.xml]: " feed_url
  feed_url="${feed_url:-https://daylight.mings.work/appcast.xml}"
  printf '%s\n' "$feed_url" > "$FEED_URL_FILE"
  echo "Wrote feed URL to $FEED_URL_FILE"
fi

cat <<EOF

Done. Next:
  1. Commit $PUB_KEY_FILE and $FEED_URL_FILE (public).
  2. Host appcast.xml + the DMG at the feed URL (R2/Pages/GitHub releases).
  3. Run scripts/release-macos.sh with
     SPARKLE_EDDSA_KEYCHAIN_ACCOUNT="$KEYCHAIN_ACCOUNT" to sign + appcast + upload.
EOF
