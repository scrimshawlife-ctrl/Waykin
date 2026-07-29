# Lira AR Production Rig

```yaml
document_id: WAYKIN-LIRA-AR-RIG-001
version: 0.7
date: 2026-07-29
status: MESHY_EMBER_FOX_WALK_V1_SHIPPED
usdz: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
mesh_descriptor: SHIPPED
runtime_animation: EMBEDDED_WALK_ON_SKELETON
procedural_fallback: SHIPPED_BOUNDED_LOAD_ONLY
supersedes: ARTIST_BLEND_HERO_DCC_MID_LOD
direction: spectral_living_familiar_with_ember_fox_package
evidence_class: MESHY_EMBER_FOX_WALK_V1
armature: meshy_auto_skin_12_joints
```

## Current runtime (PR #246)

| Layer | Implementation | Status |
| ----- | -------------- | ------ |
| Session 2D | Spectral still matrix 7×3 | DIRECTION_ACCEPTED |
| Packaged AR companion | Ember Fox `Lira_AR_Base.usdz` (triple-mirrored) | **Current default** |
| Async template load | Versioned load + live authored replacement | **Shipped** (#246) |
| Procedural Living Familiar | `CompanionEntityFactory` | **Bounded fallback only** |
| Anchor cleanup | Scene-owned anchors explicitly removed on replace/clear | **Shipped** |
| Animation | Embedded walk cycle → skeleton target | **Shipped** |
| Per-state DCC sidecars | Six clip USDZs still bundled | Present; not bound while authored walk is active |
| AR USDZ load path | `LiraARAssetLoader` | **Shipped** |
| Superseded package | Artist-blend / DCC mid-LOD | **Historical** — not active runtime |
| Superseded mesh PRs | #242 / #243 | **Closed** — do not merge |
| Animation plan | [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md) | Incremental clips without base-mesh replace |

### Historical (superseded as default)

| Layer | Note |
| ----- | ---- |
| Artist-blend package | Was ~4.8–5.3 MB `ARTIST_BLEND_HERO_DCC_MID_LOD`; retired as runtime default by #246 |
| Puppet / promote markers | Still used for incomplete meshes and fallback paths |
| Blender export scripts | Remain for future compatible rigs; do not overwrite Ember Fox without an issue |

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
