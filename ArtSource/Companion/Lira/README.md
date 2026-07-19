# Lira hand-sculpted AR mid-LOD source

Status: optional art-track source; no runtime behavior change.

## Runtime contract

- Runtime filename: `Lira_AR_Base.usdz`
- Runtime destination: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`
- Root entity: `LiraRoot`
- Canonical height: `0.72 m`
- Ground offset: `0.02 m`
- Required semantic nodes:
  - `Body`
  - `Head`
  - `LeftEar`
  - `RightEar`
  - `Tail`
  - `Filament`
  - `CoreGlow`
  - `GroundShadow`
  - `StatusIndicator`

## Design anchors

Lira is a mature, slightly uncanny spectral living familiar rather than a mascot. The sculpt preserves:

1. tapered non-canid head;
2. paired blade-like sensor ears;
3. amber chest bond core;
4. trailing path filament;
5. Dawn palette compatibility with runtime skin remapping.

## Source package

The generated source package contains:

- `Lira_AR_Base.glb`
- `Lira_AR_Base.obj`
- `BUILD_MANIFEST.json`
- `Lira_preview.png`

The binary source package was generated outside the repository and is intentionally not represented as a production USDZ. Before runtime inclusion:

1. open the GLB in Blender or Reality Converter;
2. preserve `LiraRoot` and all semantic node names;
3. export as `Lira_AR_Base.usdz`;
4. place the USDZ in `App/Resources/Companion/Lira/`;
5. run hierarchy validation and the full Waykin validation suite;
6. perform physical-device outdoor readability and performance checks.

## Scope boundary

This source is static and unrigged. It does not claim AnimationLibrary compatibility, production UVs, outdoor readability, or physical-device performance. The procedural Living Familiar remains the permanent fallback.