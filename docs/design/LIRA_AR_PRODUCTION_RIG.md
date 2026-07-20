# Lira AR Production Rig

```yaml
document_id: WAYKIN-LIRA-AR-RIG-001
version: 0.5
status: ARTIST_BLEND_ARMATURE_MID_LOD_SHIPPED
usdz: ARTIST_BLEND_ARMATURE_MID_LOD_V1
mesh_descriptor: SHIPPED
runtime_animation_clips: SHIPPED
skeletal_joint_hierarchy: SHIPPED
blender_armature_rigid_bind: SHIPPED
dcc_skinned_weights: NOT_SHIPPED
direction: spectral_living_familiar
evidence_class: ARTIST_BLEND_ARMATURE_MID_LOD
source_blend: ArtSource/Companion/Lira/lira.blend
armature: LiraArmature
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
| AR USDZ asset | `App/Resources/Lira_AR_Base.usdz` | **ARTIST_BLEND_ARMATURE_MID_LOD** (~515 KB) |
| Blender armature | `LiraArmature` 25 bones, rigid bone-parent multi-mesh | **Shipped** (`build_lira_armature.py`) |
| Artist source | `ArtSource/Companion/Lira/lira.blend` | Export: `scripts/export_lira_blend_to_usdz.sh` |
| Generated fallback | `docs/assets/companion/ar/src/Lira_AR_Base.usda` | `scripts/build_lira_usdz.sh` |
| Animation plan | [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md) | Mid-LOD + armature |

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

Skeletal clips bind via `AnimationBindTarget.entity(name)` on semantic nodes (puppet paths), not SkinnedMesh weight maps.

## Export / rebuild

```bash
# Preferred: artist Blender file (+ auto armature build)
./scripts/export_lira_blend_to_usdz.sh ArtSource/Companion/Lira/lira.blend

# Fallback: procedural GENERATED_MID_LOD
./scripts/build_lira_usdz.sh
```

Evidence class **ARTIST_BLEND_ARMATURE_MID_LOD**: multi-mesh Living Familiar + Blender armature with rigid bone-parent bind. USD includes a `Skeleton` prim. Heat-map skin weights are **not** shipped.

## Armature joint tree (Blender)

```text
Root
 └─ Body
     ├─ Chest → CoreGlow, CoreHalo, Neck → Head → ears/snout/status
     ├─ Tail
     ├─ Filament → FilamentBase → FilamentMid → FilamentTip
     └─ Legs → Paws
 └─ GroundShadow
```

## Optional next (not this ship)

1. Merge organic body into one mesh and paint heat-map weights.
2. Author DCC action clips on `LiraArmature` with same bone names.
3. Outdoor AR QA (#41).

## Explicit non-goals

- Multiplayer mesh marketplace
- Unique mesh per skin
- Gore / teeth / blood hunter geometry
- Claiming outdoor AR quality without Issue #41 device receipt
- Claiming heat-map skinned deformation without weight-painted mesh
