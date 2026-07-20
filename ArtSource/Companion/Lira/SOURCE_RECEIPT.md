# Lira AR mid-LOD source receipt

```yaml
evidence_class: ARTIST_BLEND_MID_LOD
version: 1.0
date: 2026-07-20
source: ArtSource/Companion/Lira/lira.blend
```

## OBSERVED

- Artist file: `lira.blend` (Desktop → ArtSource)
- Multi-part mesh/curve Living Familiar under `Lira_ROOT` (no armature)
- Export: `scripts/export_lira_blend_to_usdz.sh` renames to runtime contract, scales to **0.72 m**, USD → usdzip
- Runtime package: `App/Resources/Lira_AR_Base.usdz` (~434 KB)
- Required semantic nodes present after prep; `Tail`/`StatusIndicator`/`CoreHalo` synthesized if missing
- Export unhides `hide_render` objects (artist `GroundShadow` locator was render-hidden and previously dropped by USD)

## Name map (high-level)

| Blend | Runtime |
| ----- | ------- |
| Lira_Body | Body |
| Lira_Head | Head |
| Lira_Ear.L/R | LeftEar / RightEar |
| Lira_Tail | Filament (A3 trail) |
| Lira_TailTip | FilamentTip |
| Lira_ChestGlow | CoreGlow |
| Lira_GroundLocator | GroundShadow |

## INFERRED

- Compatible with hierarchy validation + skeletal **puppet** bind by name
- Not DCC skinned (no bones/weights in blend)

## NOT_COMPUTABLE

- Outdoor AR readability
- True skinned animation library until armature + weights are authored
