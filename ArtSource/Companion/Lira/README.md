# Lira hand-sculpted AR mid-LOD source

Status: **GENERATED_MID_LOD** runtime package (v1.2). Not hand-sculpted artist mesh.

## Runtime contract

- Runtime filename: `Lira_AR_Base.usdz`
- Runtime destinations: `App/Resources/Lira_AR_Base.usdz` (+ nested `Companion/Lira/`)
- Root entity: `LiraRoot`
- Canonical height: `0.72 m`
- Ground offset: `0.02 m`
- Required semantic nodes:
  - `Body`, `Head`, `LeftEar`, `RightEar`, `Tail`
  - `Filament`, `CoreGlow`, `GroundShadow`, `StatusIndicator`
- Joint extras for skeletal mid-LOD: `FilamentBase`, `FilamentMid`, `FilamentTip`, `CoreHalo`

## Design anchors

Lira is a mature, slightly uncanny spectral living familiar rather than a mascot:

1. tapered non-canid head;
2. paired blade-like sensor ears;
3. amber chest bond core;
4. trailing multi-seg path filament;
5. Dawn palette compatibility with runtime skin remapping.

## Generate and package

```bash
# regenerate USDA + USDZ (requires python3 + usdzip)
./scripts/build_lira_usdz.sh
```

| Path | Role |
| ---- | ---- |
| `scripts/generate_lira_mid_lod_usda.py` | Source of truth generator |
| `docs/assets/companion/ar/src/Lira_AR_Base.usda` | Generated USDA |
| `scripts/build_lira_usdz.sh` | usdzip → App + docs |
| `BUILD_MANIFEST.json` | Provenance |

## Future artist drop-in

Optional hand-sculpted GLB may replace generated mid-LOD **only** if node names match. Open in Blender/Reality Converter, preserve `LiraRoot` + required joints, export USDZ, re-run validation. Label that package as artist-authored separately.

## Scope boundary

- Evidence class: **GENERATED_MID_LOD**
- Skeletal **puppet** joints: compatible
- DCC skinned weights / outdoor readability: **NOT_COMPUTABLE** / not shipped
- Procedural RealityKit factory remains permanent fallback