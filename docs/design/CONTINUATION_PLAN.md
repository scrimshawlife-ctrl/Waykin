# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 5.0
date: 2026-07-29
status: FREEZE_BASELINE_THEN_BUILD_ON_TOP
goal: freeze_docs_and_laptop_baseline_then_device_only_then_optional_redesign
outdoor_qa: PARKED_SEE_DEFERRED_RECOMMENDATIONS
ar_status: MAINTENANCE_PLUS_APPROVED_MESH_RUNTIME_ONLY
ui_package: Waykin-Design/11_Approved-Exports/CANDIDATE_v0.2/
main_tip_at_refresh: 7df3a16
main_tip_full: 7df3a169ede507ce54469330318f66c4603f8c3d
companion_runtime: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
gameplay_pressure_pr: 248
marketing_version: "0.9.0"
build_number: "2"
marketing_note: revalidate_before_retaining_as_rc
open_product_pr: "245_supporting_docs_only_do_not_merge_stale"
open_issues: [41, 247]
authority_note: ACTIVE_WORK.md is the live coordination snapshot
```

## Executive summary

Engineering for **Ember Fox** packaged companion mesh/runtime (**PR #246**), real-walk event pressure on real distances (**PR #248**), full-screen AR, audio, plant/follow, Hallmark presentation polish, and internal TF version metadata **0.9.0 (2)** is **on main**.

Remaining value is **documentation accuracy**, **fresh automated baseline**, and **device evidence** — not mesh re-import, stale-branch recovery, or broad UI reskin churn.

| Layer | Status on tip `7df3a16` |
| ----- | ------------------------ |
| Packaged companion | **Ember Fox** USDZ (`MESHY_EMBER_FOX_WALK_V1`, ~19–20 MB triple-mirrored) |
| Mesh / loader runtime | Async template load, procedural fallback, live authored replacement, explicit anchor detach (#246) |
| Embedded animation | Single authored walk cycle on skeleton; per-state DCC sidecars present but not bound while authored clip is active |
| Retired runtime package | Artist-blend / DCC mid-LOD (`ARTIST_BLEND_HERO_DCC_MID_LOD`) — **superseded**; historical only |
| Superseded mesh PRs | #242 / #243 closed — **do not merge** |
| Full-screen AR, audio, plant/follow | Shipped (#217+) |
| Hallmark UI polish | Shipped (#236) |
| Real-walk pressure curve | Shipped (#248) — gameplay tuning, **not** AR implementation |
| Marketing / build (in tree) | **0.9.0 (2)** — revalidate; #247 holds TF archive |
| Phase A laptop validate (post-mesh) | **Required** on current tip (pre-mesh receipts are historical) |
| Indoor device smoke | **Human — next** (Ember Fox protocol) |
| Outdoor #41 COH | **Human — daylight** on post-mesh tip |
| AR redesign docs | Supporting only; recover via fresh branch from freeze tip (replaces stale #245 history) |

## Completed eng waves (recent)

| Wave | Evidence |
| ---- | -------- |
| Ember Fox package + placement + animation runtime | #246 · `b17864e` |
| Real-walk pressure on real distances | #248 · `7df3a16` |
| Artist mid-LOD package (superseded runtime) | #222 — **historical** |
| Device AR/audio/follow | #217 |
| DCC sidecar composition + bake (historical path) | #224 / #226 |
| Audio cue family + lifecycle + AR audio map | #230–#234 |
| Session double-End guard | #235 |
| Hallmark presentation polish | #236 · `d9d1df7` |
| TF 0.9.0 (2) + board (pre-mesh) | #237 · `2d969a0` |
| Pre-mesh cut SHA + Phase A + board sync | #238–#240 · tip `d7954ac` — **historical tip** |

## Safe sequence (campaign) — freeze first, then build

```text
FREEZE LANE (do not skip)
1. Re-baseline current documentation          ← done on docs/current-main-rebaseline
2. Validate post–Ember Fox lineage → receipt  ← POST_EMBER_FOX_BASELINE_*
3. Merge freeze docs to main (write-access gate)
4. Stop feature/redesign work on other branches that predate the freeze tip

