# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN_INDOOR_AR_HYBRID_SMOKE_RECEIPT
date_utc: 2026-07-23T05:26:35Z
main_tip_sha: 68ba09d8885e0bec54d3ab52d52bca9a24575021
main_tip_short: 68ba09d
# Board/receipt scaffold branch (PR #223); install device from main tip or later
scaffold_sha: 696997c647f380831a93fa26bdc44564885306d7
status: PENDING_HUMAN_DEVICE
pre_device_usdz: PASS
pre_device_validate: PASS
sim_binding: puppet_multiPart_clips0_dcc0
```

## Pre-device (laptop) — filled

| Gate | Result |
|------|--------|
| product tip to install | `68ba09d` (or newer main) |
| check-lira-usdz | PASS @ main tip |
| validate | PASS @ main tip |
| sim AR binding | OBSERVED `clipSource=puppet` `availableAnimations=0` (test on PR #223 / #224 tips; same package bytes) |

## Device rows — PENDING

See [INDOOR_AR_HYBRID_SMOKE.md](../INDOOR_AR_HYBRID_SMOKE.md). Do not mark outdoor #41 from this packet.

| Item | Result |
|------|--------|
| Device model / iOS | |
| Plant companion visible | |
| Motion line `skel_on` / clip | |
| States idle→follow→… distinguishable | |
| Continuity / re-plant single Lira | |
| Audio cues with silent switch | |
| Reduce Motion | |
| Receipt JSON schema ≥5 | |
