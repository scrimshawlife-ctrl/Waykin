# Real Application Screenshots

**Evidence class:** `SIMULATOR` or `DEVICE` only when a dated receipt is present.

## Authority

| Kind | Location | Use |
| ---- | -------- | --- |
| Capture script | `scripts/capture_sim_screenshots.sh` | Best-effort sim captures after Debug install |
| Capture folders | `docs/assets/screenshots/sim_<UTC>_<sha>/` | SIMULATOR-classed PNGs + RECEIPT.md |
| Concept art | `docs/assets/companion/**`, heroes | **Not** product UI evidence |

## How to capture (simulator)

```bash
# Home day + night (installs Debug build if needed)
./scripts/capture_sim_screenshots.sh "iPhone 17"

# Full matrix: Home / Active Session / Summary × day + night (UI test driven)
WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh "iPhone 17"
```

Each run writes `docs/assets/screenshots/sim_<UTC>_<sha>/` with PNGs + `RECEIPT.md` (`evidence_class: SIMULATOR`).

AR full-screen chrome is still **manual** in-sim if needed; do not treat as outdoor AR evidence.

## Outdoor

Physical-device screenshots belong under `docs/design/receipts/` with Issue #41 outdoor protocol — not here as outdoor proof.

## Related

- Residual candidate audit: [`docs/design/UI_CANDIDATE_RESIDUAL_AUDIT.md`](../../design/UI_CANDIDATE_RESIDUAL_AUDIT.md)
- Issue #194
