# AR MVP Freeze Contract

```yaml
document_id: WAYKIN-AR-MVP-FREEZE-001
version: 1.2
date: 2026-07-29
status: FROZEN_FOR_ENGINEERING
evidence_class: SIMULATOR_PLUS_CODE
outdoor_physical_ar: PARTIAL_DEVICE_2026_07_20_HISTORICAL
outdoor_receipt: docs/design/receipts/OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md
outdoor_pass: REQUIRES_REWALK_ISSUE_41
packaged_companion: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
main_tip_at_refresh: 7df3a16
```

## Purpose

Declare AR presentation **complete for MVP engineering** so pathfinding and HealthKit can proceed without AR feature creep. Mesh/runtime shipping under approved issues (e.g. #246) is **package + loader maintenance**, not a freeze exit.

## In scope (frozen as shipped)

| Surface | Implementation |
| ------- | -------------- |
| Session 2D Lira | Spectral stills 7×3, skins, motion polish |
| AR mid-LOD companion | Packaged **Ember Fox** `Lira_AR_Base.usdz` (`MESHY_EMBER_FOX_WALK_V1`) |
| USDZ load | `LiraARAssetLoader`: versioned async template load, procedural fallback, live authored replacement |
| Anchor ownership | Scene-owned anchors explicitly removed on clear/replace (no duplicate companions) |
| Animation | Embedded walk cycle targets skeleton; per-state DCC sidecars may exist for fallback paths |
| Commands | `ARWorldCommand` from demo + real walk via `CanonicalARWorldCommandMapper` |
| Skins | Dawn / Veil / Rupture materials only (FX / climate remap as implemented) |
| Determinism | Replay/soak suites; no wall-clock in core tests |

## Explicit non-goals (do not implement under AR-F)

- Replacing the Ember Fox base mesh without an explicit asset issue
- Merging closed mesh branches **#242** / **#243** (superseded by **#246**)
- Outdoor AR tracking quality claims without #41 device evidence
- Multi-companion AR, marketplace assets
- Navigation map UI, AR glasses
- New companion mechanics
- Broad AR session UX redesign before Phase 0 product-law reconciliation

### Authorized mesh package history

| Event | Authority | Status |
| ----- | --------- | ------ |
| Interim Meshy / stub USDZ | Pre-#220 | Retired |
| Artist mid-LOD + DCC (`ARTIST_BLEND_HERO_DCC_MID_LOD`) | #220 / #222–#226 | **Superseded as runtime default** |
| Ember Fox packaged walk | **PR #246** | **Current runtime default** |

Scope of mesh work remains package + evidence class + integrity/tests + loader defects — not AR feature expansion.

## Frozen paths (maintenance-only)

Unless a **defect** is found or an **explicit issue** authorizes a narrow change:

- `App/AR/**` feature expansion
- USDZ art pipeline expansions beyond approved asset issues
- New AR presentation states beyond existing companion/discovery/threat

Defect fixes, integrity tests, and approved mesh/loader repairs remain allowed.

## Real-walk integration (code-observed)

| Event | AR commands |
| ----- | ----------- |
| Real walk starts | `spawn(companionRuntime)` |
| Accepted movement + world update | `update(companion, event)` |
| End / fail / clear | `clearSession` |

Gameplay pressure tuning (PR **#248**) may change event reachability; it does **not** authorize AR presentation feature work.

See `docs/design/REAL_WALK_TO_AR_MAPPING.md`.

## Exit to pathfinding / HealthKit

When this freeze is accepted:

1. AR presentation status → **Implemented (MVP frozen)**
2. Primary engineering → pathfinding (P), then HealthKit (H)
3. Outdoor/device AR remains parallel evidence only

## Related

- [CONTINUATION_PLAN.md](CONTINUATION_PLAN.md) v5.0
- [AR_PRODUCT_REDESIGN_MAP.md](AR_PRODUCT_REDESIGN_MAP.md) and [AR_APP_REDESIGN_PLAN.md](../plans/AR_APP_REDESIGN_PLAN.md) — Phase 0 promotes AR-designed identity without lifting frozen production paths
- [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md)
- [AR_REPLAY_VALIDATION.md](../AR_REPLAY_VALIDATION.md)
- [ACTIVE_WORK.md](../collaboration/ACTIVE_WORK.md)
