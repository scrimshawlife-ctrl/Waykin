# Waykin Continuation Plan

> **AR redesign map (supporting):** see [AR_PRODUCT_REDESIGN_MAP.md](AR_PRODUCT_REDESIGN_MAP.md) and [../plans/AR_APP_REDESIGN_PLAN.md](../plans/AR_APP_REDESIGN_PLAN.md) for AR-designed product direction and phases. This continuation plan remains the device-evidence lane.


```yaml
document_id: WAYKIN-CONTINUATION-001
version: 4.1
date: 2026-07-25
status: DEVICE_EVIDENCE_LANE
goal: indoor_smoke_then_internal_tf_then_outdoor_41
outdoor_qa: PARKED_SEE_DEFERRED_RECOMMENDATIONS
ar_status: MAINTENANCE_ONLY_UNLESS_41_OR_DEFECT
ui_package: Waykin-Design/11_Approved-Exports/CANDIDATE_v0.2/
main_tip_at_refresh: d7954ac
marketing_version: "0.9.0"
build_number: "2"
open_product_pr: none
open_issues: [41]
authority_note: ACTIVE_WORK.md is the live coordination snapshot
```

## Executive summary

Engineering for Lira AR mid-LOD, device AR/audio, DCC binding, Hallmark presentation polish, and internal TF version **0.9.0 (2)** is **on main**. Remaining value is **device evidence** and **distribution**, not more mesh pipeline or UI reskin churn.

| Layer | Status on tip |
| ----- | ------------- |
| Artist mesh + DCC clips | Shipped (`ARTIST_BLEND_HERO_DCC_MID_LOD`, sim `clipSource=dcc`) |
| Full-screen AR, audio, plant/follow | Shipped (#217+) |
| Hallmark UI polish | Shipped (#236) |
| Marketing / build | **0.9.0 (2)** (#237) |
| Phase A laptop validate | **PASS** on `3cc8ac2` (ancestor of tip; app binary identity holds) |
| Indoor device smoke | **Human — next** (PENDING receipt) |
| Internal TestFlight upload | **Human — parallel OK** |
| Outdoor #41 COH | **Human — daylight** |

## Completed eng waves (recent)

| Wave | Evidence |
| ---- | -------- |
| Artist mid-LOD package | #222 |
| Device AR/audio/follow | #217 |
| DCC sidecar composition + bake | #224 / #226 |
| Audio cue family + lifecycle + AR audio map | #230–#234 |
| Session double-End guard | #235 |
| Hallmark presentation polish | #236 · `d9d1df7` |
| TF 0.9.0 (2) + board | #237 · `2d969a0` |
| Cut SHA pin + Phase A handoff + board sync | #238–#240 · tip `d7954ac` |

## Phase A — Pre-device gates (laptop)

```bash
git checkout main && git pull --ff-only
SHA=$(git rev-parse HEAD) && echo tip=$SHA
make check-lira-usdz
make validate
```

| Gate | Expected on tip ≥ `2d969a0` |
| ---- | --------------------------- |
| Integrity | PASS + 6 DCC sidecars + animated joints |
| Validate | OVERALL PASS (package tests + WaykinApp) |
| Version | Info.plist **0.9.0** / **2** |

Latest Phase A receipt: `docs/design/receipts/PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md`  
Re-run Phase A if main moves with **code** changes before archive/device install.

## Phase B — Indoor AR hybrid smoke (human, ~15 min)

Protocol: [INDOOR_AR_HYBRID_SMOKE.md](INDOOR_AR_HYBRID_SMOKE.md)

1. Install **exact** tip SHA (Debug + operator strip preferred).
2. Run I1–I12; mark PASS / FAIL / NOT_COMPUTABLE only.
3. Expect Motion line with `dcc` / clip ids after plant (**device** OBSERVED).
4. Share field-test JSON (schema ≥ 5); no coordinates.
5. Fill PENDING receipt; use `evidence_class: OBSERVED` (note indoor); open repair issues only for FAIL.

**Current scaffold:** `docs/design/receipts/INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md`  
**Does not close #41.**

## Phase C — Internal TestFlight (human, parallel to B)

Checklist: [TESTFLIGHT_RC_CHECKLIST.md](TESTFLIGHT_RC_CHECKLIST.md)

1. Archive tip with **0.9.0 (2)** (already set on main).
2. Privacy/encryption already on main (#215/#219).
3. Internal group only; #41 **not** required for internal TF.
4. Re-run `make validate` if tip moved past Phase A receipt with code changes.

## Phase D — Outdoor #41 (human, daylight)

Protocol: [OUTDOOR_SESSION_PACKET.md](OUTDOOR_SESSION_PACKET.md) + issue #41.

1. Same tip as indoor (or re-run Phase A after any merge).
2. Daylight walk; COH PASS/PARTIAL/FAIL with OBSERVED only.
3. Silhouette, plant/replant, DCC motion in sun, continuity, audio, thermal.

**Current scaffold:** `docs/design/receipts/OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md`

## Explicit non-goals

- Re-sculpt Lira without a defect
- Meshy walk as default runtime USDZ
- Outdoor quality claims from sim or indoor smoke alone
- MVP expansion without promotion
- AI Directors / Watch / CloudKit without promotion

## Defect triage

| Symptom | First look |
| ------- | ---------- |
| `mapped=0` / puppet only on tip ≥ `c4995f4` | Wrong build/tip; Clips missing; integrity FAIL |
| Plant fail / duplicate Lira | Continuity / placement |
| Silent audio | `.playback` / silent switch / interruption |
| DCC bound but ugly motion | Art bake quality — field note; not #41 close alone |

## Success criteria

| Milestone | Done when |
| --------- | --------- |
| Eng DCC + Hallmark + 0.9.0 (2) | On main (done through `d7954ac`) |
| Indoor smoke | Filled receipt with device OBSERVED rows |
| Internal TF | Build on internal testing group |
| #41 | Dated outdoor receipt; no invented PASS |

---

**Live board:** [ACTIVE_WORK.md](../collaboration/ACTIVE_WORK.md)  
**Parked backlog:** [DEFERRED_RECOMMENDATIONS.md](DEFERRED_RECOMMENDATIONS.md)
