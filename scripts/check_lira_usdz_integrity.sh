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

# Artist packages: default layer must be Lira_AR_Base.usd (not a clip sidecar).
# Zip listing order = archive order; first data row after headers is the default layer.
first_entry=$(unzip -Z1 "$ROOT_USDZ" 2>/dev/null | head -1 || true)
if [[ -n "$first_entry" ]]; then
  if [[ "$first_entry" == "Lira_AR_Base.usd" || "$first_entry" == "Lira_AR_Base.usdc" || "$first_entry" == *.usdc ]]; then
    pass "default layer first entry ($first_entry)"
  elif [[ "$first_entry" == Lira_*.usd ]]; then
    fail "default layer is clip sidecar ($first_entry); repack with Lira_AR_Base.usd first"
  else
    pass "default layer first entry ($first_entry)"
  fi
fi

if [[ -f "$MARKER" ]]; then
  if grep -E 'MESHY_TEXTURED_STATIC_V1|ARTIST_BLEND_HERO_DCC_MID_LOD|ARTIST_BLEND_SKINNED_MID_LOD|ARTIST_BLEND_ARMATURE_MID_LOD|ARTIST_BLEND_MID_LOD' "$MARKER" >/dev/null; then
    pass "EXPORT_OK evidence marker"
  else
    fail "EXPORT_OK missing known evidence class"
  fi
fi

# Artist DCC clip sidecars (optional but expected for ARTIST_BLEND_HERO_DCC_MID_LOD).
CLIP_DIR="$ROOT/App/Resources/Companion/Lira/Clips"
if grep -q 'ARTIST_BLEND_HERO_DCC_MID_LOD' "$ROOT/App/AR/Companion/LiraARAssetCatalog.swift" 2>/dev/null; then
  missing=0
  for clip in Lira_Idle Lira_Follow Lira_Investigate Lira_Alert Lira_Celebrate Lira_Spawn; do
    if [[ ! -f "$CLIP_DIR/${clip}.usdz" ]]; then
      echo "WARN: missing DCC sidecar $CLIP_DIR/${clip}.usdz"
      missing=$((missing + 1))
    fi
  done
  if [[ "$missing" -eq 0 ]]; then
    pass "DCC clip sidecars present (6)"
  else
    echo "WARN: $missing DCC clip sidecars missing (runtime falls back to puppet)"
  fi

  # A sidecar can exist and still contain a single frozen pose: Blender 5's USD
  # writer emits SkelAnimation joint arrays with no timeSamples, which RealityKit
  # reports as availableAnimations=0 (#225). Presence alone is not enough —
  # require real animated joint curves so a static re-export fails loudly here
  # instead of silently shipping motionless clips.
  if command -v usdcat >/dev/null 2>&1; then
    static=0
    for clip in Lira_Idle Lira_Follow Lira_Investigate Lira_Alert Lira_Celebrate Lira_Spawn; do
      src="$CLIP_DIR/${clip}.usdz"
      [[ -f "$src" ]] || continue
      # `grep -c` (not `-q`): under `set -o pipefail` an early-exiting `grep -q`
      # SIGPIPEs usdcat and the pipeline reports failure even on a match.
      curves=$(usdcat "$src" 2>/dev/null | grep -c 'rotations.timeSamples' || true)
      if [[ "${curves:-0}" -eq 0 ]]; then
        echo "FAIL: $clip.usdz has no animated joint curves (static pose export)"
        static=$((static + 1))
      fi
    done
    if [[ "$static" -gt 0 ]]; then
      echo "check_lira_usdz_integrity: FAIL ($static clip(s) without timeSamples)"
      exit 1
    fi
    pass "DCC clip sidecars carry animated joint curves"
  else
    echo "WARN: usdcat unavailable; skipped DCC animation-curve check"
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
