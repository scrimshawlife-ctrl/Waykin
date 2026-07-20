# Generated Lira Art Pack

```yaml
version: 1.4
style: spectral_living_familiar
anti: [pokemon, mascot, canid_clone, creature_collectible]
status: DIRECTION_ACCEPTED
path: docs/assets/companion/generated/
matrix: complete_7x3
sign_off: docs/design/ART_DIRECTION_SIGN_OFF.md
```

## Design direction (locked)

- Spectral path-born familiar, mature and slightly uncanny
- Anchors A1 tapered head · A2 amber chest ember · A3 filament plume
- Not a pet/mascot/Pokémon read

## Delivered (full matrix)

| Pose \ Skin | Dawn | Veil | Rupture |
| ----------- | ---- | ---- | ------- |
| Guide | ✓ | ✓ | ✓ |
| Hunter | ✓ | ✓ | ✓ |
| Sanctuary | ✓ | ✓ | ✓ |
| Rival | ✓ | ✓ | ✓ |
| Bond | ✓ | ✓ | ✓ |
| Dormant | ✓ | ✓ | ✓ |
| Manifesting | ✓ | ✓ | ✓ |

### Glyphs
Dawn, Veil, Rupture

### Hero
`Lira_Hero_Guide_Dawn.png` (marketing optional)

## App integration

Assets installed under `App/Resources/Assets.xcassets/LiraStills` (21 imagesets) and `LiraGlyph` (3 skins).

### Runtime diagnostics (#133)

| Surface | Path when “new art used” | Fallback / notes |
| ------- | ------------------------ | ---------------- |
| Session 2D | `still:catalog` via `UIImage(named: Lira_Session_*)` | `still:canvas_fallback` Canvas puppet |
| AR mid-LOD | `artist_blend_usdz:Lira_AR_Base.usdz (usdz_active_artist_blend_skinned_mid_lod)` — **ARTIST_BLEND_HERO_DCC_MID_LOD** | `procedural_living_familiar_mid (<note>)` — RealityKit factory fallback; GENERATED USDA via `build_lira_usdz.sh` |

Session HUD shows graphics path; AR chrome shows LOD + “mid-LOD (not hero sculpt)”.
`LiraStillCatalog` resolves `Lira_Session_{Pose}_{Skin}`; missing names fall back to Canvas puppet (none expected for this pack).

## Source masters

`docs/assets/companion/generated/{dawn,veil,rupture,glyphs,hero}/`

## Related

- Sign-off: [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md)
- AR mid-LOD: packaged artist skinned USDZ (`Lira_AR_Base.usdz`) + permanent procedural fallback in `CompanionEntityFactory`

## Quality pass

- v1.1: Dawn full set + Guide Veil/Rupture + hero
- **v1.2: complete Veil + Rupture 7-pose matrix** (full 7×3 quality-passed)
- Session stills: full 7×3 matrix
- AR: skeletal **puppet** clips + skinned mid-LOD package (see LIRA_AR_PRODUCTION_RIG.md)

