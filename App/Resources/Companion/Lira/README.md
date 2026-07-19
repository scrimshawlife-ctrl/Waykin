# Lira AR assets

```yaml
lod: AR_mid
companion: Lira
rig: Living_Familiar
file: Lira_AR_Base.usdz
```

## Packaged asset

Primary bundle path (copied into app): `App/Resources/Lira_AR_Base.usdz`  
Mirror: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`

Mid-LOD Living Familiar with named anchors:

| Node | Role |
| ---- | ---- |
| `LiraRoot` | Root |
| `Head` | A1 tapered snout |
| `CoreGlow` | A2 bond ember |
| `Filament` | A3 path plume |
| `Body`, `LeftEar`, `RightEar`, `Tail`, `GroundShadow`, `StatusIndicator` | Required hierarchy |
| `HunterEcho` | Optional pressure ghost |
| `Chest`, `Haunch`, `CoreHalo`, `FilamentTip` | Volume extras |

## Runtime

1. AR attach → `LiraARAssetLoader.preloadFromBundle()`
2. Load + validate required nodes → clone + skin materials
3. If load/validation fails → procedural `CompanionEntityFactory`

Rebuild:

```bash
./scripts/build_lira_usdz.sh
```

Source USDA: `docs/assets/companion/ar/src/Lira_AR_Base.usda`

## Skins

One mesh; Dawn / Veil / Rupture remapped at runtime.
