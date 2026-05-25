#!/usr/bin/env bash
# build-dmg.sh — wrap MDEditor.app in a signed DMG for direct download distribution.
# Called by `make release`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

: "${MDEDIT_SIGN_ID:?MDEDIT_SIGN_ID env var must be set to 'Developer ID Application: ...'}"

APP="build/Build/Products/Release/MDEditor.app"
OUTPUT_DIR="build/Release"
DMG="$OUTPUT_DIR/MDEditor.dmg"
STAGING="$(mktemp -d)/MDEditor-dmg"

if [[ ! -d "$APP" ]]; then
    echo "FAIL: $APP not found. Build Release first." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create the DMG
hdiutil create -volname "MD Editor" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG"

# Sign the DMG
codesign --force --sign "$MDEDIT_SIGN_ID" "$DMG"

# Compute SHA-256 for the SHASUMS file
shasum -a 256 "$DMG" | tee -a "$OUTPUT_DIR/SHASUMS256.txt"

echo "DMG built: $DMG"
