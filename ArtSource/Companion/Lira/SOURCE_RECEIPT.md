# Lira AR mid-LOD source receipt

```yaml
evidence_class: GENERATED_MID_LOD
version: 1.2
date: 2026-07-20
```

## OBSERVED

- Generator: `scripts/generate_lira_mid_lod_usda.py`
- Package: `scripts/build_lira_usdz.sh` → `App/Resources/Lira_AR_Base.usdz`
- Root `LiraRoot` with required semantic nodes + nested filament joints
- Explicit **not** labeled hand-sculpted artist mesh

## INFERRED

- Compatible with runtime `LiraSkeletalPlayer` joint names
- Procedural RealityKit factory remains permanent fallback if load fails

## NOT_COMPUTABLE

- Outdoor AR readability
- True DCC skinned deformation / painted weights