DEVICE LANE (on frozen lineage only)
5. Indoor Ember Fox smoke (device OBSERVED)
6. Resolve or re-scope #247 (authored mesh on device)
7. Outdoor evidence walk (#41)
8. Internal TestFlight only after #247 + validate on archive SHA

BUILD-ON-TOP LANE (only after freeze + device honesty)
9. Recover PR #245 docs onto freeze tip (SUPPORTING; never merge stale branch)
10. Phase 0 binding product-law reconciliation
11. AR session shell in bounded PRs
12. State animations incrementally (preserve base mesh)
```

**Rule:** Do not start steps 9–12 until freeze docs are on `main` and device lanes are at least armed with tip-bound receipts. Prefer freezing release engineering over parallel redesign churn.

## Phase A — Pre-device gates (laptop)

```bash
git checkout main && git pull --ff-only
SHA=$(git rev-parse HEAD) && echo tip=$SHA
make check-lira-usdz
make test
make validate
make validate-simulator   # when presentation changed
git diff --check
```

| Gate | Expected on tip ≥ `b17864e` |
| ---- | --------------------------- |
| Integrity | PASS + triple hash match + `MESHY_EMBER_FOX_WALK_V1` |
| Validate | OVERALL PASS (package tests + WaykinApp) |
| Version | Info.plist **0.9.0** / **2** (revalidate before RC claim) |

Pre-mesh Phase A receipt (historical): `docs/design/receipts/PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md`
**Re-run Phase A** on current tip before archive/device install claims.

## Phase B — Indoor Ember Fox smoke (human, ~15 min)

Protocol: [INDOOR_AR_HYBRID_SMOKE.md](INDOOR_AR_HYBRID_SMOKE.md)

1. Install **exact** tip SHA (Debug + operator strip preferred).
2. Confirm procedural fallback may appear only during bounded load.
3. Confirm **Ember Fox** replaces fallback automatically; **one** companion anchor remains.
4. Confirm embedded walk drives the **skeleton** (not wrong root target).
5. Plant / replant / interruption / background recovery; end session diagnostics.
6. Share field-test JSON (schema ≥ 5); no coordinates.
7. Fill a tip-bound PENDING receipt; `evidence_class: OBSERVED` (note indoor).

Historical scaffold (artist-blend era, not current install target):
`docs/design/receipts/INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md`
**Does not close #41.**

## Phase C — Internal TestFlight (human; gated)

Checklist: [TESTFLIGHT_RC_CHECKLIST.md](TESTFLIGHT_RC_CHECKLIST.md)

1. Issue **#247** must be resolved or explicitly waived with device evidence of authored mesh on screen.
2. Archive only an exact validated SHA after post-mesh Phase A PASS.
3. Revalidate marketing/build; bump build if **0.9.0 (2)** was already uploaded.
4. Privacy/encryption already on main (#215/#219).
5. Internal group only; #41 **not** required for internal TF, but mesh replacement **is**.

## Phase D — Outdoor #41 (human, daylight)

Protocol: [OUTDOOR_SESSION_PACKET.md](OUTDOOR_SESSION_PACKET.md) + issue #41.

1. Same tip as indoor (or re-run Phase A after any merge).
2. Daylight walk; COH PASS/PARTIAL/FAIL with OBSERVED only.
3. Report **mesh/runtime** evidence separately from **world-event** evidence (pressure curve from #248 changes variety reachability, not density intent).
4. Silhouette, plant/replant, authored walk in sun, continuity, audio, thermal.

Historical outdoor scaffold: `docs/design/receipts/OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md`
Create a new tip-bound scaffold when walking `7df3a16` or later.

## Explicit non-goals

- Re-import or replace the Ember Fox mesh without an explicit asset issue
- Merge closed PRs **#242** or **#243**
- Force-merge stale branches onto `main`
- Outdoor quality claims from sim or indoor smoke alone
- Broad AR UX redesign before Phase 0 binding-doc reconciliation
- Treating supporting redesign docs (#245) as binding product law
- MVP expansion without promotion
- AI Directors / Watch / CloudKit without promotion

## Defect triage

| Symptom | First look |
| ------- | ---------- |
| Procedural placeholder never replaced | Template load / versioned replace path (#246); issue #247 |
| Duplicate companion anchors | Scene-owned anchor detach; continuity |
| Animation on wrong target | Skeleton-target selection vs root scene animation |
| Scale / ground drift after state change | Base-transform invariant; do not overwrite imported base |
| Plant fail / tracking loss pile-up | Continuity / placement |
| Silent audio | `.playback` / silent switch / interruption |
| Sparse events after long walk | #248 pressure is distance-scaled; do not retune cadence from sparse alone |

## Success criteria

| Milestone | Done when |
| --------- | --------- |
| Docs match current main | No live tip pin to `d7954ac`; Ember Fox is canonical runtime |
| Eng mesh + pressure | On main through `7df3a16` |
| Indoor smoke | Filled receipt with device OBSERVED rows (Ember Fox) |
| Outdoor #41 | Dated outdoor receipt on tested SHA; no invented PASS |
| Internal TF | Build on internal testing group from validated SHA after #247 |
| Redesign docs | Recovered SUPPORTING docs on current main (not #245 merge) |

---

**Live board:** [ACTIVE_WORK.md](../collaboration/ACTIVE_WORK.md)
**Parked backlog:** [DEFERRED_RECOMMENDATIONS.md](DEFERRED_RECOMMENDATIONS.md)
