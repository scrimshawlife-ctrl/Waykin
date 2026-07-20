# AR MVP Freeze Contract

```yaml
document_id: WAYKIN-AR-MVP-FREEZE-001
version: 1.1
date: 2026-07-20
status: FROZEN_FOR_ENGINEERING
evidence_class: SIMULATOR_PLUS_CODE
outdoor_physical_ar: PARTIAL_DEVICE_2026_07_20
outdoor_receipt: docs/design/receipts/OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md
outdoor_pass: REQUIRES_REWALK_ISSUE_41
```

## Purpose

Declare AR presentation **complete for MVP engineering** so pathfinding and HealthKit can proceed without AR feature creep.

## In scope (frozen as shipped)

| Surface | Implementation |
| ------- | -------------- |
| Session 2D Lira | Spectral stills 7×3, skins, motion polish |
| AR mid-LOD | Procedural Living Familiar **or** packaged `Lira_AR_Base.usdz` |
| USDZ load | `LiraARAssetLoader` validate + skin remap + procedural fallback |
| Commands | `ARWorldCommand` from demo + real walk via `CanonicalARWorldCommandMapper` |
| Skins | Dawn / Veil / Rupture materials only |
| Determinism | Replay/soak suites; no wall-clock in core tests |

## Explicit non-goals (do not implement under AR-F)

- Hand-sculpted hero mesh / AnimationLibrary clips
- Outdoor AR tracking quality claims
- Multi-companion AR, marketplace assets
- Navigation map UI, AR glasses
- New companion mechanics

## Frozen paths (maintenance-only)

Unless a **defect** is found:

- `App/AR/**` feature expansion
- USDZ art pipeline expansions
- New AR presentation states beyond existing companion/discovery/threat

Defect fixes and isolation tests remain allowed.

## Real-walk integration (code-observed)

| Event | AR commands |
| ----- | ----------- |
| Real walk starts | `spawn(companionRuntime)` |
| Accepted movement + world update | `update(companion, event)` |
| End / fail / clear | `clearSession` |

See `docs/design/REAL_WALK_TO_AR_MAPPING.md`.

## Exit to pathfinding / HealthKit

When this freeze is accepted:

1. AR presentation status → **Implemented (MVP frozen)**
2. Primary engineering → pathfinding (P), then HealthKit (H)
3. Outdoor/device AR remains parallel evidence only

## Related

- [CONTINUATION_PLAN.md](CONTINUATION_PLAN.md) v0.3
- [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md)
- [AR_REPLAY_VALIDATION.md](../AR_REPLAY_VALIDATION.md)
