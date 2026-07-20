#!/usr/bin/env bash
# Compress Meshy/runtime Lira_AR_Base.usdz textures for mobile AR mid-LOD.
# Keeps USD filenames so crate paths remain valid. ArtSource full-res is unchanged.
#
# Usage:
#   ./scripts/compress_lira_meshy_usdz.sh [input.usdz]
# Default input: App/Resources/Lira_AR_Base.usdz
# Writes compressed package to the runtime triple (root / nested / docs).
#
# Important: RealityKit requires the root USD/USDC to be the **first** zip entry.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IN="${1:-$ROOT/App/Resources/Lira_AR_Base.usdz}"
APP_OUT="$ROOT/App/Resources/Lira_AR_Base.usdz"
NESTED="$ROOT/App/Resources/Companion/Lira/Lira_AR_Base.usdz"
DOC_OUT="$ROOT/docs/assets/companion/ar/Lira_AR_Base.usdz"

MAX_ALBEDO="${LIRA_TEX_MAX_ALBEDO:-2048}"
MAX_ORM="${LIRA_TEX_MAX_ORM:-1024}"

[[ -f "$IN" ]] || { echo "missing input: $IN" >&2; exit 1; }
command -v usdzip >/dev/null || { echo "usdzip not found" >&2; exit 1; }
command -v sips >/dev/null || { echo "sips not found" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "=== extract $IN ==="
PAYLOAD="$TMP/payload"
mkdir -p "$PAYLOAD"
unzip -q -o "$IN" -d "$PAYLOAD"

resize_max() {
  local file="$1" max="$2"
  [[ -f "$file" ]] || return 0
  local w h
  w=$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  [[ -n "$w" && -n "$h" ]] || return 0
  local edge=$w
  if [[ "$h" -gt "$edge" ]]; then edge=$h; fi
  if [[ "$edge" -gt "$max" ]]; then
    echo "resize $(basename "$file") ${w}x${h} → max ${max}"
    sips -Z "$max" "$file" >/dev/null
  else
    echo "keep $(basename "$file") ${w}x${h}"
  fi
}

shopt -s nullglob
for f in "$PAYLOAD"/*.jpg "$PAYLOAD"/*.jpeg "$PAYLOAD"/*.JPG; do
  base=$(basename "$f")
  case "$base" in
    *metallic*|*roughness*|*normal*|*ao*|*orm*)
      resize_max "$f" "$MAX_ORM"
      ;;
    *)
      resize_max "$f" "$MAX_ALBEDO"
      ;;
  esac
done
for f in "$PAYLOAD"/*.png "$PAYLOAD"/*.PNG; do
  base=$(basename "$f")
  case "$base" in
    *metallic*|*roughness*|*normal*|*ao*|*orm*)
      resize_max "$f" "$MAX_ORM"
      ;;
    *)
      resize_max "$f" "$MAX_ALBEDO"
      ;;
  esac
done
shopt -u nullglob

OUT_TMP="$TMP/out.usdz"
echo "=== usdzip (USD/USDC first) ==="
# RealityKit requires the root USD/USDC to be the first archive entry.
USD_ARGS=()
OTHER_ARGS=()
for f in "$PAYLOAD"/*; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f")
  case "$base" in
    *.usdc|*.usd|*.usda) USD_ARGS+=("$base") ;;
    *) OTHER_ARGS+=("$base") ;;
  esac
done
[[ ${#USD_ARGS[@]} -ge 1 ]] || { echo "no USD/USDC in package" >&2; exit 1; }

(cd "$PAYLOAD" && usdzip "$OUT_TMP" "${USD_ARGS[@]}" "${OTHER_ARGS[@]}")

in_size=$(stat -f%z "$IN" 2>/dev/null || stat -c%s "$IN")
out_size=$(stat -f%z "$OUT_TMP" 2>/dev/null || stat -c%s "$OUT_TMP")
echo "size: $in_size → $out_size bytes"
first=$(unzip -l "$OUT_TMP" | awk 'NR==4 {print $4}')
echo "first entry: $first"
case "$first" in
  *.usdc|*.usd|*.usda) ;;
  *) echo "WARN: first entry is not USD/USDC ($first) — RealityKit may fail to load" >&2 ;;
esac

mkdir -p "$(dirname "$NESTED")" "$(dirname "$DOC_OUT")"
cp "$OUT_TMP" "$APP_OUT"
cp "$OUT_TMP" "$NESTED"
cp "$OUT_TMP" "$DOC_OUT"
echo "installed → $APP_OUT"
echo "installed → $NESTED"
echo "installed → $DOC_OUT"

"$ROOT/scripts/check_lira_usdz_integrity.sh"
echo "compress_lira_meshy_usdz: PASS"
