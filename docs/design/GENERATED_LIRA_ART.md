# Generated Lira Art Pack

```yaml
version: 1.3
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
`LiraStillCatalog` resolves `Lira_Session_{Pose}_{Skin}`; missing names fall back to Canvas puppet (none expected for this pack).

## Source masters

`docs/assets/companion/generated/{dawn,veil,rupture,glyphs,hero}/`

## Related

- Sign-off: [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md)
- AR mid-LOD: procedural Living Familiar in `CompanionEntityFactory`; USDZ slot at `App/Resources/Companion/Lira/`
