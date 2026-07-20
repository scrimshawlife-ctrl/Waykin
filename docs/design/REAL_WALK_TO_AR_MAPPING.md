# Real Walk → AR Command Mapping

```yaml
document_id: WAYKIN-REAL-WALK-AR-MAP-001
version: 1.1
status: OBSERVED_IN_CODE
device_ar_tracking: PARTIAL_DEVICE_2026_07_20
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
| Physical AR continuity (~10–15 m loss) | **PARTIAL device** | OBSERVED disappear; re-open recovers — #125 |
| World-plant vs “follow walker” expectation | Design decision | Placement is ground-plane anchor; presentation `.follow` is local pose — not continuous re-anchor |
| Outdoor glare readability | NOT_COMPUTABLE | Outdoor UI checklist incomplete |
| Menu / AR entry UX awkward | PARTIAL device | #126 flow audit |
| GPS failure | **Not claimed** | Device report is AR presentation, not GPS integrity |
| USDZ mid-LOD | Acceptable | Procedural fallback if load fails |

Device receipt: `docs/design/receipts/OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md` · parent #41.

## Tests that prove the bridge

- `CanonicalARRuntimeIntegrationTests`
- `RealMovementSessionTests` (handler receives batches)
- `ARCommandReplaySoakTests`

No new AR features required for pathfinding/HealthKit.
