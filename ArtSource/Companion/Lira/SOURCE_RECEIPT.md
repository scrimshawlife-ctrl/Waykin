# Lira AR mid-LOD source receipt

```yaml
evidence_class: ARTIST_BLEND_SKINNED_MID_LOD
version: 1.2
date: 2026-07-20
source: ArtSource/Companion/Lira/lira.blend
armature: LiraArmature (25 bones)
skin: automatic heat-map weights (ARMATURE_AUTO)
```

## OBSERVED

- Artist multi-part Living Familiar under `Lira_ROOT`
- Armature: `scripts/build_lira_armature.py` → **LiraArmature** (25 bones)
- Skin: `scripts/skin_lira_armature.py`
  - Merge **Body+Chest+Neck → Body**, **Head+Snout → Head**
  - Automatic weights on Body/Head/ears/legs/paws/detail
  - Rigid bone-parent FX: CoreGlow/Halo, Filament*, Tail, GroundShadow, StatusIndicator
- Body heat-map: **1830 verts**, **1709 multi-bone**, max **5** influences
- Head heat-map: **1830 verts**, **1216 multi-bone**, max **5** influences
- USD exports `Skeleton` + `primvars:skel:jointIndices/jointWeights` (SkelBindingAPI)
- Runtime package: `App/Resources/Lira_AR_Base.usdz` (~754 KB)

## INFERRED

- Suitable for bone-driven mid-LOD deformation + existing puppet entity clips by name
- Auto-weights are not artist-painted; acceptable for mid-LOD, not hero close-ups

## NOT_COMPUTABLE

- Outdoor AR readability (#41)
- Hand-painted weight quality / DCC performance action library
