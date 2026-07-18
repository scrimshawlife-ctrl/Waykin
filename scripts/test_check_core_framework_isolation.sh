#!/usr/bin/env bash
#
# Deterministic tests for scripts/check_core_framework_isolation.sh.
# Uses temporary fixture directories only — never touches the real
# Sources/WaykinCore tree. Exit 0 when all cases pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="${SCRIPT_DIR}/check_core_framework_isolation.sh"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/waykin-isolation-tests.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

failures=0
case_number=0

# run_guard <core-dir> [baseline-file] [strict]
run_guard() {
  local core_dir="$1"
  local baseline="${2:-/nonexistent-baseline}"
  local strict="${3:-0}"
  set +e
  OUTPUT="$(WAYKIN_ISOLATION_BASELINE="$baseline" WAYKIN_ISOLATION_STRICT="$strict" \
    "$GUARD" "$core_dir" 2>&1)"
  STATUS=$?
  set -e
}

check() {
  # check <description> <condition-result (0/1)>
  case_number=$((case_number + 1))
  if [ "$2" -eq 0 ]; then
    echo "ok ${case_number} - $1"
  else
    echo "not ok ${case_number} - $1"
    echo "#   guard exit: ${STATUS}"
    echo "#   guard output:"
    printf '%s\n' "$OUTPUT" | sed 's/^/#     /'
    failures=$((failures + 1))
  fi
}

# --- Case 1: clean core (standard-library imports only) exits zero -------
CLEAN="$TMP_ROOT/clean/Core"
mkdir -p "$CLEAN/Engines"
cat > "$CLEAN/Engines/Engine.swift" <<'EOF'
import Foundation
import Combine

struct Engine {}
EOF
run_guard "$CLEAN"
check "clean core with permitted imports passes" "$([ "$STATUS" -eq 0 ]; echo $?)"

# --- Case 2: forbidden import fails and names file, line, framework ------
BAD="$TMP_ROOT/bad/Core"
mkdir -p "$BAD/Views"
cat > "$BAD/Views/Leak.swift" <<'EOF'
import Foundation

import SwiftUI

struct Leak {}
EOF
run_guard "$BAD"
check "forbidden import exits nonzero" "$([ "$STATUS" -eq 1 ]; echo $?)"
check "error names the offending file" "$(printf '%s' "$OUTPUT" | grep -q "Views/Leak.swift"; echo $?)"
check "error names the line number" "$(printf '%s' "$OUTPUT" | grep -q "Views/Leak.swift:3:"; echo $?)"
check "error names the framework" "$(printf '%s' "$OUTPUT" | grep -q "'SwiftUI'"; echo $?)"

# --- Case 3: comments, doc text, and strings are not false positives -----
TEXTY="$TMP_ROOT/texty/Core"
mkdir -p "$TEXTY"
cat > "$TEXTY/Mentions.swift" <<'EOF'
import Foundation

// import SwiftUI would be forbidden here.
/// RealityKit and ARKit belong to the app adapter layer, not core.
let note = "import ARKit"
let doc = "CoreLocation is adapter-owned; see ARCHITECTURE.md"

struct Mentions {}
EOF
run_guard "$TEXTY"
check "framework names in comments/strings do not fail" "$([ "$STATUS" -eq 0 ]; echo $?)"

# --- Case 4: attributed, submodule, and scoped imports are detected ------
SNEAKY="$TMP_ROOT/sneaky/Core"
mkdir -p "$SNEAKY"
cat > "$SNEAKY/Sneaky.swift" <<'EOF'
import Foundation
@preconcurrency import CoreLocation
    import UIKit.UIView
import struct SwiftData.ModelContainer
EOF
run_guard "$SNEAKY"
check "attributed/submodule/scoped imports exit nonzero" "$([ "$STATUS" -eq 1 ]; echo $?)"
check "attributed import detected (CoreLocation)" "$(printf '%s' "$OUTPUT" | grep -q "'CoreLocation'"; echo $?)"
check "submodule import detected (UIKit)" "$(printf '%s' "$OUTPUT" | grep -q "'UIKit'"; echo $?)"
check "scoped import detected (SwiftData)" "$(printf '%s' "$OUTPUT" | grep -q "'SwiftData'"; echo $?)"

