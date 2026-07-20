# Lira AR assets

```yaml
lod: AR_mid
companion: Lira
evidence_class: ARTIST_BLEND_HERO_DCC_MID_LOD
file: Lira_AR_Base.usdz
```

## Packaged asset

Primary: `App/Resources/Lira_AR_Base.usdz`  
Mirror: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`

Artist multi-mesh + `LiraArmature` + auto-weight heat-map. Named anchors:

| Node | Role |
| ---- | ---- |
| `LiraRoot` | Root |
| `Head` | A1 tapered snout |
| `CoreGlow` | A2 bond ember |
| `Filament` | A3 path plume |
| `Body`, `LeftEar`, `RightEar`, `Tail`, `GroundShadow`, `StatusIndicator` | Required hierarchy |

## Runtime

1. AR attach → `LiraARAssetLoader.preloadFromBundle()`
2. Load + validate required nodes → clone + skin materials
3. If load/validation fails → procedural `CompanionEntityFactory`

## Rebuild

```bash
# Preferred: artist blend + armature + auto-weights
./scripts/export_lira_blend_to_usdz.sh ArtSource/Companion/Lira/lira.blend

# Fallback generator (GENERATED_MID_LOD USDA only)
./scripts/build_lira_usdz.sh

# Integrity
./scripts/check_lira_usdz_integrity.sh
```

## Motion stack (dual)

| Layer | Mechanism |
| ----- | --------- |
| Runtime clips | `LiraSkeletalPlayer` binds **entity names** (puppet paths) |
| Mesh deform | USD heat-map weights on Body/Head/ears/legs |
| FX | Filament/core rigid bone-parent |

Optional DCC actions: `scripts/author_lira_armature_clips.py` → `LIRA_EXPORT_ANIM=1` on export.

## Skins

One mesh package; Dawn / Veil / Rupture remapped at runtime (live re-apply supported).
