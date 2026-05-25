#!/usr/bin/env bash
# MD Editor — interactive one-time setup for the release pipeline.
#
# Adapted from audire/scripts/setup-release.sh. MD Editor's release is
# simpler (no GCP / no remote CI signing yet) — V1 ships notarized direct
# downloads via GitHub Releases + Homebrew cask. The notarytool keychain
# profile is the only thing strictly required for local notarized builds.
#
# Walks through:
#   1. notarytool keychain profile ("notarytool-password") — same name as audire/Membrain
#   2. Sparkle EdDSA signing keys (sparkle's generate_keys, kept in Keychain)
#   3. Optional: GitHub Releases dry-run check
#
# Manual steps NOT covered:
#   - Apple Developer Program enrollment + .p12 export.
#   - First release tag (`git tag v0.1.0 && git push --tags`).
#
# Idempotent: every step detects whether the work is done and skips it.
#
# Requirements: gh, xcrun (Xcode CLT), bash 3.2+, macOS.

set -u

TEAM_ID="LY8G872X5U"  # Same Apple Developer Team ID as audire and Membrain.
KEYCHAIN_PROFILE="notarytool-password"

if tput colors >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
    C_GREEN=$(tput setaf 2)
    C_YELLOW=$(tput setaf 3)
    C_RED=$(tput setaf 1)
    C_BOLD=$(tput bold)
    C_RESET=$(tput sgr0)
else
    C_GREEN=""; C_YELLOW=""; C_RED=""; C_BOLD=""; C_RESET=""
fi

ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
err()  { printf '%sERROR:%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; }
step() { printf '\n%s== %s ==%s\n' "$C_BOLD" "$1" "$C_RESET"; }

confirm() {
    local prompt="$1"
    local reply
    printf '%s%s [y/N]%s ' "$C_YELLOW" "$prompt" "$C_RESET"
    read -r reply
    case "$reply" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# ---- step 0: preflight ----
step "Step 0: preflight"

if ! xcrun notarytool --help >/dev/null 2>&1; then
    err "xcrun notarytool not available. Install Xcode Command Line Tools (xcode-select --install) or full Xcode."
    exit 1
fi
ok "xcrun notarytool available"

if [ ! -f "VISION.md" ] || [ ! -f "project.yml" ]; then
    err "Not at the md-editor repo root."
    exit 1
fi
ok "md-editor repo detected (cwd: $(pwd))"

# Developer ID Application identity check
DEV_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
if [ -z "$DEV_ID" ]; then
    warn "No 'Developer ID Application' identity found in Keychain."
    echo "  Export your .p12 from Keychain Access on the machine that originally"
    echo "  enrolled in the Apple Developer Program (Team ID $TEAM_ID), then"
    echo "  double-click to install. The same identity is used by audire and Membrain."
else
    ok "Signing identity: $DEV_ID"
fi

# ---- step 1: notarytool keychain profile ----
step "Step 1: notarytool keychain profile ($KEYCHAIN_PROFILE)"

NOTARY_CHECK=$(xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" 2>&1 | head -1 || true)
case "$NOTARY_CHECK" in
    *"Successfully received"*|*"No submissions found"*)
        ok "keychain profile '$KEYCHAIN_PROFILE' already configured"
        ;;
    *)
        warn "keychain profile '$KEYCHAIN_PROFILE' not found — will create"
        printf 'Apple ID email: '
        read -r APPLE_ID
        if [ -z "$APPLE_ID" ]; then
            err "Apple ID required"
            exit 1
        fi
        printf 'App-specific password (https://appleid.apple.com → Sign-In and Security → App-Specific Passwords): '
        stty -echo
        read -r APP_PASSWORD
        stty echo
        printf '\n'
        if [ -z "$APP_PASSWORD" ]; then
            err "App-specific password required"
            exit 1
        fi
        xcrun notarytool store-credentials "$KEYCHAIN_PROFILE" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APP_PASSWORD"
        unset APP_PASSWORD
        ok "keychain profile '$KEYCHAIN_PROFILE' stored"
        ;;
esac

# ---- step 2: Sparkle EdDSA keys ----
step "Step 2: Sparkle EdDSA signing keys"

# Sparkle 2 stores its EdDSA private key in the user's Keychain. The public
# key is what ships in the app bundle (via Info.plist SUPublicEDKey) so the
# Sparkle framework can verify each downloaded update.
#
# generate_keys lives in the SPM artifacts after `make build` resolves Sparkle.
# This step bootstraps the build if needed, then runs generate_keys for real
# (not a "you should do this" message).

if security find-generic-password -a "ed25519" -s "https://sparkle-project.org" >/dev/null 2>&1; then
    ok "Sparkle EdDSA private key already in Keychain"
else
    warn "Sparkle EdDSA key not in Keychain — minting now"

    # Ensure the Sparkle SPM artifacts are present (build resolves them).
    SPARKLE_BIN=""
    for candidate in \
        "build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys" \
        $(find ~/Library/Developer/Xcode/DerivedData -path "*Sparkle*/bin/generate_keys" -type f 2>/dev/null); do
        if [ -x "$candidate" ]; then
            SPARKLE_BIN="$candidate"
            break
        fi
    done

    if [ -z "$SPARKLE_BIN" ]; then
        warn "Sparkle artifacts not present — bootstrapping with 'make build'..."
        make build >/dev/null 2>&1 || true
        SPARKLE_BIN="build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys"
    fi

    if [ ! -x "$SPARKLE_BIN" ]; then
        err "Couldn't locate generate_keys even after 'make build'. Run 'make build' manually then re-run this script."
        exit 1
    fi

    OUTPUT=$("$SPARKLE_BIN" 2>&1)
    echo "$OUTPUT"
    PUB_KEY=$(echo "$OUTPUT" | grep -oE '[A-Za-z0-9+/]{43}=' | head -1)
    if [ -n "$PUB_KEY" ]; then
        ok "EdDSA keypair minted; public key: $PUB_KEY"
        echo ""
        printf '%sPaste this into project.yml under info.properties:%s\n' "$C_BOLD" "$C_RESET"
        printf '  SUPublicEDKey: "%s"\n' "$PUB_KEY"
    else
        warn "Couldn't parse public key from generate_keys output — copy it manually from the message above."
    fi
fi

# ---- step 3: verification print ----
step "Step 3: Verification"

verify_check() {
    local label="$1"
    local cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        ok "$label"
    else
        printf '%sMISSING%s %s\n' "$C_RED" "$C_RESET" "$label"
    fi
}

verify_check "Developer ID Application identity in Keychain" \
    "security find-identity -v -p codesigning | grep -q 'Developer ID Application'"
verify_check "notarytool-password keychain profile" \
    "xcrun notarytool history --keychain-profile $KEYCHAIN_PROFILE 2>&1 | head -1 | grep -E -q 'Successfully received|No submissions found'"

printf '\n%sNext:%s\n' "$C_BOLD" "$C_RESET"
printf '  make release         (build, sign, notarize, staple)\n'
printf '  git tag v0.1.0 && git push --tags     (cut first release)\n'
