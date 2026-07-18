#!/usr/bin/env bash
#
# Waykin structural guard: WaykinCore must stay platform-neutral.
#
# Fails when a Swift source file under Sources/WaykinCore imports a
# forbidden platform framework, unless that exact (file, framework) pair
# is listed in the reviewed baseline. The baseline is a ratchet for the
# pre-existing, architecture-documented platform adapters that currently
# live inside WaykinCore (see ARCHITECTURE.md: RealLocationProvider is a
# foreground Core Location adapter; session memories persist via
# SwiftData). New leaks always fail; baseline entries require explicit
# review to add.
#
# Usage:
#   scripts/check_core_framework_isolation.sh [CORE_DIR]
#
# Environment:
#   WAYKIN_ISOLATION_BASELINE   baseline file path
#                               (default: scripts/core_isolation_baseline.txt)
#   WAYKIN_ISOLATION_STRICT=1   ignore the baseline entirely
#
# Exit codes: 0 = clean, 1 = violations found, 2 = usage/environment error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CORE_DIR="${1:-${REPO_ROOT}/Sources/WaykinCore}"
BASELINE="${WAYKIN_ISOLATION_BASELINE:-${SCRIPT_DIR}/core_isolation_baseline.txt}"
STRICT="${WAYKIN_ISOLATION_STRICT:-0}"

FRAMEWORKS="ARKit RealityKit SwiftUI MapKit SwiftData AVFoundation CoreLocation UIKit AppKit"

if [ ! -d "$CORE_DIR" ]; then
  echo "check_core_framework_isolation: ERROR: expected source directory not found: $CORE_DIR" >&2
  exit 2
fi

baseline_allows() {
  # $1 = path relative to CORE_DIR, $2 = framework
  [ "$STRICT" = "1" ] && return 1
  [ -f "$BASELINE" ] || return 1
  grep -v '^#' "$BASELINE" | sed '/^[[:space:]]*$/d' | grep -qxF "$1|$2"
}

violations=0

# Deterministic traversal order regardless of filesystem.
FILE_LIST="$(cd "$CORE_DIR" && find . -type f -name '*.swift' | LC_ALL=C sort)"

while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  rel="${rel#./}"
  file="$CORE_DIR/$rel"
  for fw in $FRAMEWORKS; do
    # Valid Swift import syntax only: optional leading whitespace, optional
    # attributes (@preconcurrency, @_exported, @testable), optional scoped
    # import kind (import struct SwiftUI.Color), then the framework as the
    # module (or submodule: import UIKit.UIView). Comments, doc text, and
    # string literals that merely mention a framework never match.
    pattern="^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+((class|struct|enum|protocol|typealias|func|var|let)[[:space:]]+)?${fw}([.[:space:]]|$)"
    hits="$(grep -nE "$pattern" "$file" || true)"
    [ -z "$hits" ] && continue
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      line="${hit%%:*}"
      if baseline_allows "$rel" "$fw"; then
        continue
      fi
      echo "VIOLATION: ${rel}:${line}: forbidden framework '${fw}' imported in WaykinCore"
      violations=$((violations + 1))
    done <<EOF2
$hits
EOF2
  done
done <<EOF
$FILE_LIST
EOF

if [ "$violations" -gt 0 ]; then
  echo ""
  echo "check_core_framework_isolation: FAIL (${violations} violation(s))"
  echo "WaykinCore must remain platform-neutral. Move platform framework use into"
  echo "the App target adapter layer, or (only with explicit architecture review)"
  echo "add the exact file|framework pair to scripts/core_isolation_baseline.txt."
  exit 1
fi

echo "check_core_framework_isolation: PASS (no forbidden platform imports outside baseline)"
exit 0
