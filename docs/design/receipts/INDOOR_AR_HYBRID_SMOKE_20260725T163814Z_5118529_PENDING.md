# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-07-25T16:38:14Z
git_sha: 5118529a35d7b8cf2644be5264b5dfb3045e4566
git_short: 5118529
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE   # change to OBSERVED_INDOOR_DEVICE when walk done
outdoor_qa: NOT_COMPUTABLE
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
note: Post Hallmark UI polish (#236). CI validate/swift-package/native-ios PASS on tip.
```

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make check-lira-usdz | PASS (CI / prior local) |
| make validate | PASS (CI native-ios + validate green on #236 tip) |

## Device results I1–I12

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch → Home | | Hallmark: left-biased home, no Form card chrome |
| I2 | Demo Begin Walk + operator strip | | |
| I3 | AR full-screen cover + Pause/End | | |
| I4 | Plant Lira on table/floor | | |
| I5 | Motion dcc/hybrid/puppet | | label: |
| I6 | State motion change | | Single state chip (no giant label) |
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

1. Install Debug build of `5118529` on a physical iPhone after #236 merges (or install this tip).
2. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md`.
3. Fill I1–I12; set `evidence_class: OBSERVED_INDOOR_DEVICE` if completed.
4. PR the filled receipt (do not claim outdoor PASS).
