# Meshy Lira textured mesh — source receipt

```yaml
evidence_class: MESHY_TEXTURED_STATIC_V1
source_file: Meshy_Lira_ImageTo3D_Textured.usdz
origin: Meshy AI image-to-3d (texture)
date: 2026-07-20
runtime_package: App/Resources/Lira_AR_Base.usdz
runtime_size: ~9.6MB (textures max 2048 albedo / 1024 ORM)
source_size: ~38MB full-res (this directory)
animation: puppet / LiraSkeletalPlayer entity-bind (no DCC skeleton in package)
compress: scripts/compress_lira_meshy_usdz.sh
```

## Intent

Use this static textured mesh as the AR embodiment. Animate via existing runtime puppet clips and local motion on promoted semantic nodes (Head, CoreGlow, Filament, …). Walking Meshy export intentionally **not** used.

## Runtime adaptation

- Loader promotes incomplete hierarchy → `LiraRoot` + required marker nodes + mesh under `Body`.
- Spectral FX installed on markers: A2 CoreGlow, A3 Filament segments, GroundShadow, StatusIndicator, HunterEcho.
- `layoutSpectralFXAnchors` places A2/A3/shadow from Body visual bounds after height normalize.
- Authored Body PBR preserved; `applySpectralFXSkin` recolors FX only (Dawn/Veil/Rupture climate on ember/plume).
- Hybrid puppet: Body bob/lean + CoreGlow breath + Filament sway.
- Visual height normalized on Body to ~0.72 m companion scale.
- Runtime package is **texture-compressed** (see compress script); full-res stays in ArtSource.

## Non-claims

- Not outdoor AR quality (#41)
- Not skinned DCC walk cycle
- Not full Body material remap per skin (FX climate only)
