#!/usr/bin/env bash
# Rebuild Lira_AR_Base.usdz from USDA source and install into the app package path.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/docs/assets/companion/ar/src/Lira_AR_Base.usda"
# Packaged at Resources root so xcodegen reliably copies into the app bundle.
APP_OUT="$ROOT/App/Resources/Lira_AR_Base.usdz"
NESTED="$ROOT/App/Resources/Companion/Lira/Lira_AR_Base.usdz"
DOC_OUT="$ROOT/docs/assets/companion/ar/Lira_AR_Base.usdz"

if [[ ! -f "$SRC" ]]; then
  echo "missing source: $SRC" >&2
  exit 1
fi
if ! command -v usdzip >/dev/null; then
  echo "usdzip not found (Xcode command line tools)" >&2
  exit 1
fi

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
