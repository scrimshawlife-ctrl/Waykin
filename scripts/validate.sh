#!/usr/bin/env bash
#
# Waykin Canonical Validation Harness
# Usage: ./scripts/validate.sh
# Or via: make validate
#
# Resolves repo root, runs deterministic validation, prints receipt.
# Does not modify tracked files except for the generated Xcode project.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

echo "=== WAYKIN CANONICAL VALIDATION ==="
echo "Repo root: ${REPO_ROOT}"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo ""
echo "--- Tool Versions ---"
swift --version | head -1
xcodegen --version 2>/dev/null || echo "xcodegen: NOT_FOUND"
xcodebuild -version 2>/dev/null | head -1 || echo "xcodebuild: NOT_COMPUTABLE"

echo ""
echo "--- Tool Checks ---"
command -v swift >/dev/null || { echo "ERROR: swift not found"; exit 1; }
command -v xcodegen >/dev/null || { echo "ERROR: xcodegen not found"; exit 1; }

XCODEBUILD_AVAILABLE=true
if ! command -v xcodebuild >/dev/null; then
  XCODEBUILD_AVAILABLE=false
  echo "xcodebuild: NOT_COMPUTABLE"
fi

echo ""
echo "--- Pre-validation drift ---"
git status --short || true

EXIT_CODE=0

echo ""
echo "--- Structural guard: WaykinCore framework isolation ---"
if "${SCRIPT_DIR}/check_core_framework_isolation.sh"; then
  echo "core framework isolation: PASS"
else
  echo "core framework isolation: FAIL"
  EXIT_CODE=1
fi

echo ""
echo "--- Structural guard: Lira USDZ integrity ---"
if "${SCRIPT_DIR}/check_lira_usdz_integrity.sh"; then
  echo "lira usdz integrity: PASS"
else
  echo "lira usdz integrity: FAIL"
  EXIT_CODE=1
fi

echo ""
echo "--- Structural guard: collaboration coordination ---"
if python3 "${SCRIPT_DIR}/validate_collaboration_coordination.py"; then
  echo "collaboration coordination: PASS"
else
  echo "collaboration coordination: FAIL"
  EXIT_CODE=1
fi

echo ""
echo "--- Regenerate project ---"
rm -rf Waykin.xcodeproj || true
if xcodegen generate; then
  echo "xcodegen generate: PASS"
else
  echo "xcodegen generate: FAIL"
  EXIT_CODE=1
fi

echo ""
echo "--- Swift package ---"
if swift build; then
  echo "swift build: PASS"
else
  echo "swift build: FAIL"
  EXIT_CODE=1
fi

TEST_OUTPUT=$(swift test 2>&1 || true)
if echo "$TEST_OUTPUT" | grep -q "Test Suite 'All tests' passed"; then
  TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oE "Executed [0-9]+ tests" | tail -1 | awk '{print $2}' || echo "?")
  echo "swift test: PASS (${TEST_COUNT} tests)"
else
  echo "swift test: FAIL"
  echo "$TEST_OUTPUT" | tail -10
  EXIT_CODE=1
fi

if [ "$XCODEBUILD_AVAILABLE" = true ]; then
  echo ""
  echo "--- Native build (best effort) ---"
  SIM="iPhone 17 Pro"
  if xcodebuild -project Waykin.xcodeproj -scheme Waykin -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIM" build > /tmp/waykin-xcodebuild.log 2>&1; then
    echo "xcodebuild (WaykinApp): PASS"
  else
    echo "xcodebuild (WaykinApp): FAIL (see /tmp/waykin-xcodebuild.log)"
  fi
else
  echo ""
  echo "XCODEBUILD_VALIDATION=NOT_COMPUTABLE"
fi

echo ""
echo "--- Post-validation drift ---"
git status --short || true

echo ""
echo "=== VALIDATION RECEIPT ==="
if [ $EXIT_CODE -eq 0 ]; then
  echo "OVERALL: PASS (package + generation)"
else
  echo "OVERALL: FAIL (first error code preserved)"
fi

exit $EXIT_CODE
