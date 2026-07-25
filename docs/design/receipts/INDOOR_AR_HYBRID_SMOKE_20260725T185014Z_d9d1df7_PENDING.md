# Indoor AR hybrid smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-07-25T18:50:14Z
git_sha: d9d1df7ebb2dd458223f1c5ee2ab1787456c5635
git_short: d9d1df7
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE
outdoor_qa: NOT_COMPUTABLE
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
note: Post Hallmark #236 merge tip. Prefer this receipt over older PENDING scaffolds. When filled, set evidence_class to OBSERVED (indoor device); never invent outdoor PASS.
```

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| make check-lira-usdz | PASS (CI on #236) |
| make validate / native-ios | PASS (CI on #236) |

## Device results I1–I12

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch → Home | | Hallmark home hierarchy |
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

1. Install Debug build of `d9d1df7` (`d9d1df7ebb2dd458223f1c5ee2ab1787456c5635`) on a physical iPhone.
2. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md`.
3. Fill I1–I12; set `evidence_class: OBSERVED` if completed on a named physical device (note indoor in device_model / notes).
4. PR the filled receipt (do not claim outdoor PASS).
