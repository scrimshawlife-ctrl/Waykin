#!/usr/bin/env python3
"""
Export Desktop/repo lira.blend → runtime Lira_AR_Base.usdz with Waykin node names.

Evidence class: ARTIST_BLEND_MID_LOD (hand-authored Blender; not DCC skinned weights).

Requires: Blender 3+ with USD export (wm.usd_export).
Invoked by: scripts/export_lira_blend_to_usdz.sh
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

# --- CLI: blender --background blend --python this.py -- [args] ---
argv = sys.argv
if "--" in argv:
    argv = argv[argv.index("--") + 1 :]
else:
    argv = []

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BLEND = Path.home() / "Desktop" / "lira.blend"
BLEND = Path(argv[0]) if argv else DEFAULT_BLEND
OUT_DIR = ROOT / "docs/assets/companion/ar/artist"
APP_USDZ = ROOT / "App/Resources/Lira_AR_Base.usdz"
NESTED_USDZ = ROOT / "App/Resources/Companion/Lira/Lira_AR_Base.usdz"
DOC_USDZ = ROOT / "docs/assets/companion/ar/Lira_AR_Base.usdz"
ARTSOURCE = ROOT / "ArtSource/Companion/Lira"

# Blend object name → runtime semantic name
RENAME = {
    "Lira_ROOT": "LiraRoot",
    "Lira_Body": "Body",
    "Lira_Head": "Head",
    "Lira_Ear.L": "LeftEar",
    "Lira_Ear.R": "RightEar",
    "Lira_Tail": "Filament",  # long spectral trail = A3 filament
    "Lira_TailTip": "FilamentTip",
    "Lira_ChestGlow": "CoreGlow",
    "Lira_GroundLocator": "GroundShadow",
    "Lira_Muzzle": "Snout",
    "Lira_Chest": "Chest",
    "Lira_Neck": "Neck",
}

TARGET_HEIGHT_M = 0.72
REQUIRED = [
    "Body",
    "Head",
    "LeftEar",
    "RightEar",
    "Tail",
    "Filament",
    "CoreGlow",
    "GroundShadow",
    "StatusIndicator",
]


def log(msg: str) -> None:
    print(f"[export_lira] {msg}")


def convert_curves_to_mesh() -> None:
    curves = [o for o in bpy.data.objects if o.type == "CURVE"]
    for o in curves:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        try:
            bpy.ops.object.convert(target="MESH")
            log(f"converted curve → mesh: {o.name}")
        except Exception as e:
            log(f"WARN convert failed {o.name}: {e}")


def world_bounds(objects: list) -> tuple[Vector, Vector]:
    mins = Vector((1e9, 1e9, 1e9))
    maxs = Vector((-1e9, -1e9, -1e9))
    for o in objects:
        if o.type not in {"MESH", "EMPTY"}:
            continue
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            mins.x = min(mins.x, w.x)
            mins.y = min(mins.y, w.y)
            mins.z = min(mins.z, w.z)
            maxs.x = max(maxs.x, w.x)
            maxs.y = max(maxs.y, w.y)
            maxs.z = max(maxs.z, w.z)
    return mins, maxs


def ensure_root() -> bpy.types.Object:
    root = bpy.data.objects.get("Lira_ROOT") or bpy.data.objects.get("LiraRoot")
    if root is None:
        root = bpy.data.objects.new("LiraRoot", None)
        bpy.context.scene.collection.objects.link(root)
    root.name = "LiraRoot"
    return root


def rename_objects() -> None:
    for o in list(bpy.data.objects):
        if o.name in RENAME:
            new = RENAME[o.name]
            log(f"rename {o.name} → {new}")
            o.name = new


def reparent_under_root(root: bpy.types.Object) -> None:
    for o in list(bpy.data.objects):
        if o == root:
            continue
        if o.name.startswith("Lira_") or o.name in REQUIRED or o.name in {
            "Snout",
            "Chest",
            "Neck",
            "FilamentTip",
            "CoreHalo",
            "HunterEcho",
            "StatusIndicator",
            "Tail",
            "CoreGlow",
            "GroundShadow",
            "Body",
            "Head",
            "LeftEar",
            "RightEar",
            "Filament",
        }:
            # Keep world transform when reparenting
            mw = o.matrix_world.copy()
            o.parent = root
            o.matrix_world = mw


def _ensure_mesh_visible(obj: bpy.types.Object) -> None:
    """USD export with evaluation_mode=RENDER skips hide_render objects."""
    obj.hide_set(False)
    obj.hide_viewport = False
    obj.hide_render = False
    if hasattr(obj, "hide_get"):
        try:
            obj.hide_set(False)
        except Exception:
            pass


def create_missing_required(root: bpy.types.Object) -> None:
    """Ensure required semantic nodes exist (blend maps trail→Filament)."""
    if "Tail" not in bpy.data.objects:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.04, location=(0.0, 0.15, 0.28))
        tail = bpy.context.active_object
        tail.name = "Tail"
        tail.parent = root
        tail.scale = (0.4, 0.5, 1.2)
        log("created Tail placeholder")

    if "StatusIndicator" not in bpy.data.objects:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.025, location=(0.0, -0.05, 0.78))
        ind = bpy.context.active_object
        ind.name = "StatusIndicator"
        ind.parent = root
        log("created StatusIndicator")

    if "GroundShadow" not in bpy.data.objects:
        # Thin disc under feet — EMPTY locators do not always survive USD export.
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.18, depth=0.008, location=(0.0, 0.0, 0.004)
        )
        shadow = bpy.context.active_object
        shadow.name = "GroundShadow"
        shadow.parent = root
        log("created GroundShadow disc")

    # Convert EMPTY GroundShadow (artist locator) to mesh so USD keeps the prim.
    gs = bpy.data.objects.get("GroundShadow")
    if gs is not None and gs.type != "MESH":
        loc = gs.matrix_world.to_translation().copy()
        bpy.data.objects.remove(gs, do_unlink=True)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.008, location=loc)
        shadow = bpy.context.active_object
        shadow.name = "GroundShadow"
        shadow.parent = root
        log("replaced EMPTY GroundShadow with disc mesh")

    if "CoreHalo" not in bpy.data.objects and "CoreGlow" in bpy.data.objects:
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.05, location=bpy.data.objects["CoreGlow"].location
        )
        halo = bpy.context.active_object
        halo.name = "CoreHalo"
        halo.parent = root
        halo.scale = (1.2, 1.2, 1.2)
        log("created CoreHalo")

    # Nest FilamentTip under Filament if both exist
    fil = bpy.data.objects.get("Filament")
    tip = bpy.data.objects.get("FilamentTip")
    if fil and tip and tip.parent != fil:
        mw = tip.matrix_world.copy()
        tip.parent = fil
        tip.matrix_world = mw
        log("parented FilamentTip under Filament")

    # Unhide required + joint nodes so RENDER evaluation includes them.
    for name in REQUIRED + ["FilamentTip", "FilamentMid", "FilamentBase", "CoreHalo", "Snout"]:
        o = bpy.data.objects.get(name)
        if o is not None:
            _ensure_mesh_visible(o)


def scale_to_canonical_height(root: bpy.types.Object) -> None:
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    mins, maxs = world_bounds(meshes)
    height = max(maxs.z - mins.z, 1e-6)
    # Prefer Z as up in this blend; also consider max of Y/Z
    height = max(maxs.z - mins.z, maxs.y - mins.y, 1e-6)
    scale = TARGET_HEIGHT_M / height
    log(f"bounds height≈{height:.4f} → scale {scale:.4f} for {TARGET_HEIGHT_M}m")
    root.scale = (scale, scale, scale)
    # Apply scale on root children for clean export
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    bpy.context.view_layer.objects.active = root
    # Apply scale only on root via transform apply to hierarchy
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def export_usd(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    # Select full hierarchy; force required nodes unhidden for RENDER eval.
    bpy.ops.object.select_all(action="DESELECT")
    root = bpy.data.objects["LiraRoot"]
    root.select_set(True)
    for o in bpy.data.objects:
        if o.parent is not None or o == root:
            _ensure_mesh_visible(o)
            o.select_set(True)
    bpy.context.view_layer.objects.active = root

    # Blender 5 USD export RNA (no visible_objects_only / export_textures flags)
    try:
        bpy.ops.wm.usd_export(
            filepath=str(path),
            check_existing=False,
            selected_objects_only=True,
            export_animation=False,
            export_hair=False,
            export_uvmaps=True,
            export_normals=True,
            export_materials=True,
            use_instancing=False,
            evaluation_mode="RENDER",
            generate_preview_surface=True,
            convert_orientation=True,
            relative_paths=True,
            root_prim_path="/LiraRoot",
            export_armatures=True,
            convert_scene_units="METERS",
            meters_per_unit=1.0,
        )
    except Exception as e:
        raise SystemExit(f"usd_export failed: {e}") from e
    log(f"exported {path}")


def validate_names() -> None:
    names = {o.name for o in bpy.data.objects}
    missing = [n for n in REQUIRED if n not in names]
    if missing:
        raise SystemExit(f"missing required objects after export prep: {missing}")
    log(f"required nodes present: {REQUIRED}")


def main() -> None:
    if not BLEND.is_file():
        raise SystemExit(f"blend not found: {BLEND}")

    log(f"open {BLEND}")
    bpy.ops.wm.open_mainfile(filepath=str(BLEND))

    convert_curves_to_mesh()
    root = ensure_root()
    rename_objects()
    reparent_under_root(root)
    create_missing_required(root)
    scale_to_canonical_height(root)
    validate_names()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    usd_path = OUT_DIR / "Lira_AR_Base.usd"
    export_usd(usd_path)

    # Also save a prepared blend into ArtSource for provenance
    ARTSOURCE.mkdir(parents=True, exist_ok=True)
    prepared = ARTSOURCE / "Lira_AR_Base_prepared.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(prepared))
    log(f"saved prepared blend {prepared}")

    # Write marker for shell packaging
    marker = OUT_DIR / "EXPORT_OK"
    marker.write_text(f"usd={usd_path}\nblend={BLEND}\nevidence=ARTIST_BLEND_MID_LOD\n", encoding="utf-8")
    log("done")


if __name__ == "__main__":
    main()
