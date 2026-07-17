# AR-2 Swarm Execution Contract

## Milestone

- M0 Repository Foundation: complete
- M1 AR Runtime Foundation: physically validated for camera, placement, and replacement
- M2 Companion Rendering: active
- M3 Companion Locomotion: deterministic policy only
- M4 Companion State Machine: deterministic placeholder states
- M5 Runtime Integration: deferred until AR-2 physical validation

## Lane 0 — Integration Authority

The integration lane owns branch integrity, API contracts, merge order, shared-file edits, conflict resolution, test gating, and architecture review. No independent lane may alter another lane's owned files or merge directly to the canonical branch.

## Frozen Architecture

The following systems are not modified during AR-2:

- `MovementEngine`
- `MovementIntegrityProcessor`
- `WorldEventGenerator`
- Bond calculation
- persistence schemas
- `SessionMemory`
- field receipt format
- audio cue semantics
- existing walking validation

AR-2 layers presentation behavior on top of sealed `ARWorldCommand` and `SpatialIntent` contracts.

## Ownership

| Surface | Owner | Forbidden dependencies |
|---|---|---|
| `App/AR/Companion/` | Companion embodiment lane | Movement, persistence, Bond |
| `App/AR/Placeholders/` | Placeholder lane | Event generation, progression |
| `App/AR/Diagnostics/` | Diagnostics lane | Camera frames, coordinates, world maps |
| `App/AR/ARWorldCommandRenderer.swift` | Renderer lane | Gameplay mutation |
| `App/AR/WaykinARView.swift` | Integration/UI lane | Core gameplay ownership |
| `AppTests/` AR files | Validation lane | Production behavior changes |

## Asset Replacement Seam

The procedural companion is temporary. Runtime code targets a stable semantic hierarchy rooted at `LiraRoot`. A future USDZ implementation must preserve or bind these semantic parts without changing command routing:

- Body
- Head
- LeftEar
- RightEar
- Tail
- CoreGlow
- GroundShadow
- StatusIndicator

## Performance Rules

- Reuse registry storage.
- Remove replaced anchors before registration.
- Avoid gameplay work in rendering paths.
- Keep locomotion calculations value-based and allocation-light.
- Do not recreate entities per frame.
- Do not retain camera frames or raw world maps.

## AR-2 Scope

Included:

- procedural Lira
- deterministic idle, follow, investigate, alert, and celebrate states
- complete `ARWorldCommand` routing
- discovery and threat engineering placeholders
- development control panel
- privacy-bounded validation diagnostics
- deterministic locomotion policy
- focused tests

Deferred:

- final art and skeletal animation
- GPS-driven following
- event-generator integration
- pursuit locomotion
- Bond or persistence mutation
- AR world-map persistence
- cloud anchors, multiplayer, glasses, and multiple companions

## Exit Gate

Before phone validation:

```bash
swift test
swift test --filter ARPresentationContract
xcodegen generate
make build
make validate
make validate-simulator
git diff --check
```

`Sources/WaykinCore` must contain no ARKit or RealityKit imports.

The pre-device status may be marked only as:

`WAYKIN_AR2_COMPANION_EMBODIMENT_READY_FOR_PHYSICAL_VALIDATION`
