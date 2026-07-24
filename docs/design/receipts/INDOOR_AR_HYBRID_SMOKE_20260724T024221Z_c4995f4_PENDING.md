# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN_INDOOR_AR_HYBRID_SMOKE_RECEIPT
date_utc: 2026-07-24T02:42:21Z
main_tip_sha: c4995f4819ab18a2a306571170e2512278c8c452
main_tip_short: c4995f4
status: PENDING_HUMAN_DEVICE
pre_device_usdz: PASS
pre_device_integrity_animated_curves: PASS
sim_binding: OBSERVED_mapped6_clipSource_dcc
```

## Pre-device (laptop) — filled @ tip `c4995f4`

| Gate | Result |
|------|--------|
| tip | `c4995f4` (#226 on main) |
| `check_lira_usdz_integrity` | **PASS** (triple ~5.1 MB; default layer base; 6 sidecars; **animated joint curves**) |
| Sim composition test | **OBSERVED** `sidecars_found=6;mapped=6;keys=alert,celebrate,follow,idle,investigate,spawn` `clipSource=dcc` `dcc:multiPart:6_clips` |
| Outdoor #41 | **NOT_COMPUTABLE** from this packet |

Command used:
```bash
xcodebuild -scheme Waykin -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WaykinTests/LiraHeroDCCUSDZTests/testDCCClipSidecarCompositionBindsStateClips test
```

## Device rows — PENDING

Install **exact** tip `c4995f4` (or newer main after board PR). See [INDOOR_AR_HYBRID_SMOKE.md](../INDOOR_AR_HYBRID_SMOKE.md).

| Item | Result |
|------|--------|
| Device model / iOS | |
| Plant companion visible | |
| Motion line `skel_on` / `dcc` / clip id | |
| States idle→follow→… distinguishable | |
| Continuity / re-plant single Lira | |
| Audio cues with silent switch | |
| Reduce Motion | |
| Receipt JSON schema ≥5 | |

Do **not** mark outdoor #41 from this packet.
