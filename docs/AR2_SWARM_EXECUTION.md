# Waykin AR-2 Swarm Execution Contract

## Status

AR-1 physical evidence established camera startup, horizontal placement, and second-placement replacement. AR-2 builds the first procedural companion surface on that validated foundation.

## Lane 0 — Integration Lead

Lane 0 owns branch integrity, merge order, API contracts, conflict resolution, validation gates, and the final draft PR. No worker lane may merge directly into the integration branch without scope review.

## Architecture Freeze

The following surfaces are frozen unless a future work packet explicitly assigns them:

- `MovementEngine`
- `MovementIntegrityProcessor`
- `WorldEventGenerator`
- Bond calculation
- SwiftData persistence schema
- `SessionMemory`
- field-receipt format
- semantic audio-cue selection
- existing walking validation

AR work must layer on top of these systems.

## Ownership

| Lane | Owned paths | Forbidden scope |
|---|---|---|
| Companion | `App/AR/Companion/` | movement, persistence, Bond |
| Renderer | `App/AR/ARWorldCommandRenderer.swift` | core gameplay mutation |
| Debug | `App/AR/Debug/` | production walking flow |
| Diagnostics | `App/AR/Diagnostics/` | camera frames, coordinates, world maps |
| Validation | `AppTests/ARCompanionEmbodimentTests.swift` | production behavior changes |
| Integration | shared files and docs | unreviewed feature expansion |

## Implemented in this run

- Procedural Lira entity with stable semantic children.
- Configurable and clamped visual scale.
- Deterministic `idle`, `follow`, `investigate`, `alert`, and `celebrate` presentation states.
- `ARWorldCommand` renderer for companion, discovery, threat, removal, and clear commands.
- AR Lab control panel for direct device testing.
- Privacy-filtered diagnostic summary.
- Focused unit tests.

## Explicitly deferred

- final USDZ art
- skeletal animation
- walking-driven follow behavior
- event-generator integration
- GPS-to-AR coordinate conversion
- Bond or persistence mutation
- pursuer chase behavior
- outdoor calibration
- AR glasses

## Pre-device gate

```bash
swift test
xcodegen generate
make build
make validate
make validate-simulator
git diff --check
```

The core framework isolation check must return no matches:

```bash
grep -RInE '^[[:space:]]*import[[:space:]]+(ARKit|RealityKit)' Sources/WaykinCore
```

The pre-device status may be declared only after local checks pass:

```text
WAYKIN_AR2_PRE_DEVICE_VALID
```
