# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 4.0
date: 2026-07-24
status: DEVICE_EVIDENCE_LANE
goal: indoor_smoke_then_internal_tf_then_outdoor_41
outdoor_qa: PARKED_SEE_DEFERRED_RECOMMENDATIONS
ar_status: MAINTENANCE_ONLY_UNLESS_41_OR_DEFECT
ui_package: Waykin-Design/11_Approved-Exports/CANDIDATE_v0.2/
main_tip_at_refresh: f061b4e
open_product_pr: none
open_issues: [41]
authority_note: ACTIVE_WORK.md is the live coordination snapshot
```

## Executive summary

Engineering stack for Lira AR mid-LOD + device AR/audio + DCC binding is **on main**. Remaining value is **device evidence** and **distribution**, not more mesh pipeline churn.

| Layer | Status on tip |
| ----- | ------------- |
| Artist mesh | Shipped (#222) `ARTIST_BLEND_HERO_DCC_MID_LOD` |
| Full-screen, audio, plant/follow | Shipped (#217) |
| DCC composition (sidecars in bundle) | Shipped (#224) |
| Joint curve bake → RK `availableAnimations` | Shipped (#226) sim **`mapped=6` / `clipSource=dcc`** |
| Board / sim receipts | Shipped (#223, #227) |
| Indoor device smoke | **Human — next** |
| Internal TestFlight | **Human — parallel OK** |
| Outdoor #41 COH | **Human — daylight** |

## Completed eng waves (recent)

| Wave | Evidence |
| ---- | -------- |
| Artist mid-LOD package | #222 · `ee57a7d` |
| Device AR/audio/follow | #217 · `68ba09d` |
| Board + sim preflight | #223 · `b66e235` |
| DCC sidecar composition | #224 · `7931120` |
| DCC bake / timeSamples | #226 · `c4995f4` · closes #225 |
| Board post-#226 | #227 · `f061b4e` |

## Phase A — Pre-device gates (laptop)

```bash
git checkout main && git pull --ff-only
SHA=$(git rev-parse HEAD) && echo tip=$SHA
make check-lira-usdz
make validate
xcodebuild -scheme Waykin \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WaykinTests/LiraHeroDCCUSDZTests/testDCCClipSidecarCompositionBindsStateClips \
  test
```

| Gate | Expected on tip ≥ `c4995f4` / board `f061b4e` |
| ---- | --------------------------- |
| Integrity | PASS + animated joint curves on 6 sidecars |
| Validate | OVERALL PASS |
| Sim composition | `mapped=6` `clipSource=dcc` (OBSERVED sim) |

Phase A receipt example: `docs/design/receipts/PHASE_A_PREDEVICE_*_f061b4e.md`.

## Phase B — Indoor AR hybrid smoke (human, ~15 min)

Protocol: [INDOOR_AR_HYBRID_SMOKE.md](INDOOR_AR_HYBRID_SMOKE.md)

1. Install **exact** tip SHA (Debug + operator strip preferred).
2. Run I1–I12; mark PASS / FAIL / NOT_COMPUTABLE only.
3. Expect Motion line: `dcc:`… with real clip ids after plant (**device** OBSERVED).
4. Share field-test JSON (schema ≥ 5); no coordinates.
5. Fill PENDING receipt; open repair issues only for FAIL items.

**Does not close #41.**

## Phase C — Internal TestFlight (human, parallel to B)

Checklist: [TESTFLIGHT_RC_CHECKLIST.md](TESTFLIGHT_RC_CHECKLIST.md)

1. Bump build number; archive tip.
2. Privacy/encryption already on main (#215/#219).
3. Internal group only; #41 **not** required for internal TF.

## Phase D — Outdoor #41 (human, daylight)

Protocol: [OUTDOOR_SESSION_PACKET.md](OUTDOOR_SESSION_PACKET.md) + issue #41.

1. Same tip as indoor (or re-run Phase A after any merge).
2. Daylight walk; COH PASS/PARTIAL/FAIL with OBSERVED only.
3. Silhouette, plant/replant, DCC motion in sun, continuity, audio, thermal.

## Explicit non-goals

- Re-sculpt Lira without a defect
- Meshy walk as default runtime USDZ
- Hermes open-ended Blender thrash without one hypothesis
- Outdoor quality claims from sim or indoor smoke alone
- MVP expansion without promotion

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
| Eng DCC stack | On main (done `c4995f4` / board `f061b4e`) |
| Indoor smoke | Filled receipt with device OBSERVED rows |
| Internal TF | Build on internal group |
| #41 | Dated outdoor receipt; no invented PASS |

---

**Live board:** [ACTIVE_WORK.md](../collaboration/ACTIVE_WORK.md)  
**Parked backlog:** [DEFERRED_RECOMMENDATIONS.md](DEFERRED_RECOMMENDATIONS.md)
