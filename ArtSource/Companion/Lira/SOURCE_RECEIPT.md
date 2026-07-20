# Lira sculpt / mid-LOD source receipt

```yaml
asset: Lira_AR_Base
source_status: USDA_MID_LOD_V1_1
runtime_status: PACKAGED
runtime_paths:
  - App/Resources/Lira_AR_Base.usdz
  - App/Resources/Companion/Lira/Lira_AR_Base.usdz
source: docs/assets/companion/ar/src/Lira_AR_Base.usda
build: scripts/build_lira_usdz.sh
required_node_generation: PASS
usdz_conversion: PASS
realitykit_load: SIMULATOR_COVERED
physical_device_validation: NOT_RUN
animation_library: NOT_SHIPPED
```

## Interpretation

- **OBSERVED:** Runtime USDZ rebuilt from enriched USDA with required hierarchy; loader tests cover packaged + procedural fallback.
- **INFERRED:** Soft asymmetry + Snout improve Living Familiar read vs sphere-stack mascot.
- **NOT_COMPUTABLE:** Outdoor AR readability; skeletal AnimationLibrary until DCC clips land.

## Binary GLB note

Offline GLB/OBJ (5.8k verts) referenced historically remains optional art-track; repository runtime path is USDA→USDZ mid-LOD with permanent procedural fallback.
