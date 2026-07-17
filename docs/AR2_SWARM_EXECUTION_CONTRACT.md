# Waykin AR-2 Swarm Execution Contract

## Milestone

- M0 Repository Foundation: complete
- M1 AR Runtime Foundation: physically validated
- M2 Companion Rendering: active
- M3 Companion Locomotion: included as deterministic presentation logic
- M4 Companion State Machine: included
- M5 Runtime Integration: deferred until physical M2 validation

## Lane 0 — Integration Authority

Lane 0 owns branch integrity, merge order, shared interfaces, conflict resolution, validation gates, and final scope review. No implementation lane may modify another lane's owned files without an explicit integration decision.

## Frozen Systems

The following systems are frozen for this run:

- MovementEngine
- MovementIntegrityProcessor
- WorldEventGenerator
- Bond calculation
- Persistence schema
- SessionMemory
- Existing walking validation
- Field receipt format
- Audio cue semantics

New AR work must layer above these systems.

## Ownership

- `App/AR/Companion/`: procedural companion, state, animation, locomotion, orientation
- `App/AR/Debug/`: AR Lab controls and deterministic scenarios
- `App/AR/Diagnostics/`: privacy-filtered AR diagnostics
- `App/AR/Placeholders/`: discovery and threat engineering entities
- `App/AR/Spatial/`: semantic placement policy
- `App/AR/ARWorldCommandRenderer.swift`: command routing only
- `AppTests/AR2*`: deterministic AR-2 tests

## Performance Contract

- Reuse entities after creation where practical.
- Do not recreate meshes or materials per frame.
- Keep state reduction and locomotion calculations allocation-light.
- Keep all RealityKit update behavior app-target only.

## Asset Replacement Contract

The procedural companion is an implementation placeholder behind `CompanionEntityFactory`. Stable semantic child names must permit a later USDZ-backed factory without changing command routing, state reduction, diagnostics, or gameplay contracts.

## Operator Gate

The swarm should leave the branch ready for these commands without intermediate human repair:

```bash
swift test
xcodegen generate
make build
make validate
make validate-simulator
git diff --check
```

Physical validity remains unclaimed until the next device run.
