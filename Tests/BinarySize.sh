#!/usr/bin/env bash
# Tests/BinarySize.sh — V1.0 Resource budget check.
# See VISION.md "Resource budgets" → "Binary size".
# Target: <10 MB. Hard ceiling: 15 MB.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$REPO_ROOT/build/Build/Products/Release/MDEditor.app"

if [[ ! -d "$APP" ]]; then
    echo "FAIL: $APP not found. Run 'make release' first." >&2
    exit 1
fi

SIZE_KB=$(du -sk "$APP" | awk '{print $1}')
SIZE_MB=$(( SIZE_KB / 1024 ))

echo "MDEditor.app size: ${SIZE_MB} MB"

if (( SIZE_KB > 15 * 1024 )); then
    echo "FAIL: binary exceeds 15 MB hard ceiling" >&2
    exit 1
fi

if (( SIZE_KB > 10 * 1024 )); then
    echo "WARN: binary exceeds 10 MB target (under 15 MB ceiling — soft fail)"
fi

echo "PASS"
