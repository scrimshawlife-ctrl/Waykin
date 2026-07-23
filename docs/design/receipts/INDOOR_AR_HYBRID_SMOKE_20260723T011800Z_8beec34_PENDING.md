# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-07-23T01:18:00Z
git_sha: 8beec340311287b015e46b824d0ede2b94d7b0e4
git_short: 8beec34
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE   # change to OBSERVED_INDOOR_DEVICE when walk done
outdoor_qa: NOT_COMPUTABLE
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
note: Armed for main tip pre-#217. Re-scaffold after #217 merges if tip moves.
```

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make check-lira-usdz | PASS (main tip package; soft budget may WARN on later tips) |
| make validate | PASS on tip when last observed (re-run at cut) |

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
- #217 walk-cycle play quality (test on #217 tip after merge)

## Operator

1. Install Debug build of `8beec34` (or post-#217 tip) on a physical iPhone.
2. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md`.
3. Fill I1–I12; set `evidence_class: OBSERVED_INDOOR_DEVICE` if completed.
4. PR the filled receipt (do not claim outdoor PASS).