# --- Case 5: missing input directory fails clearly -----------------------
run_guard "$TMP_ROOT/does-not-exist"
check "missing source directory exits with usage error" "$([ "$STATUS" -eq 2 ]; echo $?)"
check "missing-directory error is explicit" "$(printf '%s' "$OUTPUT" | grep -q "expected source directory not found"; echo $?)"

# --- Case 6: baseline grandfathers exact pairs only (ratchet) ------------
RATCHET="$TMP_ROOT/ratchet/Core"
mkdir -p "$RATCHET/Location"
cat > "$RATCHET/Location/Adapter.swift" <<'EOF'
import Foundation
import CoreLocation
EOF
BASELINE_FILE="$TMP_ROOT/ratchet/baseline.txt"
cat > "$BASELINE_FILE" <<'EOF'
# test baseline
Location/Adapter.swift|CoreLocation
EOF
run_guard "$RATCHET" "$BASELINE_FILE"
check "baselined file|framework pair passes" "$([ "$STATUS" -eq 0 ]; echo $?)"

cat >> "$RATCHET/Location/Adapter.swift" <<'EOF'
import MapKit
EOF
run_guard "$RATCHET" "$BASELINE_FILE"
check "new framework in a baselined file still fails" "$([ "$STATUS" -eq 1 ]; echo $?)"
check "the new leak is the one reported (MapKit)" "$(printf '%s' "$OUTPUT" | grep -q "'MapKit'"; echo $?)"
check "the baselined import is not reported" "$(! printf '%s' "$OUTPUT" | grep -q "'CoreLocation'"; echo $?)"

# --- Case 7: strict mode ignores the baseline ----------------------------
run_guard "$RATCHET" "$BASELINE_FILE" 1
check "strict mode fails even baselined imports" "$([ "$STATUS" -eq 1 ]; echo $?)"
check "strict mode reports the baselined framework" "$(printf '%s' "$OUTPUT" | grep -q "'CoreLocation'"; echo $?)"

# --- Case 8: multiple violations produce deterministic ordering ----------
MULTI="$TMP_ROOT/multi/Core"
mkdir -p "$MULTI/Engines" "$MULTI/Views"
cat > "$MULTI/Engines/Alpha.swift" <<'EOF'
import Foundation
import SwiftUI
import MapKit
EOF
cat > "$MULTI/Views/Beta.swift" <<'EOF'
import ARKit
EOF
run_guard "$MULTI"
FIRST_RUN="$OUTPUT"
run_guard "$MULTI"
check "multiple violations exit nonzero" "$([ "$STATUS" -eq 1 ]; echo $?)"
check "all three violations are reported" "$([ "$(printf '%s\n' "$OUTPUT" | grep -c '^VIOLATION:')" -eq 3 ]; echo $?)"
check "repeated runs produce byte-identical output" "$([ "$FIRST_RUN" = "$OUTPUT" ]; echo $?)"
check "files are reported in sorted order (Alpha before Beta)" \
  "$([ "$(printf '%s\n' "$OUTPUT" | grep '^VIOLATION:' | head -1 | grep -c 'Engines/Alpha.swift')" -eq 1 ]; echo $?)"

# --- Case 9: the real repository baseline holds on the real core ---------
set +e
OUTPUT="$("$GUARD" 2>&1)"
STATUS=$?
set -e
check "real Sources/WaykinCore passes with the committed baseline" "$([ "$STATUS" -eq 0 ]; echo $?)"

echo ""
if [ "$failures" -gt 0 ]; then
  echo "test_check_core_framework_isolation: FAIL (${failures}/${case_number} cases failed)"
  exit 1
fi
echo "test_check_core_framework_isolation: PASS (${case_number} cases)"
exit 0
