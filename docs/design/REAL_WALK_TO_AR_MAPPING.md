# Real Walk → AR Command Mapping

```yaml
document_id: WAYKIN-REAL-WALK-AR-MAP-001
version: 1.0
status: OBSERVED_IN_CODE
device_ar_tracking: NOT_COMPUTABLE
```

## Owner

`WaykinAppModel` emits `[ARWorldCommand]` through `emitARWorldCommands` when a handler is attached (`CanonicalARSessionView` / tests).

Mapper: `CanonicalARWorldCommandMapper`.

## Lifecycle mapping (OBSERVED)

| App / walk event | Source (approx.) | Commands |
| ---------------- | ---------------- | -------- |
| Demo start | `startDemo` | `spawnCompanion` |
| Demo tick | `advanceDemo` | `updateCompanion` (+ discovery/threat per event) |
| Demo end | `endDemo` | `clearSession` |
| Real walk authorized + active | `startRealCompanionWalk` path | `spawnCompanion` |
| Real accepted snapshot + world step | location callback | `updateCompanion` (+ event entities) |
| Real pause/end/fail | pause/end/fail handlers | `clearSession` (on end/fail) |

## Entity IDs (stable)

| Entity | ID constant |
| ------ | ----------- |
| Discovery | `CanonicalARWorldCommandMapper.discoveryID` |
| Threat | `CanonicalARWorldCommandMapper.threatID` |
| Companion registry key | `ARWorldCommandRenderer.companionID` string |

## Pursuit presentation matrix (replay-tested)

| PursuitState | Extra commands |
| ------------ | -------------- |
| inactive / fading | companion only |
| noticed | + discovery |
| approaching / close | + threat |

## Gaps (documented, not blocking P/H)

| Gap | Severity | Notes |
| --- | -------- | ----- |
| Physical AR tracking quality | NOT_COMPUTABLE | Issue #41 |
| Outdoor glare readability | NOT_COMPUTABLE | Outdoor QA deferred |
| USDZ is mid-LOD spheres | Acceptable | Procedural fallback if load fails |
| No skeletal AnimationLibrary | Optional later | C6 art track |

## Tests that prove the bridge

- `CanonicalARRuntimeIntegrationTests`
- `RealMovementSessionTests` (handler receives batches)
- `ARCommandReplaySoakTests`

No new AR features required for pathfinding/HealthKit.
