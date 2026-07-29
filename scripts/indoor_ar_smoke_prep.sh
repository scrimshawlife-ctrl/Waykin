#!/usr/bin/env bash
# Scaffold indoor Ember Fox AR smoke receipt + run automated pre-device gates.
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

echo "=== Waykin Indoor Ember Fox AR smoke prep ==="
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
# Indoor Ember Fox AR smoke receipt (PENDING human device)

\`\`\`yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: $DATE
git_sha: $FULL
git_short: $SHA
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE   # change to OBSERVED when walk done (note indoor in device fields)
outdoor_qa: NOT_COMPUTABLE
companion_runtime: MESHY_EMBER_FOX_WALK_V1
visual_reference: docs/design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
\`\`\`

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make check-lira-usdz | $PASS_USDZ |
| make validate | $PASS_VALIDATE |
| installed tip SHA | $FULL |

## Visual gold standard

Compare to Prabu device still:
- \`docs/design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md\`
- \`docs/design/receipts/evidence/IMG_2534_prabu_ember_fox_device.png\`
- Expect authored fox mesh, not procedural spheres; \`animated_usdz\` when follow/anim live.

## Device results I1–I14

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch / clean install | | |
| I2 | Session start; persistence healthy | | |
| I3 | AR full-screen + Pause/End | | |
| I4 | Procedural fallback only during load | | timing: |
| I5 | Ember Fox replaces fallback | | match Prabu look? |
| I6 | Single companion after replace | | anchor count: |
| I7 | Height / ground contact | | |
| I8 | Skeleton animation | | strip labels: |
| I9 | Stationary pause / idle | | |
| I10 | Closing distance / follow anim | | |
| I11 | Plant / replant / interrupt / background | | |
| I12 | End session + arPresentation receipt | | schema: |
| I13 | Audio under intended policy | | |
| I14 | No severe hitch / thermal / re-decode | | |

## Failures → new bounded issues

-

## Explicit non-claims

- Outdoor #41 COH / glare
- GPS integrity
- Battery / thermal PASS (unless OBSERVED rows filled)
- Closing #247 without this tip's SHA recorded

## Operator

1. Install Debug build of exact tip \`$FULL\` on a physical iPhone (\`git pull\` first; do not assume a stale short SHA).
2. Follow \`docs/design/INDOOR_AR_HYBRID_SMOKE.md\` v2 (Ember Fox).
3. Fill I1–I14; set \`evidence_class: OBSERVED\` if completed on named device (note indoor in device fields). Never use \`OBSERVED_INDOOR_DEVICE\`.
4. PR the filled receipt (do not claim outdoor PASS).
EOF

echo "receipt: $RECEIPT"
echo "usdz=$PASS_USDZ validate=$PASS_VALIDATE"
echo "protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md"

if [ "$PASS_USDZ" != PASS ] || [ "$PASS_VALIDATE" != PASS ]; then
  exit 1
fi
