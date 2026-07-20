# Lira AR Production Rig

```yaml
document_id: WAYKIN-LIRA-AR-RIG-001
version: 0.6
status: MESHY_TEXTURED_STATIC_V1_SHIPPED
usdz: MESHY_TEXTURED_STATIC_V1
mesh_descriptor: SHIPPED
runtime_animation_clips: SHIPPED_PUPPET_STATIC_MESH
skeletal_joint_hierarchy: PROMOTED_MARKERS
blender_armature_rigid_bind: REFERENCE_ONLY
direction: spectral_living_familiar
evidence_class: MESHY_TEXTURED_STATIC_V1
source_mesh: ArtSource/Companion/Lira/meshy/Meshy_Lira_ImageTo3D_Textured.usdz
armature: puppet_markers_plus_optional_prior_LiraArmature
puppet_style: staticMesh_body_plus_spectral_fx
spectral_fx: A2_CoreGlow_A3_Filament_GroundShadow
```

## What shipped

| Layer | Implementation | Status |
| ----- | -------------- | ------ |
| Session 2D | Spectral still matrix 7×3 | DIRECTION_ACCEPTED |
| AR mid-LOD | Procedural Living Familiar (`CompanionEntityFactory`) | **Shipped** (fallback) |
| AR mesh primitives | `LiraMeshGeometry` (tapered head, sensor blades, filament segments) | **Shipped** (fallback) |
| AR local motion | `LiraARMotion` multi-seg filament, ears/tail, body bob, hunter echo | **Shipped** |
| AR runtime clips | `LiraARAnimationLibrary` (`AnimationResource` FromToBy) | **Shipped** |
| AR skeletal puppet | `LiraSkeletalAnimationLibrary` + `LiraSkeletalPlayer` | **Shipped** (entity-bind) |
| AR USDZ load | `LiraARAssetLoader` + hierarchy **promote** for incomplete meshes | **Wired** |
| AR USDZ asset | `App/Resources/Lira_AR_Base.usdz` | **MESHY_TEXTURED_STATIC_V1** (~9.6 MB compressed; ArtSource full-res) |
| Blender armature | `LiraArmature` 25 bones | **Shipped** (`build_lira_armature.py`) |
| Heat-map skin | Auto-weights Body/Head/ears/legs; FX rigid | **Shipped** (`skin_lira_armature.py`) |
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

**Puppet styles** (`LiraSkeletalRig.puppetStyle`):

| Style | When | Motion |
| ----- | ---- | ------ |
| `multiPart` | Procedural factory / multi-mesh artist (Head has mesh) | Head, ears, filament, core, Body factory rest |
| `staticMesh` | Meshy under `Body` + spectral FX (Head empty) | Body bob/lean (identity rest) + CoreGlow breath + Filament sway |

`promoteIncompleteHierarchy` installs spectral FX children on empty markers:

| Node | FX |
| ---- | -- |
| `CoreGlow` / `CoreHalo` | Amber bond spheres (A2) |
| `Filament` | 3-segment plume (A3) |
| `GroundShadow` | Flat dark disc |
| `StatusIndicator` / `HunterEcho` | Chrome / alert ghost |

`applySpectralFXSkin` recolors FX only — Body Meshy PBR is never paint-over.

## Export / rebuild

```bash
# Preferred: artist Blender file (+ auto armature build)
./scripts/export_lira_blend_to_usdz.sh ArtSource/Companion/Lira/lira.blend

# Fallback: procedural GENERATED_MID_LOD
./scripts/build_lira_usdz.sh
```

Evidence class **ARTIST_BLEND_HERO_DCC_MID_LOD**: multi-mesh Living Familiar + `LiraArmature` + automatic heat-map weights on Body/Head/ears/legs (USD `SkelBindingAPI`). FX filament/core stay rigid bone-parent. Hand-painted weights are **not** shipped.

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

1. Hand-paint weights for hero close-ups.
2. Author DCC action clips on `LiraArmature` with same bone names.
3. Outdoor AR QA (#41).

## Explicit non-goals

- Multiplayer mesh marketplace
- Unique mesh per skin
- Gore / teeth / blood hunter geometry
- Claiming outdoor AR quality without Issue #41 device receipt
- Claiming hand-painted hero weight quality without artist paint pass

## Integrity

```bash
./scripts/check_lira_usdz_integrity.sh
./scripts/compress_lira_meshy_usdz.sh   # after re-import from ArtSource
```

Verifies root / nested / docs USDZ byte-match, evidence markers, and runtime size budget (≤20 MB hard / ~12 MB soft).

## Dual motion stack

| Layer | What drives it |
| ----- | -------------- |
| **Puppet clips** | `LiraSkeletalAnimationLibrary` → entity-name `AnimationBindTarget` |
| **Heat-map mesh** | Blender auto-weights on Body/Head/ears/legs (USD SkelBindingAPI) |
| **FX rigid** | Filament / CoreGlow bone-parent (readable A2/A3 under motion) |
| **Reduce Motion** | Stops skeletal loops; rest poses + short spawn coalesce |

Do not claim DCC SkinnedMesh clip playback unless `LIRA_EXPORT_ANIM=1` packages authored actions and a dedicated runtime player is added.


## Hero weights + DCC (v1.3)

- `paint_lira_hero_weights.py`: region falloff + smooth + cap 4
- `author_lira_armature_clips.py`: Idle/Follow/Investigate/Alert/Celebrate/Spawn
- Package includes per-clip USD sidecars; runtime overlays DCC on puppet fill
- `LIRA_EXPORT_ANIM=0` strips animation from export if needed
