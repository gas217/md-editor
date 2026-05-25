#!/usr/bin/env bash
# install.sh — install MD Editor from a release tarball, handle Gatekeeper quarantine.
# Usage: curl -sSL https://github.com/gas217/md-editor/releases/latest/download/install.sh | sh

set -euo pipefail

REPO="${MDEDIT_REPO:-gas217/md-editor}"
INSTALL_DIR="${MDEDIT_INSTALL_DIR:-/Applications}"
CLI_DIR="${MDEDIT_CLI_DIR:-/usr/local/bin}"

say() { printf "\033[36m==>\033[0m %s\n" "$*"; }
err() { printf "\033[31merror:\033[0m %s\n" "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || err "MD Editor is macOS only."
[ -d "$INSTALL_DIR" ] || err "$INSTALL_DIR does not exist."

say "Resolving latest release..."
api="https://api.github.com/repos/$REPO/releases/latest"
asset_url=$(curl -fsSL "$api" | grep -oE 'https://[^"]*MDEditor[^"]*\.dmg' | head -1)
[ -n "$asset_url" ] || err "no DMG found in latest release"

tmp=$(mktemp -d)
dmg="$tmp/MDEditor.dmg"
say "Downloading $asset_url..."
curl -fsSL -o "$dmg" "$asset_url"

say "Mounting..."
volume=$(hdiutil attach -nobrowse -quiet "$dmg" | awk '/\/Volumes\// {print $NF}' | tail -1)
trap "hdiutil detach -quiet '$volume' 2>/dev/null || true; rm -rf '$tmp'" EXIT

say "Copying MDEditor.app to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/MDEditor.app"
cp -R "$volume/MDEditor.app" "$INSTALL_DIR/"

# Notarized stapled builds don't need this; the call is a no-op then.
say "Removing Gatekeeper quarantine flag (if present)..."
xattr -dr com.apple.quarantine "$INSTALL_DIR/MDEditor.app" 2>/dev/null || true

say "Installing mdedit CLI symlink at $CLI_DIR/mdedit..."
mkdir -p "$CLI_DIR" 2>/dev/null || sudo mkdir -p "$CLI_DIR"
if [ -w "$CLI_DIR" ]; then
    ln -sf "$INSTALL_DIR/MDEditor.app/Contents/Helpers/mdedit" "$CLI_DIR/mdedit"
else
    sudo ln -sf "$INSTALL_DIR/MDEditor.app/Contents/Helpers/mdedit" "$CLI_DIR/mdedit"
fi

say "Registering with LaunchServices..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "$INSTALL_DIR/MDEditor.app"

say "Done. Open MD Editor from Finder, or run \`mdedit foo.md\`."
