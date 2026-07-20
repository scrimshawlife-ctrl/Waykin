#!/usr/bin/env bash
# Export artist lira.blend → runtime Lira_AR_Base.usdz (ARTIST_BLEND_MID_LOD).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BLEND="${1:-$HOME/Desktop/lira.blend}"
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
PY="$ROOT/scripts/export_lira_blend_to_usdz.py"
OUT_DIR="$ROOT/docs/assets/companion/ar/artist"
APP_OUT="$ROOT/App/Resources/Lira_AR_Base.usdz"
NESTED="$ROOT/App/Resources/Companion/Lira/Lira_AR_Base.usdz"
DOC_OUT="$ROOT/docs/assets/companion/ar/Lira_AR_Base.usdz"
ARTSOURCE="$ROOT/ArtSource/Companion/Lira"

if [[ ! -f "$BLEND" ]]; then
  echo "missing blend: $BLEND" >&2
  exit 1
fi
if [[ ! -x "$BLENDER" ]]; then
  echo "Blender not found at $BLENDER" >&2
  exit 1
fi
if ! command -v usdzip >/dev/null; then
  echo "usdzip not found" >&2
  exit 1
fi

mkdir -p "$OUT_DIR" "$ARTSOURCE"
# Preserve original artist file in ArtSource (skip if already that path)
BLEND_ABS="$(cd "$(dirname "$BLEND")" && pwd)/$(basename "$BLEND")"
ART_BLEND="$ARTSOURCE/lira.blend"
if [[ "$BLEND_ABS" != "$ART_BLEND" ]]; then
  cp "$BLEND" "$ART_BLEND"
fi

echo "=== Blender export (rename + scale + USD) ==="
"$BLENDER" --background "$BLEND" --python "$PY" -- "$BLEND"

USD=$(ls "$OUT_DIR"/Lira_AR_Base.usd "$OUT_DIR"/Lira_AR_Base.usdc 2>/dev/null | head -1 || true)
if [[ -z "${USD:-}" ]]; then
  # Blender may write a directory or usda
  USD=$(find "$OUT_DIR" -maxdepth 2 \( -name 'Lira_AR_Base.usd' -o -name 'Lira_AR_Base.usdc' -o -name 'Lira_AR_Base.usda' \) | head -1 || true)
fi
if [[ -z "${USD:-}" ]]; then
  echo "USD export not found under $OUT_DIR" >&2
  ls -laR "$OUT_DIR" >&2 || true
  exit 1
fi
echo "usd_source=$USD"

echo "=== usdzip → app Resources ==="
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
USD_DIR="$(cd "$(dirname "$USD")" && pwd)"
# Package USD + any sibling assets (textures/ referenced as @./textures/...@).
cp "$USD" "$TMP/"
# Top-level image/usd siblings
find "$USD_DIR" -maxdepth 1 -type f \( \
  -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.exr' \
  -o -name '*.usdc' -o -name '*.usda' -o -name '*.usd' \
\) ! -name "$(basename "$USD")" -exec cp {} "$TMP/" \; 2>/dev/null || true
# Nested texture directories (Blender often writes textures/)
if [[ -d "$USD_DIR/textures" ]]; then
  cp -R "$USD_DIR/textures" "$TMP/textures"
fi
# Any other relative asset dirs that look like texture folders
find "$USD_DIR" -mindepth 1 -maxdepth 1 -type d \( -name 'textures' -o -name 'Textures' -o -name 'maps' \) \
  -exec bash -c 'cp -R "$1" "$2/"' _ {} "$TMP" \; 2>/dev/null || true
rm -f "$APP_OUT" "$NESTED" "$DOC_OUT"
(cd "$TMP" && usdzip -r "$APP_OUT" .)
mkdir -p "$(dirname "$NESTED")"
cp "$APP_OUT" "$NESTED"
cp "$APP_OUT" "$DOC_OUT"
ls -la "$APP_OUT"
echo "usdz_entries=$(unzip -l "$APP_OUT" | tail -n +4 | head -n -2 | wc -l | tr -d ' ')"
unzip -l "$APP_OUT" | head -30
echo "evidence_class=ARTIST_BLEND_MID_LOD"
echo "wrote $APP_OUT"
echo "wrote $NESTED"
echo "wrote $DOC_OUT"
