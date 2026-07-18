# Waykin AR Milestones

| Milestone | Definition | Status |
|---|---|---|
| M0 | Repository and deterministic walking foundation | Complete |
| M1 | AR runtime foundation: camera, tracking, placement, replacement | Physically validated |
| M2 | Companion embodiment: procedural Lira, direct state controls, diagnostics, placeholders | Repaired build indoor, retained-memory, and frame-pacing validated; outdoor gate pending |
| M3 | Runtime integration: CompanionRuntime adapter, DemoSession bridge, seven-event arc, discovery and threat renderers | Repaired build indoor, retained-memory, and frame-pacing validated; outdoor gate pending |
| M4 | Companion intelligence: locomotion, orientation, eye contact, and contextual behaviors | Planned |
| M5 | One discovery interaction with completion, Bond, and memory | Planned |
| M6 | One threat presentation with escalation and escape completion | Planned |
| M7 | Complete Companion Walk AR loop | Planned |
| M8 | Outdoor alpha and field characterization | Planned |
| M9 | Experience-pack system | Future; outside the current MVP scope |

## Current phase: M3 repaired-build final evidence gates

AR-3 connects the existing `DemoSessionController`, `CompanionRuntime`, and `WorldEvent` sequence to procedural Lira through `ARWorldCommand`. It does not add new gameplay rules. The repaired executable passes the deterministic indoor gate, the operator-confirmed post-warm-up retained-memory gate, the predeclared 90-second frame-pacing gate, and final automated validation. An earlier executable passed the bounded outdoor observations; the repaired executable must repeat the bounded outdoor regression before integration or M4 work.

## AR-3 physical exit evidence

- Start Arc places procedural Lira.
- Next Event advances the existing seven-event deterministic sequence.
- UI event text matches the core event kind.
- Lira visibly transitions through investigate, alert, follow, and celebrate.
- the manual Discovery control places a discovery placeholder without inventing new event semantics.
- stable threat identity appears, intensifies in place, and is removed when pursuit fades.
- Run Arc reaches the final Bond moment without duplicate companion entities.
- Clear removes all registered entities.
- background/foreground behavior is recorded.
- no regression claim is made for the walking product without running its suite.

## M4 boundary

Real follow locomotion, camera-relative repositioning, target-facing orientation, eye contact, contextual idle behavior, and yaw smoothing remain M4 work and are not implied by AR-3 validation.
