# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-07-20T16:13:31Z
git_sha: 2246b20c7d07578d6919acc2175333e9e02d5063
git_short: 2246b20
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE   # change to OBSERVED_INDOOR_DEVICE when walk done
outdoor_qa: NOT_COMPUTABLE
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
```

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make check-lira-usdz | PASS |
| make validate | PASS |

## Device results I1–I12

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch → Home | | |
| I2 | Demo Begin Walk + operator strip | | |
| I3 | AR full-screen cover + Pause/End | | |
| I4 | Plant Lira on table/floor | | |
| I5 | Motion dcc/hybrid/puppet | | label: |
| I6 | State motion change | | |
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

1. Install Debug build of `2246b20` on a physical iPhone.
2. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md`.
3. Fill I1–I12; set `evidence_class: OBSERVED_INDOOR_DEVICE` if completed.
4. PR the filled receipt (do not claim outdoor PASS).
