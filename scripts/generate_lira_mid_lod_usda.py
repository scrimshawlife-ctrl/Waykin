#!/usr/bin/env python3
"""
Generate Lira AR mid-LOD USDA (GENERATED_MID_LOD).

- Spectral Living Familiar prim hierarchy (not hand-sculpted claim)
- Nested joints for FilamentBase/Mid/Tip so skeletal clips can bind
- Required nodes: Body, Head, LeftEar, RightEar, Tail, Filament, CoreGlow,
  GroundShadow, StatusIndicator under LiraRoot

Usage:
  python3 scripts/generate_lira_mid_lod_usda.py
  python3 scripts/generate_lira_mid_lod_usda.py --out docs/assets/companion/ar/src/Lira_AR_Base.usda
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = ROOT / "docs/assets/companion/ar/src/Lira_AR_Base.usda"

# Dawn-ish display colors (runtime remaps skins)
BODY = (0.91, 0.85, 0.77)
BODY_SEC = (0.79, 0.72, 0.60)
FRINGE = (0.25, 0.56, 0.54)
BOND = (0.83, 0.64, 0.35)
FILAMENT = (0.48, 0.62, 0.60)
HUNTER = (0.70, 0.68, 0.74)
SHADOW = (0.05, 0.05, 0.05)
STATUS = (0.90, 0.92, 0.94)


def c(rgb: tuple[float, float, float]) -> str:
    return f"[({rgb[0]:.2f}, {rgb[1]:.2f}, {rgb[2]:.2f})]"


def sphere(
    name: str,
    radius: float,
    color: tuple[float, float, float],
    translate: tuple[float, float, float],
    scale: tuple[float, float, float] | None = None,
    indent: int = 4,
    children: str = "",
) -> str:
    pad = " " * indent
    lines = [
        f'{pad}def Sphere "{name}"',
        f"{pad}{{",
        f"{pad}    double radius = {radius}",
        f"{pad}    color3f[] primvars:displayColor = {c(color)}",
    ]
    ops: list[str] = []
    if translate != (0.0, 0.0, 0.0):
        lines.append(
            f"{pad}    float3 xformOp:translate = ({translate[0]}, {translate[1]}, {translate[2]})"
        )
        ops.append("xformOp:translate")
    if scale is not None:
        lines.append(f"{pad}    float3 xformOp:scale = ({scale[0]}, {scale[1]}, {scale[2]})")
        ops.append("xformOp:scale")
    if ops:
        order = ", ".join(f'"{o}"' for o in ops)
        lines.append(f"{pad}    uniform token[] xformOpOrder = [{order}]")
    if children:
        lines.append(children.rstrip())
    lines.append(f"{pad}}}")
    return "\n".join(lines)


def xform(
    name: str,
    translate: tuple[float, float, float],
    indent: int,
    body: str,
) -> str:
    pad = " " * indent
    return "\n".join(
        [
            f'{pad}def Xform "{name}"',
            f"{pad}{{",
            f"{pad}    float3 xformOp:translate = ({translate[0]}, {translate[1]}, {translate[2]})",
            f'{pad}    uniform token[] xformOpOrder = ["xformOp:translate"]',
            body.rstrip(),
            f"{pad}}}",
        ]
    )


def generate() -> str:
    """Build USDA with joint-friendly nesting for skeletal mid-LOD."""
    # Filament chain (local offsets relative to parent) — A3 multi-seg for clips.
    filament_inner = "\n".join(
        [
            sphere(
                "FilamentBase",
                0.048,
                FILAMENT,
                (0.0, 0.0, -0.12),
                (0.85, 0.85, 1.1),
                indent=12,
            ),
            sphere(
                "FilamentMid",
                0.042,
                FILAMENT,
                (0.0, 0.0, -0.28),
                (0.75, 0.75, 1.15),
                indent=12,
            ),
            sphere(
                "FilamentTip",
                0.036,
                FRINGE,
                (0.0, 0.0, -0.42),
                (0.7, 0.7, 1.2),
                indent=12,
            ),
        ]
    )

    # Head local detail (snout child of Head joint)
    head_children = "\n" + sphere(
        "Snout",
        0.045,
        BODY_SEC,
        (0.0, -0.02, 0.12),
        (0.55, 0.45, 1.25),
        indent=12,
    )

    parts = [
        '#usda 1.0',
        '(',
        '    defaultPrim = "LiraRoot"',
        '    metersPerUnit = 1',
        '    upAxis = "Y"',
        '    doc = """Waykin Lira AR mid-LOD v1.2 GENERATED_MID_LOD (procedural prim hierarchy).',
        'Evidence class: GENERATED_MID_LOD — not hand-sculpted artist mesh.',
        'A1 Head+Snout, A2 CoreGlow, A3 FilamentBase/Mid/Tip joints. Soft asymmetry; spectral not mascot.',
        'Canonical height ~0.72m. Nested joints for LiraSkeletalPlayer. Procedural RealityKit factory remains fallback."""',
        ')',
        '',
        'def Xform "LiraRoot" (',
        '    kind = "component"',
        ')',
        '{',
        sphere("GroundShadow", 0.18, SHADOW, (0.01, 0.0, 0.02), (1.35, 0.012, 0.92), indent=4),
        '',
        '    # Body mass + climate (sibling joints for skeletal bind paths)',
        sphere("Body", 0.15, BODY, (0.008, 0.29, 0.03), (0.68, 1.52, 1.12), indent=4),
        sphere("Haunch", 0.10, BODY_SEC, (-0.02, 0.22, -0.12), (0.88, 1.02, 1.18), indent=4),
        sphere("Chest", 0.11, BODY_SEC, (0.01, 0.34, 0.13), (0.98, 0.82, 0.95), indent=4),
        '',
        '    # A1 Head joint (tapered non-canid) + local Snout',
        sphere(
            "Head",
            0.11,
            BODY,
            (0.012, 0.59, 0.20),
            (0.48, 0.68, 1.72),
            indent=4,
            children=head_children,
        ),
        '',
        '    # Sensor blades (asymmetric) — skeletal ear joints',
        sphere("LeftEar", 0.065, BODY_SEC, (-0.062, 0.72, 0.11), (0.32, 1.55, 0.48), indent=4),
        sphere("RightEar", 0.065, BODY_SEC, (0.068, 0.705, 0.095), (0.30, 1.42, 0.52), indent=4),
        '',
        sphere("Tail", 0.09, FRINGE, (-0.015, 0.25, -0.28), (0.38, 0.48, 1.65), indent=4),
        '',
        '    # A3 Filament joint chain (Base/Mid/Tip nested for multi-seg clips)',
        sphere(
            "Filament",
            0.052,
            FILAMENT,
            (0.04, 0.35, -0.38),
            (0.32, 0.32, 1.4),
            indent=4,
            children="\n" + filament_inner,
        ),
        '',
        '    # A2 bond ember + halo (skeletal CoreGlow target)',
        sphere("CoreGlow", 0.044, BOND, (0.01, 0.34, 0.19), None, indent=4),
        sphere("CoreHalo", 0.058, BOND, (0.01, 0.34, 0.19), (1.18, 1.18, 1.18), indent=4),
        '',
        sphere("StatusIndicator", 0.02, STATUS, (0.02, 0.82, 0.12), None, indent=4),
        '',
        '    # Hunter pressure ghost (present for hierarchy; presentation toggles visibility)',
        sphere("HunterEcho", 0.14, HUNTER, (0.05, 0.28, -0.09), (0.70, 1.32, 0.98), indent=4),
        '}',
        '',
    ]
    return "\n".join(parts) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    text = generate()
    # Sanity: required node names appear as named prims.
    required = [
        "LiraRoot",
        "Body",
        "Head",
        "LeftEar",
        "RightEar",
        "Tail",
        "Filament",
        "FilamentBase",
        "FilamentMid",
        "FilamentTip",
        "CoreGlow",
        "GroundShadow",
        "StatusIndicator",
    ]
    for name in required:
        token = f'"{name}"'
        if token not in text:
            raise SystemExit(f"generator missing required name {name}")
    args.out.write_text(text, encoding="utf-8")
    print(f"wrote {args.out}")
    print(f"evidence_class=GENERATED_MID_LOD nodes={len(required)}")


if __name__ == "__main__":
    main()
