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

# Runtime mid-LOD budget: keep installable without thrash (ArtSource may be full-res).
# Soft target ~12MB; hard fail above 20MB to catch accidental 4K re-import.
if [[ "$s1" -gt 20971520 ]]; then
  fail "runtime usdz too large ($s1 bytes > 20MB); run scripts/compress_lira_meshy_usdz.sh"
elif [[ "$s1" -gt 12582912 ]]; then
  echo "WARN: runtime usdz $s1 bytes > 12MB soft budget (still under 20MB hard cap)"
else
  pass "runtime size within soft budget ($s1 bytes ≤ 12MB)"
fi

# Accept artist USD layout OR Meshy static layout (usdc + textures/images).
if unzip -l "$ROOT_USDZ" | grep -E 'Lira_AR_Base\.usd|textures/|\.usdc|extracted_image_|\.jpg|\.png' >/dev/null; then
  pass "usdz entries present"
else
  fail "usdz missing usd/usdc/texture entries"
fi

if [[ -f "$MARKER" ]]; then
  if grep -E 'MESHY_TEXTURED_STATIC_V1|ARTIST_BLEND_HERO_DCC_MID_LOD|ARTIST_BLEND_SKINNED_MID_LOD|ARTIST_BLEND_ARMATURE_MID_LOD|ARTIST_BLEND_MID_LOD' "$MARKER" >/dev/null; then
    pass "EXPORT_OK evidence marker"
  else
    fail "EXPORT_OK missing known evidence class"
  fi
fi

# Catalog Swift evidence class should match shipped package class
if grep -q 'MESHY_TEXTURED_STATIC_V1' "$ROOT/App/AR/Companion/LiraARAssetCatalog.swift"; then
  pass "catalog evidence MESHY_TEXTURED_STATIC_V1"
elif grep -q 'ARTIST_BLEND_HERO_DCC_MID_LOD' "$ROOT/App/AR/Companion/LiraARAssetCatalog.swift"; then
  pass "catalog evidence ARTIST_BLEND_HERO_DCC_MID_LOD"
elif grep -q 'ARTIST_BLEND_SKINNED_MID_LOD' "$ROOT/App/AR/Companion/LiraARAssetCatalog.swift"; then
  pass "catalog evidence ARTIST_BLEND_SKINNED_MID_LOD"
fi

echo "check_lira_usdz_integrity: PASS"
