# Lira AR mid-LOD source receipt

```yaml
evidence_class: ARTIST_BLEND_HERO_DCC_MID_LOD
version: 1.3
date: 2026-07-20
source: ArtSource/Companion/Lira/lira.blend
armature: LiraArmature (25 bones)
weights: hero region paint (distance falloff + smooth)
dcc_clips: Idle Follow Investigate Alert Celebrate Spawn
```

## OBSERVED

- Armature + auto-skin + **hero region paint** (`paint_lira_hero_weights.py`)
  - Body/Head multi-bone ratio **1.0**, max **4** influences
- DCC actions authored (`author_lira_armature_clips.py`) + NLA tracks
- Main USD binds `SkelAnimation Lira_Idle`; per-clip USD sidecars packaged
- Standalone clip USDZs under `App/Resources/Companion/Lira/Clips/`
- Runtime package ~5.0 MB (mesh + 6 clip USDs + texture)

## Runtime motion stack

| Layer | Source |
| ----- | ------ |
| DCC | USD availableAnimations (name map Lira_*) when present |
| Puppet fill | `LiraSkeletalAnimationLibrary` entity-name clips |
| FX | Filament/core rigid bone-parent |

## NOT_COMPUTABLE

- Outdoor AR (#41)
- Freehand tablet weight-paint logs (hero paint is reproducible, not stylus strokes)
