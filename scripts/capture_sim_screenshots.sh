#!/usr/bin/env bash
# Capture simulator screenshots into docs/assets/screenshots/ (SIMULATOR evidence class).
# Does NOT prove outdoor readability.
#
# Usage:
#   ./scripts/capture_sim_screenshots.sh [SIMULATOR_NAME]
#
# Modes:
#   Default: day/night Home via simctl appearance (requires installed Debug app).
#   Full matrix (Home + Session + Summary × day/night):
#     WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh
#
# Env:
#   WAYKIN_BUNDLE_ID (default com.waykin.WaykinApp)
#   WAYKIN_SIMULATOR_NAME / $1
#   WAYKIN_CAPTURE_FULL=1 — drive UI tests for session/summary frames
#   WAYKIN_DERIVED_DATA — xcodebuild derived data (default /tmp/waykin-dd-shots)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIM_NAME="${1:-${WAYKIN_SIMULATOR_NAME:-iPhone 17}}"
BUNDLE_ID="${WAYKIN_BUNDLE_ID:-com.waykin.WaykinApp}"
OUT_DIR="${REPO_ROOT}/docs/assets/screenshots"
SHA="$(git -C "${REPO_ROOT}" rev-parse --short HEAD)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="${OUT_DIR}/sim_${STAMP}_${SHA}"
DD="${WAYKIN_DERIVED_DATA:-/tmp/waykin-dd-shots}"
DEST="platform=iOS Simulator,name=${SIM_NAME}"

mkdir -p "${RUN_DIR}"

echo "=== Waykin sim screenshots ==="
echo "Simulator: ${SIM_NAME}"
echo "Out: ${RUN_DIR}"
echo "SHA: ${SHA}"

xcrun simctl boot "${SIM_NAME}" 2>/dev/null || true
xcrun simctl bootstatus "${SIM_NAME}" -b

capture_home() {
  local appearance="$1"
  local file="$2"
  xcrun simctl ui booted appearance "${appearance}"
  xcrun simctl terminate booted "${BUNDLE_ID}" 2>/dev/null || true
  xcrun simctl launch booted "${BUNDLE_ID}" 2>/dev/null || {
    echo "WARN: could not launch ${BUNDLE_ID} — building + installing Debug..."
    (
      cd "${REPO_ROOT}"
      xcodegen generate >/dev/null
      xcodebuild -scheme Waykin -destination "${DEST}" \
        -derivedDataPath "${DD}" \
        -configuration Debug build
      APP_PATH="$(find "${DD}/Build/Products/Debug-iphonesimulator" -name 'WaykinApp.app' -maxdepth 2 | head -1)"
      xcrun simctl install booted "${APP_PATH}"
      xcrun simctl launch booted "${BUNDLE_ID}"
    )
  }
  sleep 2
  xcrun simctl io booted screenshot "${RUN_DIR}/${file}"
  echo "Wrote ${RUN_DIR}/${file}"
}

# Full matrix via UI tests (preferred — waits past splash, forces app day/night)
if [[ "${WAYKIN_CAPTURE_FULL:-0}" == "1" ]]; then
  echo "=== Full matrix via UI tests ==="
  printf '%s\n' "${RUN_DIR}" > /tmp/waykin_screenshot_out_dir.txt
  (
    cd "${REPO_ROOT}"
    xcodegen generate >/dev/null
    export WAYKIN_CAPTURE_SCREENSHOTS=1
    export WAYKIN_SCREENSHOT_OUT_DIR="${RUN_DIR}"
    xcodebuild test \
      -scheme Waykin \
      -destination "${DEST}" \
      -derivedDataPath "${DD}" \
      -only-testing:WaykinUITests/ScreenshotMatrixCaptureTests/testCaptureDayNightWalkSurfaces
  )
  rm -f /tmp/waykin_screenshot_out_dir.txt
else
  # Home-only fallback (may catch splash if app cold-launches; prefer FULL=1)
  capture_home light "01_home_day.png"
  capture_home dark "04_home_night.png"
fi

# Normalize: UI test may write without .png extension already handled
FILE_ROWS=""
for f in "${RUN_DIR}"/*.png; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"
  case "$base" in
    01_home_day.png) label="Home (day)" ;;
    02_session_day.png) label="Active Session Demo (day)" ;;
    03_summary_day.png) label="Session Summary (day)" ;;
    04_home_night.png) label="Home (night)" ;;
    05_session_night.png) label="Active Session Demo (night)" ;;
    06_summary_night.png) label="Session Summary (night)" ;;
    *) label="(see filename)" ;;
  esac
  FILE_ROWS+="| ${base} | ${label} |"$'\n'
done

cat > "${RUN_DIR}/RECEIPT.md" <<EOF
# Simulator screenshots

\`\`\`yaml
evidence_class: SIMULATOR
git_sha: ${SHA}
date_utc: ${STAMP}
device: ${SIM_NAME}
bundle: ${BUNDLE_ID}
full_matrix: ${WAYKIN_CAPTURE_FULL:-0}
issue: 194
\`\`\`

## Files

| File | Intended screen |
| ---- | --------------- |
${FILE_ROWS}

## Claims

- **OBSERVED in simulator only.**
- Not outdoor glare, GPS, physical AR, battery, or headphone evidence.
- Night frames use app appearance force and/or sim dark mode — not outdoor night.

## Reproduce

\`\`\`bash
# Home day/night only
./scripts/capture_sim_screenshots.sh "${SIM_NAME}"

# Full walk surfaces
WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh "${SIM_NAME}"
\`\`\`
EOF

echo "RECEIPT: ${RUN_DIR}/RECEIPT.md"
echo "DONE"
ls -la "${RUN_DIR}"
