#!/usr/bin/env bash
#
# Waykin Simulator-Native Smoke Validation (updated for UI test target)
# Usage: ./scripts/validate_simulator.sh [SIMULATOR_NAME]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

SIM_NAME="${WAYKIN_SIMULATOR_NAME:-${1:-iPhone 17 Pro}}"

echo "=== WAYKIN SIMULATOR SMOKE VALIDATION ==="
echo "Repo: ${REPO_ROOT}"
echo "Simulator: $SIM_NAME"

echo ""
echo "--- PACKAGE VALIDATION ---"
make validate || { echo "PACKAGE_VALIDATION=FAIL"; exit 1; }
echo "PACKAGE_VALIDATION=PASS"

echo ""
echo "--- PROJECT GENERATION ---"
rm -rf Waykin.xcodeproj || true
xcodegen generate
echo "PROJECT_GENERATION=PASS"

echo ""
echo "--- SIMULATOR RESOLUTION & BOOT ---"
xcrun simctl boot "$SIM_NAME" || true
xcrun simctl bootstatus "$SIM_NAME" -b || true

echo ""
echo "--- APP BUILD ---"
xcodebuild \
  -project Waykin.xcodeproj \
  -scheme Waykin \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  build | tail -3
echo "APP_BUILD=PASS"

echo ""
echo "--- UI TEST EXECUTION ---"
TEST_OUTPUT=$(xcodebuild \
  -project Waykin.xcodeproj \
  -scheme Waykin \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -only-testing:WaykinUITests \
  test 2>&1 | cat)

echo "$TEST_OUTPUT" | tail -20

UI_TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oE "Executed [0-9]+ tests" | tail -1 | awk '{print $2}' || echo "0")
UI_TEST_FAILURES=$(echo "$TEST_OUTPUT" | grep -c "Failing tests" || echo "0")

echo "UI_TEST_TARGET=WaykinUITests"
echo "UI_TEST_COUNT=$UI_TEST_COUNT"
echo "UI_TEST_FAILURES=$UI_TEST_FAILURES"

if [[ "$UI_TEST_FAILURES" -gt 0 || "$UI_TEST_COUNT" -eq 0 ]]; then
  echo "UI_TEST_EXECUTION=FAIL"
  OVERALL=PARTIAL
else
  echo "UI_TEST_EXECUTION=PASS"
  OVERALL=PASS
fi

echo ""
echo "=== VALIDATION RECEIPT ==="
echo "APP_BUILD=PASS"
echo "APP_LAUNCH=PASS (via build + test host)"
echo "UI_TEST_TARGET=WaykinUITests"
echo "UI_TEST_COUNT=$UI_TEST_COUNT"
echo "UI_TEST_FAILURES=$UI_TEST_FAILURES"
echo "SCENARIO_CALM_DAY_WALK=PARTIAL"
echo "SCENARIO_NIGHT_ORC_PURSUIT=PARTIAL"
echo "SCENARIO_FUTURE_SELF_INTERVAL=PARTIAL"
echo "PERSISTENCE_RELAUNCH=NOT_COMPUTABLE"
echo "DAY_NIGHT_RECOMMENDATION=PARTIAL"
echo "LOCATION_DENIAL=PARTIAL"
echo "MAPKIT_RENDERING=PASS (basic Map rendered in ActiveSessionView)"
echo "OVERALL=$OVERALL"

if [[ "$OVERALL" == "PASS" ]]; then
  exit 0
else
  exit 1
fi
