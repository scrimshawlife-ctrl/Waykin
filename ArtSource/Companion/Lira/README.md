# Lira hand-sculpted AR mid-LOD source

Status: **ARTIST_BLEND_ARMATURE_MID_LOD** runtime package (v1.1 from `lira.blend` + `LiraArmature`).  
Fallback generator remains GENERATED_MID_LOD via `./scripts/build_lira_usdz.sh`.

## Runtime contract

- Runtime filename: `Lira_AR_Base.usdz`
- Runtime destinations: `App/Resources/Lira_AR_Base.usdz` (+ nested `Companion/Lira/`)
- Root entity: `LiraRoot`
- Armature: `LiraArmature` (25 bones, rigid bone-parent bind)
- Canonical height: `0.72 m`
- Ground offset: `0.02 m`
- Required semantic nodes:
  - `Body`, `Head`, `LeftEar`, `RightEar`, `Tail`
  - `Filament`, `CoreGlow`, `GroundShadow`, `StatusIndicator`
- Joint extras for skeletal mid-LOD: `FilamentBase`, `FilamentMid`, `FilamentTip`, `CoreHalo`

## Design anchors

Lira is a mature, slightly uncanny spectral living familiar rather than a mascot:

1. tapered non-canid head;
2. paired blade-like sensor ears;
3. amber chest bond core;
4. trailing multi-seg path filament;
5. Dawn palette compatibility with runtime skin remapping.

## Artist blend + armature export (preferred)

```bash
# requires Blender.app + usdzip
./scripts/export_lira_blend_to_usdz.sh ~/Desktop/lira.blend
# or from ArtSource copy:
./scripts/export_lira_blend_to_usdz.sh ArtSource/Companion/Lira/lira.blend
```

Export steps: rename → synthesize missing nodes → **build LiraArmature + bone-parent meshes** → scale 0.72m → USD → usdzip.

Armature-only (open blend already in Blender session):

```bash
/Applications/Blender.app/Contents/MacOS/Blender --background \
  ArtSource/Companion/Lira/lira.blend \
  --python scripts/build_lira_armature.py
```

## Procedural generate (fallback)

```bash
./scripts/build_lira_usdz.sh
```

| Path | Role |
| ---- | ---- |
| `lira.blend` | Artist source (this folder) |
| `scripts/build_lira_armature.py` | Blender armature + rigid bone bind |
| `scripts/export_lira_blend_to_usdz.py` | Rename/scale/armature/USD export |
| `scripts/export_lira_blend_to_usdz.sh` | Blender + usdzip → App Resources |
| `scripts/generate_lira_mid_lod_usda.py` | GENERATED_MID_LOD fallback |
| `BUILD_MANIFEST.json` | Provenance |

## Scope boundary

- Evidence class: **ARTIST_BLEND_ARMATURE_MID_LOD**
- Skeletal **puppet** clips: bind by entity name (shipped)
- Blender armature + USD Skeleton prim: **shipped** (rigid multi-mesh bind)
- Heat-map skinned weights / outdoor readability: **NOT_COMPUTABLE** / not shipped
- Procedural RealityKit factory remains permanent fallback
