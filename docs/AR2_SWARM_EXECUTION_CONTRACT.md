# Waykin AR-2 Swarm Execution Contract

## Milestone

- M0 Repository Foundation: complete
- M1 AR Runtime Foundation: physically validated for camera, placement, and replacement
- M2 Companion Rendering: this branch
- M3 Companion Locomotion: deferred until M2 device validation
- M4 Companion State Machine: placeholder reducer included in M2
- M5 Runtime Integration: deferred to AR-3
- M6 Discovery Objects: engineering placeholder path only
- M7 Threat Objects: engineering placeholder path only
- M8 Full Vertical Slice: deferred
- M9 First Outdoor Alpha: deferred

## Lane 0 — Integration Lead

The integration lead owns branch integrity, API contracts, merge order, shared-file changes, validation gates, and architectural authority. No swarm lane may independently alter a frozen system or merge directly to the canonical branch.

## Architecture Freeze

Unless a task explicitly reopens them, do not modify:

- `MovementEngine`
- `MovementIntegrityProcessor`
- `WorldEventGenerator`
- Bond calculation
- persistence schemas
- `SessionMemory`
- physical-walk receipt format
- audio cue semantics
- existing walking validation

New AR capability must layer on top through `CompanionPresentation`, `ARWorldCommand`, and app-target RealityKit adapters.

## Ownership

| Lane | Owned paths | Forbidden scope |
|---|---|---|
| Companion embodiment | `App/AR/Companion/` | movement, persistence, world generation |
| Command rendering | `App/AR/ARWorldCommandRenderer.swift` | gameplay mutation |
| Spatial placement | `App/AR/ARPlacementResolver.swift`, future `App/AR/Spatial/` | companion state logic |
| Diagnostics | `App/AR/Diagnostics/` | camera frames, coordinates, world maps |
| Validation | `AppTests/AR*` | production runtime behavior changes |
| Integration | shared AR view, XcodeGen, architecture docs | unrelated product expansion |

## Performance Contract

- Do not recreate entities during ordinary state updates.
- Reuse the registered companion anchor and semantic entity hierarchy.
- Do not create meshes or materials in per-frame loops.
- Keep follow and animation updates allocation-light.
- Profile before adding continuous update subscriptions.

## Asset Replacement Contract

The procedural companion is temporary. `CompanionEntityFactory` produces a root named `LiraRoot` with stable semantic children. A future USDZ-backed factory must preserve the same root contract so command routing and state logic remain unchanged.

## Operator Handoff Objective

The branch should require no continuous operator supervision. Before device testing, the operator should only need to run:

```bash
swift test
xcodegen generate
make build
make validate
make validate-simulator
git diff --check
```

## Current Branch Scope

Included:

- procedural Lira placeholder
- five deterministic presentation states
- AR world-command renderer
- reusable placement resolver
- development control surface
- privacy-bounded AR diagnostics
- focused tests

Deferred:

- real walking-driven follow behavior
- final assets and skeletal animation
- GPS-to-AR conversion
- event-generator integration
- Bond or persistence mutation
- production discovery and threat behavior
- multiplayer, cloud anchors, glasses, and creator systems
