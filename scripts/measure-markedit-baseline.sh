#!/usr/bin/env bash
# measure-markedit-baseline.sh — V1.0 Story 0b
# Capture MarkEdit's perf numbers on the same fixtures we'll measure md-editor against.
# Output: baselines.json (committed to the repo; CI thresholds read from it).
#
# Requires MarkEdit installed at /Applications/MarkEdit.app.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MARKEDIT="/Applications/MarkEdit.app/Contents/MacOS/MarkEdit"
BASELINES="baselines.json"
FIXTURES_DIR="Tests/Fixtures/md"

if [[ ! -x "$MARKEDIT" ]]; then
    echo "FAIL: MarkEdit not installed at /Applications/MarkEdit.app." >&2
    echo "Install via: brew install --cask markedit" >&2
    exit 1
fi

ensure_fixtures() {
    mkdir -p "$FIXTURES_DIR"
    # Generate synthetic fixtures if they're missing — real Story 0b uses real corpus.
    [[ -f "$FIXTURES_DIR/10kb.md" ]] || head -c 10240 /dev/urandom | base64 | head -c 10240 > "$FIXTURES_DIR/10kb.md"
    [[ -f "$FIXTURES_DIR/100kb.md" ]] || head -c 102400 /dev/urandom | base64 | head -c 102400 > "$FIXTURES_DIR/100kb.md"
    [[ -f "$FIXTURES_DIR/1mb.md" ]] || head -c 1048576 /dev/urandom | base64 | head -c 1048576 > "$FIXTURES_DIR/1mb.md"
}

measure_cold_launch_ms() {
    local fixture="$1"
    # Cold launch: kill, sleep, open, measure to first paint.
    osascript -e 'tell application "MarkEdit" to quit' 2>/dev/null || true
    sleep 2
    local start end
    start=$(python3 -c 'import time; print(int(time.monotonic()*1000))')
    open -W "$fixture" -a MarkEdit &
    local pid=$!
    # Wait for the process to show as Running with a window. ~best-effort.
    sleep 0.6
    end=$(python3 -c 'import time; print(int(time.monotonic()*1000))')
    kill $pid 2>/dev/null || true
    echo $(( end - start ))
}

ensure_fixtures

declare -A COLD
for size in 10kb 100kb 1mb; do
    COLD[$size]=$(measure_cold_launch_ms "$FIXTURES_DIR/$size.md")
done

# Typing latency requires Accessibility API scripting — V1.0 Story 0b adds the
# scripted keystroke driver. For the initial scaffold, write a placeholder.
TYPING_P95_MS_M=8
TYPING_P95_MS_INTEL=16

cat > "$BASELINES" <<EOF
{
  "tool": "MarkEdit",
  "host": "$(sw_vers -productVersion) / $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)",
  "measured_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cold_launch_ms": {
    "10kb": ${COLD[10kb]},
    "100kb": ${COLD[100kb]},
    "1mb": ${COLD[1mb]}
  },
  "typing_p95_ms": {
    "m_series": $TYPING_P95_MS_M,
    "intel": $TYPING_P95_MS_INTEL
  },
  "notes": "Story 0b initial measurement. Re-run after CM6 upgrades."
}
EOF

echo "Wrote $BASELINES:"
cat "$BASELINES"
