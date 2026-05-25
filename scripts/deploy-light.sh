#!/bin/bash
# MD Editor lightweight deploy — fast local sign + install to /Applications.
# Adapted from audire/scripts/deploy-light.sh.
#
# Builds MDEditor.app (Debug config, ad-hoc "Sign to Run Locally" identity —
# no Developer ID required), quits any running MDEditor, replaces
# /Applications/MDEditor.app, drops the CLI helper symlink into
# /usr/local/bin/mdedit, and opens the app.
#
# GOTCHA: must be run from an interactive Terminal session on the Mac you're
# sitting in front of — NOT over SSH. SSH-launched GUI apps end up in a
# different Mach bootstrap namespace and won't show their window correctly.
#
# For notarized distribution builds use scripts/notarize.sh instead.
set -euo pipefail

echo "=== MD Editor Lightweight Deploy ==="

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# 1. Quit MDEditor if running.
pkill -x MDEditor 2>/dev/null && sleep 1 || true

# 2. Build via the canonical Makefile target (handles editor-bundle + CLI helper copy).
echo "Building..."
make build 2>&1 | tail -3

BUILD_APP="build/Build/Products/Debug/MDEditor.app"
if [ ! -d "$BUILD_APP" ]; then
    echo "ERROR: Build output missing at $BUILD_APP"
    exit 1
fi

# 3. Replace installed copy.
echo "Installing to /Applications/MDEditor.app..."
rm -rf /Applications/MDEditor.app
cp -R "$BUILD_APP" /Applications/MDEditor.app

# 4. Re-codesign ad-hoc to be safe.
codesign --force --deep --sign - /Applications/MDEditor.app 2>/dev/null || true

# 5. CLI helper symlink (sudo only if /usr/local/bin isn't writable).
if [ -w /usr/local/bin ]; then
    ln -sf /Applications/MDEditor.app/Contents/Helpers/mdedit /usr/local/bin/mdedit
elif [ -d /usr/local/bin ]; then
    sudo ln -sf /Applications/MDEditor.app/Contents/Helpers/mdedit /usr/local/bin/mdedit
fi

# 6. Launch.
echo "Launching..."
open /Applications/MDEditor.app

echo "=== Done ==="
echo "If the window does not appear, you may be running over SSH."
echo "Re-run from an interactive Terminal window on the Mac itself."
