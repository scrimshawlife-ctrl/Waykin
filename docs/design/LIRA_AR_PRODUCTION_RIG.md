# Lira AR Production Rig

```yaml
document_id: WAYKIN-LIRA-AR-RIG-001
version: 0.1
status: PROCEDURAL_MID_SHIPPED
usdz: OPTIONAL_DROP_IN
direction: spectral_living_familiar
```

## What shipped

| Layer | Implementation | Status |
| ----- | -------------- | ------ |
| Session 2D | Spectral still matrix 7×3 | DIRECTION_ACCEPTED |
| AR mid-LOD | Procedural Living Familiar (`CompanionEntityFactory`) | **Shipped** |
| AR USDZ | Artist drop-in `Lira_AR_Base.usdz` | Slot ready; not required |
| Reference USDZ | `docs/assets/companion/ar/Lira_AR_Base.usdz` | Sketch / proportions |

## Anchors (required)

| ID | Node | Role |
| -- | ---- | ---- |
| A1 | `Head` | Tapered non-canid snout |
| A2 | `CoreGlow` | Amber bond ember |
| A3 | `Filament` | Trailing path plume |
| — | `Body`, `LeftEar`, `RightEar`, `Tail`, `GroundShadow`, `StatusIndicator` | Hierarchy contract |

Skins Dawn / Veil / Rupture change **materials only**.

## Runtime

```text
CompanionEntityFactory.makeLira()
  → procedural Living Familiar mid-LOD (default)
LiraARAssetCatalog.hasPackagedUSDZ
  → true when App/Resources/Companion/Lira/Lira_AR_Base.usdz is packaged
```

Async USDZ load + material remap is a follow-up once a sculpted mesh exists; hierarchy names must match.

## Drop-in steps (artist)

1. Sculpt single shared rig (no per-skin mesh).
2. Name nodes per table above.
3. Export `Lira_AR_Base.usdz`.
4. Place under `App/Resources/Companion/Lira/`.
5. Wire async load (separate PR) preserving `LiraRoot` + A1–A3.
6. Human gore review for hunter poses before outdoor AR claims.

## Explicit non-goals

- Multiplayer mesh marketplace
- Unique mesh per skin
- Gore / teeth / blood hunter geometry
- Claiming outdoor AR quality without Issue #41 device receipt
