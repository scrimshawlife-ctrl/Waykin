#!/usr/bin/env bash
# Capture simulator screenshots into docs/assets/screenshots/ (SIMULATOR evidence class).
# Does NOT prove outdoor readability. Run after installing a Debug sim build.
#
# Usage:
#   ./scripts/capture_sim_screenshots.sh [SIMULATOR_NAME]
#
# Optional: WAYKIN_BUNDLE_ID (default com.waykin.WaykinApp)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIM_NAME="${1:-${WAYKIN_SIMULATOR_NAME:-iPhone 17}}"
BUNDLE_ID="${WAYKIN_BUNDLE_ID:-com.waykin.WaykinApp}"
OUT_DIR="${REPO_ROOT}/docs/assets/screenshots"
SHA="$(git -C "${REPO_ROOT}" rev-parse --short HEAD)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="${OUT_DIR}/sim_${STAMP}_${SHA}"

mkdir -p "${RUN_DIR}"

echo "=== Waykin sim screenshots ==="
echo "Simulator: ${SIM_NAME}"
echo "Out: ${RUN_DIR}"

xcrun simctl boot "${SIM_NAME}" 2>/dev/null || true
xcrun simctl bootstatus "${SIM_NAME}" -b

# Best-effort: open app if installed.
xcrun simctl launch booted "${BUNDLE_ID}" 2>/dev/null || {
  echo "WARN: could not launch ${BUNDLE_ID} — install Debug build first."
  echo "      xcodebuild -scheme Waykin -destination 'platform=iOS Simulator,name=${SIM_NAME}' -derivedDataPath /tmp/waykin-dd build"
}

sleep 2
xcrun simctl io booted screenshot "${RUN_DIR}/01_home.png"
echo "Wrote ${RUN_DIR}/01_home.png"

cat > "${RUN_DIR}/RECEIPT.md" <<EOF
# Simulator screenshots

\`\`\`yaml
evidence_class: SIMULATOR
git_sha: ${SHA}
date_utc: ${STAMP}
device: ${SIM_NAME}
bundle: ${BUNDLE_ID}
\`\`\`

## Files

| File | Intended screen |
| ---- | --------------- |
| 01_home.png | Home (after launch) |

## Claims

- **OBSERVED in simulator only.**
- Not outdoor glare, GPS, or physical AR evidence.
EOF

echo "RECEIPT: ${RUN_DIR}/RECEIPT.md"
echo "DONE"
