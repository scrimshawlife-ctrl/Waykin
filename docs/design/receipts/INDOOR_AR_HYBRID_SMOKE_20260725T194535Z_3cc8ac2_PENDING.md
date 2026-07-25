# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-07-25T19:45:35Z
git_sha: 3cc8ac21a3bbe286486c551b04630b5531ec928c
git_short: 3cc8ac2
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE
outdoor_qa: NOT_COMPUTABLE
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
note: Archive tip 0.9.0 (2). Prefer this receipt. When filled set evidence_class OBSERVED (indoor); never invent outdoor PASS.
```

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make validate (local tip) | PASS (2026-07-25T19:45:35Z) |
| make check-lira-usdz | PASS (via validate) |
| package tests | PASS (130) |
| xcodebuild WaykinApp | PASS |

## Device results I1–I12

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch → Home | | Hallmark home |
| I2 | Demo Begin Walk + operator strip | | |
| I3 | AR full-screen cover + Pause/End | | |
| I4 | Plant Lira on table/floor | | |
| I5 | Motion dcc/hybrid/puppet | | label: |
| I6 | State motion change | | Single state chip |
| I7 | Lens cover / tracking loss | | |
| I8 | Leave AR clean | | |
| I9 | Re-open single entity | | |
| I10 | Reduce Motion | | |
| I11 | Skin swap if available | | |
| I12 | Receipt share arPresentation | | |

## Failures → new bounded issues

-

## Explicit non-claims

- Outdoor #41 COH / glare
- GPS integrity
- Battery / thermal (unless filled)

## Operator

1. Install Debug build of `3cc8ac2` (`3cc8ac21a3bbe286486c551b04630b5531ec928c`) on a physical iPhone.
2. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md`.
3. Fill I1–I12; set `evidence_class: OBSERVED` if completed on named device (note indoor).
4. PR the filled receipt (do not claim outdoor PASS).
