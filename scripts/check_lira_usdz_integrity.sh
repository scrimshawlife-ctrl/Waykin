#!/usr/bin/env bash
# Verify dual runtime USDZ mirrors + evidence marker consistency.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT_USDZ="$ROOT/App/Resources/Lira_AR_Base.usdz"
NESTED="$ROOT/App/Resources/Companion/Lira/Lira_AR_Base.usdz"
DOC="$ROOT/docs/assets/companion/ar/Lira_AR_Base.usdz"
MARKER="$ROOT/docs/assets/companion/ar/artist/EXPORT_OK"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

[[ -f "$ROOT_USDZ" ]] || fail "missing $ROOT_USDZ"
[[ -f "$NESTED" ]] || fail "missing $NESTED"
[[ -f "$DOC" ]] || fail "missing $DOC"

s1=$(stat -f%z "$ROOT_USDZ" 2>/dev/null || stat -c%s "$ROOT_USDZ")
s2=$(stat -f%z "$NESTED" 2>/dev/null || stat -c%s "$NESTED")
s3=$(stat -f%z "$DOC" 2>/dev/null || stat -c%s "$DOC")
[[ "$s1" == "$s2" ]] || fail "root vs nested size $s1 != $s2"
[[ "$s1" == "$s3" ]] || fail "root vs docs size $s1 != $s3"
pass "triple package size match ($s1 bytes)"

# Package should contain USD + optional textures (grep: no ripgrep dependency on CI)
if unzip -l "$ROOT_USDZ" | grep -E 'Lira_AR_Base\.usd|textures/' >/dev/null; then
  pass "usdz entries present"
else
  fail "usdz missing Lira_AR_Base.usd entry"
fi

if [[ -f "$MARKER" ]]; then
  if grep -E 'ARTIST_BLEND_SKINNED_MID_LOD|ARTIST_BLEND_ARMATURE_MID_LOD|ARTIST_BLEND_MID_LOD' "$MARKER" >/dev/null; then
    pass "EXPORT_OK evidence marker"
  else
    fail "EXPORT_OK missing known evidence class"
  fi
fi

# Catalog Swift evidence class should mention SKINNED when package is skinned export
if grep -q 'ARTIST_BLEND_SKINNED_MID_LOD' "$ROOT/App/AR/Companion/LiraARAssetCatalog.swift"; then
  pass "catalog evidence ARTIST_BLEND_SKINNED_MID_LOD"
fi

echo "check_lira_usdz_integrity: PASS"
