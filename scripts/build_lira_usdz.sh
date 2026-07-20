#!/usr/bin/env bash
# Generate Lira mid-LOD USDA (if needed), package USDZ, install into app Resources.
# Evidence class: GENERATED_MID_LOD (procedural prim hierarchy + joint nesting).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT/docs/assets/companion/ar/src"
SRC="$SRC_DIR/Lira_AR_Base.usda"
# Packaged at Resources root so xcodegen reliably copies into the app bundle.
APP_OUT="$ROOT/App/Resources/Lira_AR_Base.usdz"
NESTED="$ROOT/App/Resources/Companion/Lira/Lira_AR_Base.usdz"
DOC_OUT="$ROOT/docs/assets/companion/ar/Lira_AR_Base.usdz"
GEN="$ROOT/scripts/generate_lira_mid_lod_usda.py"

if [[ ! -f "$GEN" ]]; then
  echo "missing generator: $GEN" >&2
  exit 1
fi
if ! command -v usdzip >/dev/null; then
  echo "usdzip not found (Xcode command line tools)" >&2
  exit 1
fi
if ! command -v python3 >/dev/null; then
  echo "python3 not found" >&2
  exit 1
fi

echo "=== generate USDA (GENERATED_MID_LOD) ==="
python3 "$GEN" --out "$SRC"

echo "=== package USDZ ==="
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cp "$SRC" "$TMP/default.usda"
rm -f "$APP_OUT" "$NESTED" "$DOC_OUT"
(cd "$TMP" && usdzip -r "$APP_OUT" .)
mkdir -p "$(dirname "$NESTED")"
cp "$APP_OUT" "$NESTED"
cp "$APP_OUT" "$DOC_OUT"

echo "wrote $APP_OUT"
echo "wrote $NESTED"
echo "wrote $DOC_OUT"
ls -la "$APP_OUT"

# Lightweight hierarchy token check on source (bundle load covered by AppTests).
for name in LiraRoot Body Head LeftEar RightEar Tail Filament CoreGlow GroundShadow StatusIndicator FilamentMid FilamentTip; do
  if ! grep -q "\"$name\"" "$SRC"; then
    echo "FAIL: missing node token $name in $SRC" >&2
    exit 1
  fi
done
echo "hierarchy_tokens=PASS"
echo "evidence_class=GENERATED_MID_LOD"
