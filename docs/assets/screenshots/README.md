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
# 1. Build + install (or run from Xcode on the named sim)
xcodebuild -scheme Waykin \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/waykin-dd build

# 2. Capture
./scripts/capture_sim_screenshots.sh "iPhone 17"
```

Manually add day/night variants and session/AR frames when exercising Demo Walk; label each RECEIPT with `evidence_class: SIMULATOR`.

## Outdoor

Physical-device screenshots belong under `docs/design/receipts/` with Issue #41 outdoor protocol — not here as outdoor proof.

## Status

Home auto-capture may exist after running the script. Empty root (aside from this README) means no automated set has been committed yet.
