# Meshy Lira textured mesh — source receipt

```yaml
evidence_class: MESHY_TEXTURED_STATIC_V1
source_file: Meshy_Lira_ImageTo3D_Textured.usdz
origin: Meshy AI image-to-3d (texture)
date: 2026-07-20
runtime_package: App/Resources/Lira_AR_Base.usdz
animation: puppet / LiraSkeletalPlayer entity-bind (no DCC skeleton in package)
```

## Intent

Use this static textured mesh as the AR embodiment. Animate via existing runtime puppet clips and local motion on promoted semantic nodes (Head, CoreGlow, Filament, …). Walking Meshy export intentionally **not** used.

## Runtime adaptation

- Loader promotes incomplete hierarchy → `LiraRoot` + required marker nodes + mesh under `Body`.
- Authored PBR textures preserved (no `applySkin` paint-over).
- Visual height normalized to ~0.72 m companion scale.

## Non-claims

- Not outdoor AR quality (#41)
- Not skinned DCC walk cycle
- Dawn/Veil/Rupture material remaps deferred for textured mesh
