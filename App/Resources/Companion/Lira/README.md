# Packaged Lira AR USDZ

```yaml
evidence_class: ARTIST_BLEND_HERO_DCC_MID_LOD
file: Lira_AR_Base.usdz
runtime_size: ~4.8MB_artist_blend_dcc
```

Primary: `App/Resources/Lira_AR_Base.usdz` (bundled via xcodegen)  
Mirror: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`  
Docs mirror: `docs/assets/companion/ar/Lira_AR_Base.usdz`  
Artist source: `ArtSource/Companion/Lira/lira.blend`  

Re-export after sculpt / clip changes (does **not** use the Meshy interim path):

```bash
./scripts/export_lira_blend_to_usdz.sh ArtSource/Companion/Lira/lira.blend
./scripts/check_lira_usdz_integrity.sh
```

Legacy Meshy image-to-3d packages (if still under `ArtSource/Companion/Lira/meshy/`) are
**not** the runtime default. Do not copy them over `Lira_AR_Base.usdz`.

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
