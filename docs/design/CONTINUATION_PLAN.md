# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 3.2
date: 2026-07-20
status: NON_OUTDOOR_POLISH_COMPLETE_NEXT_41
goal: outdoor_device_evidence_on_main_tip
outdoor_qa: BLOCKED_ON_DAYLIGHT_REWALK
ar_status: FROZEN_MAINTENANCE_ONLY
authority_note: ACTIVE_WORK.md is the live coordination snapshot
```

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

## Next wave — Outdoor re-walk (#41)

1. Install tip SHA on physical iPhone in daylight.
2. Run outdoor session packet + Pass COH column.
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