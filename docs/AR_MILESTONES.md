# Waykin AR Milestones

| Milestone | Definition | Status |
|---|---|---|
| M0 | Repository and deterministic walking foundation | Complete |
| M1 | AR runtime foundation: camera, tracking, placement, replacement | Physically validated |
| M2 | Procedural companion rendering and direct state controls | Implementation merged; pending physical validation |
| M3 | Companion locomotion and orientation under camera motion | Planned |
| M4 | Runtime-driven companion state mapping | Implemented in AR-3; pending validation |
| M5 | Existing Companion Walk demo arc rendered in AR | Implemented in AR-3; pending validation |
| M6 | Discovery-object interaction | Planned |
| M7 | Threat/pursuit presentation | Placeholder lifecycle only |
| M8 | Complete indoor vertical slice | Planned |
| M9 | First outdoor alpha | Planned |

## Current phase: AR-3 runtime integration

AR-3 connects the existing `DemoSessionController`, `CompanionRuntime`, and `WorldEvent` sequence to procedural Lira through `ARWorldCommand`. It does not add new gameplay rules.

## AR-3 physical exit evidence

- Start Arc places procedural Lira.
- Next Event advances the existing seven-event deterministic sequence.
- UI event text matches the core event kind.
- Lira visibly transitions through investigate, alert, follow, and celebrate.
- discovery placeholder appears during observation.
- stable threat identity appears, intensifies, and is removed when pursuit fades.
- Run Arc reaches the final Bond moment without duplicate companion entities.
- Clear removes all registered entities.
- background/foreground behavior is recorded.
- no regression claim is made for the walking product without running its suite.

## Deferred M3 evidence

Real follow locomotion, camera-relative repositioning, target-facing orientation, and yaw smoothing remain deferred until AR-3 state/event integration is physically validated.
