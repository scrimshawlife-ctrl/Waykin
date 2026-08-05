# Indoor Ember Fox AR smoke receipt (PENDING human device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_utc: 2026-08-05T16:42:00Z
git_sha:           # fill after git pull + git rev-parse HEAD on post-#255 main
git_short:         # fill
phase_0_pr: 255
phase_0_issue: 254
code_lineage_note: Install exact main HEAD after #255 merges. Do not reuse historical 7df3a16 PENDING as the install target.
device_model:      # fill on device
ios:               # fill
operator:          # fill
evidence_class: NOT_COMPUTABLE
outdoor_qa: NOT_COMPUTABLE
companion_runtime: MESHY_EMBER_FOX_WALK_V1
visual_reference: docs/design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md
protocol: docs/design/INDOOR_AR_HYBRID_SMOKE.md
status: PENDING_HUMAN_DEVICE
note: After Phase 0 (#255) merges, git checkout main && git pull --ff-only, record full SHA, install that build, then fill this receipt. Set evidence_class OBSERVED only from direct device sight (note indoor). Never invent outdoor PASS.
```

## Automated pre-device gates (laptop)

Run on the tip you will install:

```bash
git checkout main && git pull --ff-only
SHA=$(git rev-parse HEAD)
echo "tip=$SHA"
make check-lira-usdz
make validate
# optional: bash scripts/indoor_ar_smoke_prep.sh
```

| Check | Result |
| ----- | ------ |
| Exact tip SHA recorded | |
| `make check-lira-usdz` | |
| `make validate` | |
| Phase 0 identity present on tip | yes (after #255) |

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

## Operator order

1. Merge Phase 0 PR #255.
2. `git checkout main && git pull --ff-only` → record **full** `git rev-parse HEAD`.
3. Install that exact Debug build on physical iPhone.
4. Follow `docs/design/INDOOR_AR_HYBRID_SMOKE.md` v2 (Ember Fox).
5. Fill I1–I14; set `evidence_class: OBSERVED` only if completed on named device (note indoor).
6. PR the filled receipt; do not claim outdoor PASS.
