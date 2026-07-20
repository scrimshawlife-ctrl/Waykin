#!/usr/bin/env bash
# Scaffold indoor AR hybrid smoke receipt + run automated pre-device gates.
# Does NOT claim outdoor or device AR quality.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SHA=$(git rev-parse --short HEAD)
FULL=$(git rev-parse HEAD)
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
RECEIPT_DIR="docs/design/receipts"
mkdir -p "$RECEIPT_DIR"
RECEIPT="${RECEIPT_DIR}/INDOOR_AR_HYBRID_SMOKE_${STAMP}_${SHA}_PENDING.md"

echo "=== Waykin Indoor AR hybrid smoke prep ==="
echo "sha: $FULL"

PASS_USDZ=FAIL
PASS_VALIDATE=FAIL

set +e
make check-lira-usdz
USDZ_EXIT=$?
set -e
if [ "$USDZ_EXIT" -eq 0 ]; then PASS_USDZ=PASS; fi

set +e
make validate
VAL_EXIT=$?
set -e
if [ "$VAL_EXIT" -eq 0 ]; then PASS_VALIDATE=PASS; fi

cat > "$RECEIPT" <<EOF
# Indoor AR hybrid smoke receipt (PENDING human device)

\`\`\`yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: $DATE
git_sha: $FULL
git_short: $SHA
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE   # change to OBSERVED_INDOOR_DEVICE when walk done
outdoor_qa: NOT_COMPUTABLE
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
\`\`\`

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make check-lira-usdz | $PASS_USDZ |
| make validate | $PASS_VALIDATE |

## Device results I1–I12

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch → Home | | |
| I2 | Demo Begin Walk + operator strip | | |
| I3 | AR full-screen cover + Pause/End | | |
| I4 | Plant Lira on table/floor | | |
| I5 | Motion dcc/hybrid/puppet | | label: |
| I6 | State motion change | | |
| I7 | Lens cover / tracking loss | | |
| I8 | Leave AR clean | | |
| I9 | Re-open single entity | | |
| I10 | Reduce Motion | | |
| I11 | Skin swap if available | | |
| I12 | Receipt share arPresentation | | |

## Failures → new bounded issues

-

## Explicit non-claims

- Outdoor #41 COH / glare
- GPS integrity
- Battery / thermal (unless filled)

## Operator

1. Install Debug build of \`$SHA\` on a physical iPhone.
2. Follow \`docs/design/INDOOR_AR_HYBRID_SMOKE.md\`.
3. Fill I1–I12; set \`evidence_class: OBSERVED_INDOOR_DEVICE\` if completed.
4. PR the filled receipt (do not claim outdoor PASS).
EOF

echo "receipt: $RECEIPT"
echo "usdz=$PASS_USDZ validate=$PASS_VALIDATE"
echo "protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md"

if [ "$PASS_USDZ" != PASS ] || [ "$PASS_VALIDATE" != PASS ]; then
  exit 1
fi
