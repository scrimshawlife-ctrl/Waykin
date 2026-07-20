# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 3.1
date: 2026-07-19
status: EVENT_WEIGHT_LIGHT_TUNE_COMPLETE
goal: companion_first_event_pacing_without_new_kinds
outdoor_qa: DEFERRED_NON_BLOCKING
ar_status: FROZEN_MAINTENANCE_ONLY
```

## Completed waves

| Wave | Status |
| ---- | ------ |
| Design / indoor presentation / AR mid-LOD / USDZ | **Done** |
| **AR-F** freeze + **P/H MVP** | **Done** (#98) |
| **Path/Health v1.1** | **Done** (#99) |
| **Experience loop cohesion** | **Done** (#100) |
| **Event weight light tune** | **This wave** |

## Wave v3.1 — Light event weight tuning

Adjust `WorldEventGeneratorConfiguration.defaultRules` only. No new kinds, no narrative engine, no Demo arc rewrite.

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