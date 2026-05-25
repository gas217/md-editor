#!/bin/bash
# MD Editor notarization — adapted from audire/scripts/notarize.sh and
# Membrain/Membrain-mac/scripts/notarize.sh. Same signing identity, same
# `notarytool-password` keychain profile, same Team ID (LY8G872X5U).
#
# Usage: ./scripts/notarize.sh <path-to-app> <apple-id> <team-id>
#
# Requires:
#   - Developer ID Application certificate installed in Keychain
#     (must match com.mdedit.app bundle id, Team ID LY8G872X5U)
#   - App-specific password stored in Keychain as "notarytool-password"
#     One-time setup:
#       xcrun notarytool store-credentials "notarytool-password" \
#         --apple-id <apple-id> \
#         --team-id LY8G872X5U \
#         --password <app-specific-password>
#     Generate the app-specific password at https://appleid.apple.com → Sign-In and Security.
#
# Hardened runtime is enabled on Release builds via project.yml
# (ENABLE_HARDENED_RUNTIME=YES in base settings). The entitlements file
# (App/MDEditor.entitlements) has App Sandbox ON — MD Editor is a
# document app, not a system-audio capture app, so it can ship sandboxed.
set -euo pipefail

APP_PATH="${1:?Usage: notarize.sh <app-path> <apple-id> <team-id>}"
APPLE_ID="${2:?Usage: notarize.sh <app-path> <apple-id> <team-id>}"
TEAM_ID="${3:?Usage: notarize.sh <app-path> <apple-id> <team-id>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENTITLEMENTS="$REPO_ROOT/App/MDEditor.entitlements"

SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
if [ -z "$SIGNING_IDENTITY" ]; then
    echo "ERROR: No Developer ID Application certificate found in Keychain"
    exit 1
fi
echo "  Using identity: $SIGNING_IDENTITY"
ZIP_PATH="/tmp/MDEditor-notarize.zip"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
fi

if [ ! -f "$ENTITLEMENTS" ]; then
    echo "ERROR: Entitlements file not found at $ENTITLEMENTS"
    exit 1
fi

# Hard-gate: refuse to ship a release with empty entitlements. Tests/Entitlements.swift
# soft-skips on empty for dev velocity; this catches the regression at release time.
if ! /usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" "$ENTITLEMENTS" 2>/dev/null | grep -q "^true$"; then
    echo "ERROR: $ENTITLEMENTS is empty or missing 'com.apple.security.app-sandbox'."
    echo "       Restore the documented keys per PRODUCTION-READINESS.md before release:"
    echo "         com.apple.security.app-sandbox"
    echo "         com.apple.security.files.user-selected.read-write"
    echo "         com.apple.security.files.bookmarks.app-scope"
    echo "         com.apple.security.files.bookmarks.document-scope"
    exit 1
fi

echo "==> Step 0: Clean bundle for distribution..."
# Remove debug dylibs, preview dylibs, and test bundles (same as audire/Membrain).
find "$APP_PATH" -name "__preview.dylib" -delete 2>/dev/null || true
find "$APP_PATH" -name "*.debug.dylib" -delete 2>/dev/null || true
find "$APP_PATH" -name "*.xctest" -type d -exec rm -rf {} + 2>/dev/null || true
echo "  Cleaned debug/preview/test artifacts"

echo "==> Step 1: Codesign MDEditor.app (com.mdedit.app) with hardened runtime..."

# Sign the bundled CLI helper FIRST (nested code must be signed before outer).
# Helpers/mdedit is the standalone non-sandboxed Mach-O that the cask symlink
# points to — see VISION.md "Finder integration → mdedit CLI".
if [ -f "${APP_PATH}/Contents/Helpers/mdedit" ]; then
    echo "  Signing Helpers/mdedit..."
    codesign --force --options runtime \
        --sign "$SIGNING_IDENTITY" \
        --timestamp \
        "${APP_PATH}/Contents/Helpers/mdedit"
fi

# Sign any embedded frameworks/dylibs (preview-md-shared etc.).
if [ -d "${APP_PATH}/Contents/Frameworks" ]; then
    echo "  Signing frameworks..."
    find "${APP_PATH}/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" | while read -r fw; do
        codesign --force --options runtime \
            --sign "$SIGNING_IDENTITY" \
            --timestamp \
            "$fw"
    done
fi

# Sign the main app bundle with MD Editor's entitlements.
echo "  Signing MDEditor.app..."
codesign --force --options runtime \
    --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --timestamp \
    "$APP_PATH"

echo "  Verifying signature..."
codesign --verify --deep --strict "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH" 2>&1 || true

echo "==> Step 2: Create zip for notarization..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "  Created: $ZIP_PATH ($(du -h "$ZIP_PATH" | cut -f1))"

echo "==> Step 3: Submit for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --keychain-profile "notarytool-password" \
    --wait

echo "==> Step 4: Staple notarization ticket..."
xcrun stapler staple "$APP_PATH"

echo "==> Step 5: Final verification..."
spctl --assess --type execute --verbose "$APP_PATH" 2>&1
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "==> Done. $APP_PATH (com.mdedit.app) is signed, notarized, and stapled."
rm -f "$ZIP_PATH"
