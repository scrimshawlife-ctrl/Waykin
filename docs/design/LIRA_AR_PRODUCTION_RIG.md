# Lira AR Production Rig

```yaml
document_id: WAYKIN-LIRA-AR-RIG-001
version: 0.4
status: GENERATED_MID_LOD_SHIPPED
usdz: GENERATED_MID_LOD_V1_2
mesh_descriptor: SHIPPED
runtime_animation_clips: SHIPPED
skeletal_joint_hierarchy: SHIPPED
dcc_skinned_skeletal: NOT_SHIPPED
direction: spectral_living_familiar
evidence_class: GENERATED_MID_LOD
```

## What shipped

| Layer | Implementation | Status |
| ----- | -------------- | ------ |
| Session 2D | Spectral still matrix 7×3 | DIRECTION_ACCEPTED |
| AR mid-LOD | Procedural Living Familiar (`CompanionEntityFactory`) | **Shipped** (fallback) |
| AR mesh primitives | `LiraMeshGeometry` (tapered head, sensor blades, filament segments) | **Shipped** |
| AR local motion | `LiraARMotion` multi-seg filament, ears/tail, body bob, hunter echo | **Shipped** |
| AR runtime clips | `LiraARAnimationLibrary` (`AnimationResource` FromToBy) | **Shipped** |
| AR skeletal puppet | `LiraSkeletalAnimationLibrary` + `LiraSkeletalPlayer` | **Shipped** |
| AR USDZ load | `LiraARAssetLoader.preloadFromBundle()` + hierarchy validate | **Wired** |
| AR USDZ asset | `App/Resources/Lira_AR_Base.usdz` | **GENERATED_MID_LOD v1.2** (joint nesting) |
| USDA source | `docs/assets/companion/ar/src/Lira_AR_Base.usda` | Generator: `scripts/generate_lira_mid_lod_usda.py` |
| Animation plan | [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md) | Mid-LOD complete |

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
CanonicalARSessionRuntime.attach
  → Task { await LiraARAssetLoader.preloadFromBundle() }
ARWorldCommandRenderer spawn
  → assetLoader.makeLira()
       ├─ clone preloaded USDZ if hierarchy valid + apply skin materials
       └─ else CompanionEntityFactory procedural mid-LOD
```

Invalid or missing USDZ never blocks spawn — procedural fallback is permanent safety net.

## Generate / rebuild (default mid-LOD)

```bash
./scripts/build_lira_usdz.sh
```

Evidence class **GENERATED_MID_LOD** — not hand-sculpted. Nested joints include `FilamentBase` / `FilamentMid` / `FilamentTip`.

## Optional artist drop-in (future)

1. Sculpt single shared rig (no per-skin mesh).
2. Name nodes per table above (preserve joint set).
3. Export `Lira_AR_Base.usdz`.
4. Place under app Resources (same filename).
5. Re-run hierarchy validation + `make validate`.
6. Human gore review for hunter poses before outdoor AR claims.
7. Label evidence as artist-authored separately from GENERATED_MID_LOD.

## Explicit non-goals

- Multiplayer mesh marketplace
- Unique mesh per skin
- Gore / teeth / blood hunter geometry
- Claiming outdoor AR quality without Issue #41 device receipt
