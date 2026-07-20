# Packaged Lira AR USDZ

```yaml
evidence_class: MESHY_TEXTURED_STATIC_V1
file: Lira_AR_Base.usdz
runtime_size: ~9.6MB_compressed
```

Primary: `App/Resources/Lira_AR_Base.usdz` (bundled via xcodegen)  
Mirror: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`  
Docs mirror: `docs/assets/companion/ar/Lira_AR_Base.usdz`  
Full-res source: `ArtSource/Companion/Lira/meshy/Meshy_Lira_ImageTo3D_Textured.usdz`  

Recompress after re-import:

```bash
cp ArtSource/Companion/Lira/meshy/Meshy_Lira_ImageTo3D_Textured.usdz App/Resources/Lira_AR_Base.usdz
./scripts/compress_lira_meshy_usdz.sh
```

## Runtime

1. AR attach → `LiraARAssetLoader.preloadFromBundle()`
2. If hierarchy incomplete → promote markers (Body + A1–A3) + spectral FX (ember/plume/shadow)
3. Spawn clone; preserve Body textures; `applySpectralFXSkin` for Dawn/Veil/Rupture FX climate
4. Hybrid puppet: Body bob/lean + CoreGlow breath + Filament sway
5. On failure → procedural Living Familiar mid-LOD

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
