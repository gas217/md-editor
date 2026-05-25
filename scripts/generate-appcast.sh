#!/usr/bin/env bash
# generate-appcast.sh — emit appcast.xml for the Sparkle 2 in-app updater.
# Called by `make release` after notarization succeeds.
#
# Locates Sparkle's sign_update tool inside the SPM-resolved artifacts
# (build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update — minted on
# first xcodebuild that resolves the Sparkle package) and EdDSA-signs the DMG.
# Falls back to a clearly-labeled placeholder ONLY when sign_update is missing
# AND $MDEDIT_RELEASE_SOFT=1 is set (CI dry-runs); a normal `make release`
# refuses to ship without a real signature.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DMG="build/Release/MDEditor.dmg"
APPCAST="build/Release/appcast.xml"
VERSION=$(awk '/CFBundleShortVersionString/ {getline; gsub(/[^0-9.]/, "", $0); print}' project.yml | head -1)
PUBDATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")
URL="https://github.com/gas217/md-editor/releases/download/v${VERSION}/MDEditor-v${VERSION}.dmg"

if [[ ! -f "$DMG" ]]; then
    echo "FAIL: $DMG not found. Run 'make release' first." >&2
    exit 1
fi
SIZE=$(stat -f%z "$DMG")

# Locate sign_update — try SPM artifacts first, then PATH, then Sparkle's
# DerivedData cache (in case the user built Sparkle separately).
SIGN_UPDATE=""
for candidate in \
    "build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" \
    "$(command -v sign_update 2>/dev/null || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        SIGN_UPDATE="$candidate"
        break
    fi
done

if [[ -z "$SIGN_UPDATE" ]]; then
    SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -path "*Sparkle*/bin/sign_update" -type f 2>/dev/null | head -1)
fi

if [[ -z "$SIGN_UPDATE" ]]; then
    if [[ -n "${MDEDIT_RELEASE_SOFT:-}" ]]; then
        echo "WARN: sign_update not found; emitting UNSIGNED appcast (MDEDIT_RELEASE_SOFT=1)." >&2
        SIG="UNSIGNED-MDEDIT_RELEASE_SOFT-set"
    else
        cat >&2 <<EOF
ERROR: Sparkle's sign_update tool not found.

Tried:
  build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update
  \$PATH
  ~/Library/Developer/Xcode/DerivedData/*Sparkle*/bin/sign_update

Run \`make build\` once so the Sparkle SPM dep resolves and copies its bin/
artifacts into build/SourcePackages/. Then retry. To allow an UNSIGNED appcast
for a CI dry-run, set MDEDIT_RELEASE_SOFT=1 explicitly.
EOF
        exit 1
    fi
else
    echo "  Using sign_update: $SIGN_UPDATE"

    # Two paths to the private key:
    #   1. MDEDIT_ED_KEY_FILE — path to an exported key file. Non-interactive;
    #      what CI uses. The file lives outside the repo (e.g. ~/.sparkle/ed25519).
    #   2. macOS Keychain — Sparkle's default. The FIRST run of sign_update will
    #      pop a Keychain access modal that the developer must click "Always Allow"
    #      on. Subsequent runs are non-interactive. CI can't do this; CI must
    #      take path 1.
    SIGN_ARGS=("$DMG")
    if [[ -n "${MDEDIT_ED_KEY_FILE:-}" ]]; then
        if [[ ! -f "$MDEDIT_ED_KEY_FILE" ]]; then
            echo "ERROR: MDEDIT_ED_KEY_FILE='$MDEDIT_ED_KEY_FILE' not found." >&2
            exit 1
        fi
        SIGN_ARGS=("--ed-key-file" "$MDEDIT_ED_KEY_FILE" "$DMG")
        echo "  Using key file: $MDEDIT_ED_KEY_FILE"
    else
        echo "  Using Keychain (Sparkle private key under 'ed25519' / 'https://sparkle-project.org')"
        echo "  First call may show a Keychain access modal — click 'Always Allow' once."
    fi

    # sign_update prints "sparkle:edSignature=\"...\" length=\"...\""
    SIG_OUTPUT=$("$SIGN_UPDATE" "${SIGN_ARGS[@]}")
    SIG=$(echo "$SIG_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
    if [[ -z "$SIG" ]]; then
        echo "ERROR: sign_update output didn't include edSignature: $SIG_OUTPUT" >&2
        exit 1
    fi
fi

cat > "$APPCAST" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
     xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
     xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>MD Editor Updates</title>
    <link>https://github.com/gas217/md-editor</link>
    <description>Most recent updates to MD Editor</description>
    <language>en</language>
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUBDATE}</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="${URL}"
        sparkle:edSignature="${SIG}"
        length="${SIZE}"
        type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF

echo "Generated $APPCAST for v${VERSION}."
echo "  signature: ${SIG:0:32}..."
echo "  enclosure size: ${SIZE} bytes"
