# Pathfinding (Companion Walk)

```yaml
document_id: WAYKIN-PATHFINDING-001
version: 0.1
status: IMPLEMENTED_MVP
navigation_grade: false
```

## Scope

Semantic **path progress** along an active Companion Walk:

- meters along path from accepted movement
- relation: establishing / onPath / strained / offPath / recovered
- integrity pressure 0…1 for presentation (rival/hunter lean)

**Not** turn-by-turn navigation, route planning, or map product expansion.

## Core API

`PathProgressEngine` + `PathProgressSnapshot` in WaykinCore.

| Input | Effect |
| ----- | ------ |
| `recordAccepted(MovementSnapshot)` | +meters, clear reject streak, update relation |
| `recordRejected()` | +reject streak → strained / offPath |

## App wiring

- Demo ticks → accepted only
- Real walk → accepted on integrity pass; rejected on fail (except fresh anchor wait)
- `WaykinAppModel.pathProgress` exposed for UI diagnostics
- `LiraSessionPose` uses integrity pressure when pursuit is inactive

## Privacy

No coordinates stored in path snapshots. Route points remain in movement session only.

## Tests

- `PathProgressEngineTests` (package)
- `PathProgressIntegrationTests` (app demo walk)
