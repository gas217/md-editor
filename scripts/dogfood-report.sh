#!/usr/bin/env bash
# dogfood-report.sh — read the dogfood log and report qualifying-day count.
# A "qualifying day" = ≥1 session of ≥5 minutes wall-clock with at least one of
# {save, comment_created, comment_resolved}. See VISION.md "V1.0 → V1.1 transition gate".

set -euo pipefail

WINDOW_DAYS=30

# Pull all signposts from the mdedit dogfood subsystem from the last 30 days.
# Format: timestamp + event type. Real implementation aggregates per-day.
LOG_LINES=$(log show \
    --predicate 'subsystem == "com.mdedit.dogfood"' \
    --last "${WINDOW_DAYS}d" \
    --style ndjson 2>/dev/null || true)

if [[ -z "$LOG_LINES" ]]; then
    echo "No dogfood log entries found in the last ${WINDOW_DAYS} days."
    echo "qualifying_days: 0 / ${WINDOW_DAYS}"
    exit 0
fi

# Parse: count distinct YYYY-MM-DD on which a qualifying event fired.
QUALIFYING=$(echo "$LOG_LINES" | python3 -c '
import sys, json, datetime
days = set()
qualifying_events = {"save", "comment_created", "comment_resolved"}
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        e = json.loads(line)
        msg = e.get("eventMessage", "")
        ts = e.get("timestamp", "")
        # eventMessage format: "event=<name> session_secs=<n>"
        if any(f"event={ev}" in msg for ev in qualifying_events):
            day = ts[:10]  # YYYY-MM-DD
            days.add(day)
    except (json.JSONDecodeError, KeyError):
        continue
print(len(days))
')

echo "qualifying_days: ${QUALIFYING} / ${WINDOW_DAYS}"
if (( QUALIFYING >= WINDOW_DAYS )); then
    echo "GATE MET ✓"
    exit 0
else
    echo "GATE NOT YET MET"
    exit 1
fi
