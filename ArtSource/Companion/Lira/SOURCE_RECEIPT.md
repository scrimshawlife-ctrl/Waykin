# Lira AR mid-LOD source receipt

```yaml
evidence_class: ARTIST_BLEND_ARMATURE_MID_LOD
version: 1.1
date: 2026-07-20
source: ArtSource/Companion/Lira/lira.blend
armature: LiraArmature (25 bones, rigid bone-parent)
```

## OBSERVED

- Artist file: `lira.blend` multi-part Living Familiar under `Lira_ROOT`
- Armature: `scripts/build_lira_armature.py` creates **LiraArmature** with bones matching runtime joints (`Body`, `Head`, `Filament`…`FilamentTip`, legs/paws)
- Bind: **rigid bone-parent** (each mesh → bone), not heat-map skin weights
- Export: `scripts/export_lira_blend_to_usdz.sh` renames, builds armature, scales to **0.72 m**, USD (Skeleton prim) → usdzip
- Runtime package: `App/Resources/Lira_AR_Base.usdz` (~515 KB incl. textures)
- FilamentBase / FilamentMid markers synthesized for multi-seg clips

## Name map (high-level)

| Blend | Runtime joint / mesh |
| ----- | -------------------- |
| Lira_Body | Body |
| Lira_Head | Head |
| Lira_Ear.L/R | LeftEar / RightEar |
| Lira_Tail | Filament (A3) |
| Lira_TailTip | FilamentTip |
| Lira_ChestGlow | CoreGlow |
| Lira_GroundLocator | GroundShadow |
| *(generated)* | LiraArmature + FilamentBase/Mid |

## INFERRED

- Compatible with hierarchy validation + skeletal **puppet** bind by entity name
- USD `Skeleton` joints path mirrors bone tree for future DCC clip work

## NOT_COMPUTABLE

- Outdoor AR readability
- True heat-map skinned deformation (requires merged topology + weight paint)
