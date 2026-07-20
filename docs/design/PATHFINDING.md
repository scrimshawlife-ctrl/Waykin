# Pathfinding (Companion Walk)

```yaml
document_id: WAYKIN-PATHFINDING-001
version: 0.5
status: IMPLEMENTED_V1_3
navigation_grade: false
session_map_breadcrumb: RATIFIED_PRESENTATION_ONLY
session_map_route: PRESENTATION_GUIDE_ONLY
session_map_lifecycle: CLEAR_ON_START_END_FAIL
```

## Scope

Semantic **path progress** along an active Companion Walk:

- meters along path from accepted movement
- relation: establishing / onPath / strained / offPath / recovered
- integrity pressure 0…1 for presentation (rival/hunter lean)

**Not** turn-by-turn voice navigation, corridor pathfinding v2, or gameplay-owned routing.

### Session map presentation (#121 + #155 + #179)

App-layer only (`WalkPathTrace` / `GPSSignalPresentation` / `PlannedWalkRoute` / map chrome):

| Allowed | Not allowed |
| ------- | ----------- |
| In-session breadcrumb of accepted real fixes **and** demo synthetic `routePoints` (dedup/capped, ephemeral) | Persisted route history |
| GPS signal chip from existing `LiveLocationSignalState` | Movement integrity / event authority from map |
| Smooth map camera follow (Reduce Motion honored) | Corridor geometry / pathfinding v2 |
| Full interactive map (pan/zoom) | Turn-by-turn spoken guidance |
| **Create walking route** via place search / long-press → MapKit walking directions | Route as Bond/event selector |
| Planned polyline + distance/time summary (session only) | Coordinates in VoiceOver or field receipts |

Lifecycle: `WaykinAppModel.clearSessionMapPresentation()` resets `walkPathTrace` + `plannedWalkRoute` on **start, end, and fail** (demo + real) so prior session chrome never lingers (#179).

**Legacy Core note:** `MapPresentationState` / `MapEntity` in WaykinCore exist only for `DemoSessionController.presentationState` (package/demo diagnostics). They are **not** wired to App MapKit. Do not extend them for new map features.

Outdoor map readability remains `NOT_COMPUTABLE` pending Issue #41.

### Route creation (#155)

- `WalkRoutePlanner` + `MapKitWalkingDirections` (injectable for tests)
- Session state: `WaykinAppModel.plannedWalkRoute` (cleared on session start/end/**fail** with the breadcrumb)
- UI: compact map → full map; search place or long-press pin; clear route
- Product copy: **guide only** — Lira/events still follow real accepted movement

## Core API

`PathProgressEngine` + `PathProgressSnapshot` in WaykinCore.

| Input | Effect |
| ----- | ------ |
| `recordAccepted(MovementSnapshot)` | +meters, clear reject streak, update relation |
| `recordRejected()` | +reject streak → strained / offPath |

## App wiring

- Demo ticks → accepted path progress + synthetic `WalkPathTrace` append from last `routePoints`
- Real walk → accepted on integrity pass (trace append); rejected on fail (except fresh anchor wait)
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
