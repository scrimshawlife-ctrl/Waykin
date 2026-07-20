# Packaged Lira AR USDZ

```yaml
evidence_class: MESHY_TEXTURED_STATIC_V1
file: Lira_AR_Base.usdz
```

Primary: `App/Resources/Lira_AR_Base.usdz`  
Mirror: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`  
Docs mirror: `docs/assets/companion/ar/Lira_AR_Base.usdz`  
Source: `ArtSource/Companion/Lira/meshy/Meshy_Lira_ImageTo3D_Textured.usdz`

## Runtime

1. AR attach → `LiraARAssetLoader.preloadFromBundle()`
2. If hierarchy incomplete → promote markers (Body + A1–A3 empties)
3. Spawn clone; preserve textures; puppet animation binds to semantic names
4. On failure → procedural Living Familiar mid-LOD

## Required hierarchy (post-promote)

| Node | Role |
|------|------|
| `LiraRoot` | Root |
| `Body` | Visual mesh parent |
| `Head`, `LeftEar`, `RightEar`, `Tail` | Puppet / motion |
| `Filament`, `CoreGlow` | A3 / A2 anchors |
| `GroundShadow`, `StatusIndicator` | Chrome |

## Integrity

```bash
./scripts/check_lira_usdz_integrity.sh
```
