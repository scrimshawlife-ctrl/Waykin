# Indoor Ember Fox AR smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-07-29T19:15:00Z
git_sha: 7df3a169ede507ce54469330318f66c4603f8c3d
git_short: 7df3a16
code_lineage_note: app binary from main 7df3a16 (Ember Fox #246 + pressure #248); after #249 merge install current main HEAD not this parent short alone
freeze_docs_pr: 249
device_model:         # fill on device
ios:                 # fill
operator:            # fill
evidence_class: NOT_COMPUTABLE
outdoor_qa: NOT_COMPUTABLE
companion_runtime: MESHY_EMBER_FOX_WALK_V1
visual_reference: docs/design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
note: After #249 merges, git pull and install exact HEAD. Scaffold name pins code lineage for prep only. When filled set evidence_class OBSERVED (note indoor); never use OBSERVED_INDOOR_DEVICE; never invent outdoor PASS.
```

## Automated pre-device gates

| Check | Result |
| ----- | ------ |
| Laptop baseline receipt | `POST_EMBER_FOX_BASELINE_20260729T190249Z_1378307.md` **PASS** |
| `make validate` | PASS (local freeze branch on lineage `7df3a16`) |
| `make check-lira-usdz` | PASS (`MESHY_EMBER_FOX_WALK_V1`, triple match) |
| Package tests | PASS (133) |
| `make validate-simulator` | PASS (13 UI tests, 0 failures, 1 skipped) |
| `usdchecker --arkit` | PASS |

## Visual gold standard

Compare to Prabu device still:

- Receipt: [DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md](DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md)
- PNG: [evidence/IMG_2534_prabu_ember_fox_device.png](evidence/IMG_2534_prabu_ember_fox_device.png)
- Expect: stylized fox mesh, **not** procedural spheres
- Operator strip should show `animated_usdz` (or equivalent) and animation playing when follow is active

## Device results I1–I14

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| I1 | Cold launch / clean install | | |
| I2 | Session start; persistence healthy | | |
| I3 | AR full-screen + Pause/End | | |
| I4 | Procedural fallback only during load | | timing: |
| I5 | Ember Fox replaces fallback | | match Prabu look? |
| I6 | Single companion after replace | | anchor count: |
| I7 | Height / ground contact | | |
| I8 | Skeleton animation | | strip labels: |
| I9 | Stationary pause / idle | | |
| I10 | Closing distance / follow anim | | |
| I11 | Plant / replant / interrupt / background | | |
| I12 | End session + arPresentation receipt | | schema: |
| I13 | Audio under intended policy | | |
| I14 | No severe hitch / thermal / re-decode | | |

Mark each: **PASS** / **PARTIAL** / **FAIL** / **NOT_COMPUTABLE**.

## Extra capture fields

| Field | Value |
| ----- | ----- |
| Installed commit SHA (full) | |
| Time to fallback | |
| Time to authored replace | |
| Anchor count before/after | |
| Screenshot / recording ref | |
| Overall | |

## Failures → new bounded issues

-

## Explicit non-claims

- Outdoor #41 COH / glare
- GPS integrity
- Battery / thermal PASS (unless OBSERVED rows filled)
- Closing #247 without this tip’s SHA recorded

## Operator

1. Prefer Debug install of **freeze tip after #249 merges**, or code lineage `7df3a16` if docs-only tip differs.
2. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md` v2 (Ember Fox).
3. Fill I1–I14; set `evidence_class: OBSERVED` if completed on named device (note indoor).
4. PR the filled receipt; do not claim outdoor PASS.
