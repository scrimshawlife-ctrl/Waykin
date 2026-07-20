# Pathfinding (Companion Walk)

```yaml
document_id: WAYKIN-PATHFINDING-001
version: 0.3
status: IMPLEMENTED_V1_1
navigation_grade: false
session_map_breadcrumb: RATIFIED_PRESENTATION_ONLY
```

## Scope

Semantic **path progress** along an active Companion Walk:

- meters along path from accepted movement
- relation: establishing / onPath / strained / offPath / recovered
- integrity pressure 0…1 for presentation (rival/hunter lean)

**Not** turn-by-turn navigation, route planning, or map product expansion.

### Session map presentation (#121 — ratified)

App-layer only (`WalkPathTrace` / `GPSSignalPresentation` / map camera follow):

| Allowed | Not allowed |
| ------- | ----------- |
| In-session breadcrumb of accepted fixes (dedup/capped, ephemeral) | Persisted route history |
| GPS signal chip from existing `LiveLocationSignalState` | Navigation / guidance chrome |
| Smooth map camera follow (Reduce Motion honored) | Corridor geometry / pathfinding v2 |

Outdoor map readability remains `NOT_COMPUTABLE` pending Issue #41.

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
- Session phrases surface path relation when pursuit is quiet
- Field-test receipts record privacy-safe path summary fields (schema 3)
- Session summary shows human path line via `WalkPathCopy` / `SessionSummary.pathPresentationLine`

## Privacy

No coordinates stored in path snapshots or field-test path fields. Route points remain in movement session only.

## Tests

- `PathProgressEngineTests` (package)
- `PathProgressIntegrationTests` (app demo walk)
- `RealMovementSessionTests` path accept/reject
- `CompanionPresencePresentationTests` path phrases
- `FieldTestReceiptTests` path summary round-trip
