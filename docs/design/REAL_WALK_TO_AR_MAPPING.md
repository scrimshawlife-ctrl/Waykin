# Real Walk → AR Command Mapping

```yaml
document_id: WAYKIN-REAL-WALK-AR-MAP-001
version: 1.2
status: OBSERVED_IN_CODE
device_ar_tracking: PARTIAL_DEVICE_2026_07_20
product_placement: WORLD_PLANT_WITH_CONTINUITY_REPLANT
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

## Presentation triangle (#139) + path soft coupling (#140/#141)

| Tick source | Core behavior | Distance | AR behavior string | 2D pose lean | Audio |
| ----------- | ------------- | -------- | ------------------ | ------------ | ----- |
| quietInterval | rest | 2.0 | idle | sanctuary (dormant if paused) | quietShift (event) |
| companionMovesAhead / lead | lead | 4.0 far | follow + ahead bearing | guide | companionAhead |
| bondMoment | drawNear | 1.2 | celebrate | bond | bondMotif |
| AR presentation transition (event/behavior silent) | (matrix) | (matrix) | investigate / alert / celebrate | (matrix) | `arPresentation:*` → quietShift / pursuitPressure / bondMotif; follow/idle silent |
| path strained (pursuit quiet) | (unchanged) | (unchanged) | investigate | rival lean | prefer `arPresentation:investigate` → quietShift; else quietShift `path:strained` |
| path offPath (pursuit quiet) | (unchanged) | (unchanged) | alert | hunter lean | prefer `arPresentation:alert` → pursuitPressure; else quietShift `path:offPath` |
| path recovered | (unchanged) | (unchanged) | (matrix) | (matrix) | pursuitRelease `path:recovered` if still silent |

Shared resolver: `CompanionPresentationMatrix`. Outdoor multi-surface scorecard: `OUTDOOR_QA_RECEIPT_TEMPLATE.md` Pass COH (#143).

## Product decision (#125) — world-plant + continuity re-plant

**Ratified for solo MVP:** keep **world-plane plant** (ground raycast → `AnchorEntity`). Presentation state `.follow` remains a **local pose**, not walker re-anchor.

Continuity mitigation (code, sim-testable; outdoor PASS requires re-walk):

1. On spawn / re-plant: prefer ground raycast; **camera-anchor fallback** if raycast fails so presence does not vanish when planes drop.
2. On `updateCompanion`: `ensureCompanionContinuity` re-plants when registry-missing, detached, or farther than **6 m** from camera.
3. HUD exposes `Continuity: <note>` (`ok_present` / `planted_ground:*` / `planted_camera:*` / `replant_*`).
4. Full product “follow the walker” remains **out of scope** until a separate expansion issue.

## Gaps (documented, not blocking P/H)

| Gap | Severity | Notes |
| --- | -------- | ----- |
| Physical AR continuity (~10–15 m loss) | **PARTIAL device → code mitigation** | Re-plant + camera fallback shipped; outdoor re-walk required for OBSERVED PASS — #125 |
| World-plant vs “follow walker” expectation | **Decided: world-plant** | Continuity re-plant only; not continuous re-anchor |
| Outdoor glare readability | NOT_COMPUTABLE | Outdoor UI checklist incomplete |
| Menu / AR entry UX awkward | PARTIAL device | #126 flow audit |
| GPS failure | **Not claimed** | Device report is AR presentation, not GPS integrity |
| USDZ mid-LOD | Acceptable | Procedural fallback if load fails |
| Audio coupling | Code mitigation | Event + behavior + AR presentation-transition cues (#130); outdoor audibility NOT_COMPUTABLE until re-walk |

Device receipt: `docs/design/receipts/OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md` · parent #41.

## Tests that prove the bridge

- `CanonicalARRuntimeIntegrationTests`
- `RealMovementSessionTests` (handler receives batches)
- `ARCommandReplaySoakTests`

No new AR features required for pathfinding/HealthKit.
