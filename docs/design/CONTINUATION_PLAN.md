# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 3.4
date: 2026-07-23
status: DEVICE_FIXES_THEN_TF_INTERNAL
goal: land_device_ar_audio_fixes_then_internal_testflight
outdoor_qa: PARKED_SEE_DEFERRED_RECOMMENDATIONS
ar_status: FROZEN_MAINTENANCE_ONLY_UNLESS_41_OR_DEFECT
ui_package: Waykin-Design/11_Approved-Exports/CANDIDATE_v0.2/
main_tip_at_refresh: 8beec34
open_product_pr: 217
open_dist_pr: 216
authority_note: ACTIVE_WORK.md is the live coordination snapshot
```

**2026-07-23 board note:** UI CANDIDATE_v0.2 and Meshy AR packaging largely landed on main. Live code lane is **PR #217** (device AR/audio + skinned walk). Distribution privacy/encryption **shipped** (#215). Internal TF checklist is **PR #216** (approved). Outdoor #41 remains PARTIAL / daylight.

## Completed waves

| Wave | Status |
| ---- | ------ |
| Design / indoor presentation / AR mid-LOD / USDZ | **Done** |
| **AR-F** freeze + **P/H MVP** | **Done** (#98) |
| **Path/Health v1.1** | **Done** (#99) |
| **Experience loop cohesion** | **Done** (#100) |
| **Event weight light tune** | **Done** (v3.1) |
| Continuity + audio coupling + path soft cues | **Done** (#125/#130/#139–#143) |
| Menu UX + non-outdoor UI polish | **Done** (#126/#147–#150) |
| Engineering doc sync vs code | **This wave** |

## Completed wave — UI CANDIDATE_v0.2 Phase 4

Pointer: [UI_CANDIDATE_V02_POINTER.md](UI_CANDIDATE_V02_POINTER.md)

**No longer active** (2026-07-23 board refresh). UI candidate integration largely landed on main; live lanes are device AR/audio (#217), artist AR package (#222), internal TF (#218 checklist / #219 encryption). Residual UI polish only via dedicated issues — do not treat the list below as open implementation queue.

Historical checklist (done or superseded on main):

1. Tokens / day-night vs `App/Theme/WKTokens.swift` (HO-001).
2. Home + Begin + settings chrome vs production board.
3. Active session + pause + safety pause density.
4. Icons from candidate SVG set.
5. Mode cards / bond viz / summary alignment.

## Parked wave — Outdoor re-walk (#41)

See [DEFERRED_RECOMMENDATIONS.md](DEFERRED_RECOMMENDATIONS.md). Resume when human requests outdoor.
3. Record OBSERVED continuity, produced/path audio, menu/AR full-screen feel.
4. Open new defect issues only if needed; do not invent PASS from sim.

## Wave v3.1 — Light event weight tuning (complete)

Adjusted `WorldEventGeneratorConfiguration.defaultRules` only. No new kinds, no narrative engine, no Demo arc rewrite.

| ID | Work | Acceptance |
| -- | ---- | ---------- |
| **W1** | Companion-first weights/cooldowns | drawsNear/observes favored over quiet + pursuit entry |
| **W2** | Rarer pursuit begins | Higher pressure/energy entry, lower weight, longer cooldown |
| **W3** | Easier fade / earlier bond-familiar | Mild threshold relief; fade slightly more available |
| **W4** | Frequency bound preserved | ≤8 events / 30×10s fixture; seed determinism unchanged |
| **W5** | Demo Mode unaffected | Scheduled calm-day arc tests still pass |

### Tuning intent

| Prefer | De-emphasize |
| ------ | ------------ |
| Lira near / observe / ahead | quietInterval dominance |
| Bond + familiar place | Early sharp pursuit |
| pursuitFades after pressure | pursuitBegins spam |

Outdoor receipts may revise numbers later. Do not drop `minimumTickSpacing` below ~30 without device evidence.

### Out of scope

| Track | Work |
| ----- | ---- |
| Outdoor | Device walk QA / outdoor receipt OBSERVED |
| AR | Issue #41; sculpted USDZ / AnimationLibrary |
| Path v2 | Corridor geometry / map product |
| Health v2 | Workouts, background delivery |
| Audio | New cue kinds / production sound redesign |

## Related

- [PATHFINDING.md](PATHFINDING.md)
- [HEALTHKIT.md](HEALTHKIT.md)
- [AR_MVP_FREEZE.md](AR_MVP_FREEZE.md)
- `Sources/WaykinCore/Engines/WorldEventGenerator.swift`