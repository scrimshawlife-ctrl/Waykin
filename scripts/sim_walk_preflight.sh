#!/usr/bin/env bash
# Simulator walk preflight — OBSERVED in CI/simulator only. Not outdoor QA.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SHA=$(git rev-parse --short HEAD)
FULL=$(git rev-parse HEAD)
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
RECEIPT_DIR="docs/design/receipts"
mkdir -p "$RECEIPT_DIR"
RECEIPT="$RECEIPT_DIR/SIM_PREFLIGHT_${STAMP}_${SHA}.md"

echo "=== Waykin Simulator Walk Preflight ==="
echo "sha: $FULL"

PASS_VALIDATE=FAIL
PASS_PACKAGE=FAIL
PASS_DEMO=FAIL

set +e
make validate
VAL_EXIT=$?
set -e
if [ "$VAL_EXIT" -eq 0 ]; then PASS_VALIDATE=PASS; fi

set +e
swift test > /tmp/waykin-sim-walk-test.log 2>&1
TEST_EXIT=$?
set -e
if [ "$TEST_EXIT" -eq 0 ]; then PASS_PACKAGE=PASS; fi
if grep -q "DemoAndPhysicsTests" /tmp/waykin-sim-walk-test.log; then PASS_DEMO=PASS; fi
tail -5 /tmp/waykin-sim-walk-test.log || true

cat > "$RECEIPT" <<EOF
# Simulator Preflight Receipt

\`\`\`yaml
document_id: WAYKIN-SIM-PREFLIGHT-RECEIPT
date_utc: $DATE
git_sha: $FULL
git_short: $SHA
evidence_class: OBSERVED_IN_SIMULATOR_ONLY
outdoor_qa: NOT_COMPUTABLE
\`\`\`

## Automated checks

| Check | Result |
| ----- | ------ |
| make validate | $PASS_VALIDATE |
| swift package tests | $PASS_PACKAGE |
| Demo session tests exercised | $PASS_DEMO |

## Manual sim checklist (operator)

| ID | Check | Result |
| -- | ----- | ------ |
| S1 | Day appearance | |
| S2 | Night appearance | |
| S3 | Night not invert of day | |
| S4 | Home Lira + Form skins | |
| S5 | Begin Walk demo completes | |
| S6 | Pause / End calm | |
| S7 | Settings appearance force | |
| S8 | AR Companion form label | |

## Notes

- Does **not** prove outdoor glare, GPS integrity, or night street readability.
- Device walks use OUTDOOR_QA_RECEIPT_TEMPLATE.md.
EOF

echo "receipt: $RECEIPT"
echo "validate=$PASS_VALIDATE package=$PASS_PACKAGE demo=$PASS_DEMO"
if [ "$PASS_VALIDATE" != PASS ] || [ "$PASS_PACKAGE" != PASS ]; then
  exit 1
fi
