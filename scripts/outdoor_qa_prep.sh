#!/usr/bin/env bash
# Print build identity for outdoor QA receipts. Does not claim device evidence.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "=== Waykin Outdoor QA Prep ==="
echo "date_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "git_sha: $(git rev-parse HEAD)"
echo "git_short: $(git rev-parse --short HEAD)"
echo "branch: $(git rev-parse --abbrev-ref HEAD)"
echo "checklist: docs/design/OUTDOOR_QA_CHECKLIST.md"
echo "receipt_template: docs/design/OUTDOOR_QA_RECEIPT_TEMPLATE.md"
echo "sim_preflight: docs/design/SIMULATOR_PREFLIGHT.md"
echo "art_pipeline: docs/design/LIRA_PRODUCTION_ART_PIPELINE.md"
echo ""
echo "Next: run make validate, then SIMULATOR_PREFLIGHT, then device walk."
