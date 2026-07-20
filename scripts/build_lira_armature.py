#!/usr/bin/env python3
"""
Build a mid-LOD armature on the multi-mesh Lira artist blend.

Evidence class target: ARTIST_BLEND_ARMATURE_MID_LOD
  - Real Blender Armature + bone hierarchy matching runtime joint names
  - Multi-part mesh bone-parented (rigid bind) — not merged heat-map skin weights
  - Compatible with existing LiraSkeletalRig / puppet AnimationBindTarget.entity paths

Invoked by export_lira_blend_to_usdz.py (optional step) or standalone:
  blender --background ArtSource/Companion/Lira/lira.blend --python scripts/build_lira_armature.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]

# Runtime joint names (post-rename). Bones use the same names.
# parent_bone → list of bones that hang under it (edit-mode creation order).
BONE_TREE: list[tuple[str, str | None]] = [
    ("Root", None),
    ("Body", "Root"),
    ("Chest", "Body"),
    ("CoreGlow", "Chest"),
    ("CoreHalo", "Chest"),
    ("Neck", "Chest"),
    ("Head", "Neck"),
    ("LeftEar", "Head"),
    ("RightEar", "Head"),
    ("Snout", "Head"),
    ("StatusIndicator", "Head"),
    ("Tail", "Body"),
    ("Filament", "Body"),
    ("FilamentBase", "Filament"),
    ("FilamentMid", "FilamentBase"),
    ("FilamentTip", "FilamentMid"),
    ("LegFrontL", "Body"),
    ("LegFrontR", "Body"),
    ("LegHindL", "Body"),
    ("LegHindR", "Body"),
    ("PawFrontL", "LegFrontL"),
    ("PawFrontR", "LegFrontR"),
    ("PawHindL", "LegHindL"),
    ("PawHindR", "LegHindR"),
    ("GroundShadow", "Root"),
]

# Mesh / empty object name → bone to parent onto (after runtime rename).
MESH_TO_BONE: dict[str, str] = {
    "Body": "Body",
    "Chest": "Chest",
    "Neck": "Neck",
    "Head": "Head",
    "LeftEar": "LeftEar",
    "RightEar": "RightEar",
    "Snout": "Snout",
    "CoreGlow": "CoreGlow",
    "CoreHalo": "CoreHalo",
    "Tail": "Tail",
    "Filament": "Filament",
    "FilamentBase": "FilamentBase",
    "FilamentMid": "FilamentMid",
    "FilamentTip": "FilamentTip",
    "GroundShadow": "GroundShadow",
    "StatusIndicator": "StatusIndicator",
    # Artist extras (optional)
    "Lira_Eye.L": "Head",
    "Lira_Eye.R": "Head",
    "Lira_InnerEar.L": "LeftEar",
    "Lira_InnerEar.R": "RightEar",
    "Lira_Nose": "Snout",
    "Lira_ForeheadGlow": "Head",
    "Lira_TempleMark.L": "Head",
    "Lira_TempleMark.R": "Head",
    "Lira_Leg.Front.L": "LegFrontL",
    "Lira_Leg.Front.R": "LegFrontR",
    "Lira_Leg.Hind.L": "LegHindL",
    "Lira_Leg.Hind.R": "LegHindR",
    "Lira_Paw.Front.L": "PawFrontL",
    "Lira_Paw.Front.R": "PawFrontR",
    "Lira_Paw.Hind.L": "PawHindL",
    "Lira_Paw.Hind.R": "PawHindR",
    # After rename of legs/paws if export renames them later
    "LegFrontL": "LegFrontL",
    "LegFrontR": "LegFrontR",
    "LegHindL": "LegHindL",
    "LegHindR": "LegHindR",
    "PawFrontL": "PawFrontL",
    "PawFrontR": "PawFrontR",
    "PawHindL": "PawHindL",
    "PawHindR": "PawHindR",
}

ARMATURE_NAME = "LiraArmature"


def log(msg: str) -> None:
    print(f"[build_armature] {msg}")


def world_center(obj: bpy.types.Object) -> Vector:
    if obj.type in {"MESH", "CURVE"} and obj.bound_box:
        corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
        return sum(corners, Vector()) / 8.0
    return obj.matrix_world.translation.copy()


def world_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    if obj.type not in {"MESH", "CURVE"} or not obj.bound_box:
        t = obj.matrix_world.translation
        return t.copy(), t.copy()
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    xs = [c.x for c in corners]
    ys = [c.y for c in corners]
    zs = [c.z for c in corners]
    return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))


def resolve_anchor(name: str) -> Vector | None:
    """World position for a joint from existing object or fallback."""
    o = bpy.data.objects.get(name)
    if o is not None:
        return world_center(o)
    # Artist names before rename
    artist = {
        "Body": "Lira_Body",
        "Head": "Lira_Head",
        "LeftEar": "Lira_Ear.L",
        "RightEar": "Lira_Ear.R",
        "Tail": "Lira_Tail",
        "Filament": "Lira_Tail",
        "FilamentTip": "Lira_TailTip",
        "CoreGlow": "Lira_ChestGlow",
        "CoreHalo": "Lira_ChestGlow",
        "GroundShadow": "Lira_GroundLocator",
        "Snout": "Lira_Muzzle",
        "Chest": "Lira_Chest",
        "Neck": "Lira_Neck",
        "LegFrontL": "Lira_Leg.Front.L",
        "LegFrontR": "Lira_Leg.Front.R",
        "LegHindL": "Lira_Leg.Hind.L",
        "LegHindR": "Lira_Leg.Hind.R",
        "PawFrontL": "Lira_Paw.Front.L",
        "PawFrontR": "Lira_Paw.Front.R",
        "PawHindL": "Lira_Paw.Hind.L",
        "PawHindR": "Lira_Paw.Hind.R",
    }.get(name)
    if artist:
        o = bpy.data.objects.get(artist)
        if o is not None:
            return world_center(o)
    return None


def ensure_edit_mode(arm_obj: bpy.types.Object) -> None:
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="EDIT")


def remove_existing_armature() -> None:
    for o in list(bpy.data.objects):
        if o.type == "ARMATURE" and o.name in {ARMATURE_NAME, "LiraArmature", "Armature"}:
            log(f"remove existing armature object {o.name}")
            bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.armatures):
        if a.name in {ARMATURE_NAME, "LiraArmature", "Armature"}:
            bpy.data.armatures.remove(a)


def create_armature() -> bpy.types.Object:
    remove_existing_armature()
    arm_data = bpy.data.armatures.new(ARMATURE_NAME)
    arm_obj = bpy.data.objects.new(ARMATURE_NAME, arm_data)
    bpy.context.scene.collection.objects.link(arm_obj)
    arm_obj.show_in_front = True

    # Collect anchors
    anchors: dict[str, Vector] = {}
    for bone_name, _parent in BONE_TREE:
        p = resolve_anchor(bone_name)
        if p is None:
            # hierarchical fallbacks
            if bone_name == "Root":
                p = Vector((0.0, 0.0, 0.0))
            elif bone_name == "StatusIndicator":
                h = anchors.get("Head") or Vector((0, -0.8, 2.0))
                p = h + Vector((0.0, -0.05, 0.35))
            elif bone_name == "CoreHalo":
                p = anchors.get("CoreGlow") or Vector((0, -0.9, 1.5))
            elif bone_name.startswith("Filament"):
                base = anchors.get("Filament") or anchors.get("Tail") or Vector((0.2, 1.3, 1.7))
                tip = anchors.get("FilamentTip") or (base + Vector((0, 0.2, 0.3)))
                t = {
                    "Filament": 0.0,
                    "FilamentBase": 0.25,
                    "FilamentMid": 0.55,
                    "FilamentTip": 1.0,
                }.get(bone_name, 0.0)
                p = base.lerp(tip, t)
            else:
                p = anchors.get("Body") or Vector((0, 0.1, 1.2))
        anchors[bone_name] = p

    ensure_edit_mode(arm_obj)
    edit = arm_data.edit_bones

    # Bone length: short segment toward child or along +Z (Blender Z-up in this file)
    for bone_name, parent_name in BONE_TREE:
        head = anchors[bone_name]
        # default tail: small +Z offset for visibility / orientation
        tail = head + Vector((0.0, 0.0, 0.12))
        # Aim toward a preferred child if present
        child_prefs = {
            "Root": "Body",
            "Body": "Chest",
            "Chest": "Neck",
            "Neck": "Head",
            "Head": "Snout",
            "Filament": "FilamentBase",
            "FilamentBase": "FilamentMid",
            "FilamentMid": "FilamentTip",
            "LegFrontL": "PawFrontL",
            "LegFrontR": "PawFrontR",
            "LegHindL": "PawHindL",
            "LegHindR": "PawHindR",
        }
        child = child_prefs.get(bone_name)
        if child and child in anchors:
            direction = anchors[child] - head
            if direction.length > 1e-4:
                tail = head + direction.normalized() * max(0.08, min(direction.length * 0.45, 0.45))
        if (tail - head).length < 0.05:
            tail = head + Vector((0.0, 0.0, 0.1))

        eb = edit.new(bone_name)
        eb.head = head
        eb.tail = tail
        if parent_name:
            eb.parent = edit[parent_name]
            eb.use_connect = False

    bpy.ops.object.mode_set(mode="OBJECT")
    log(f"created armature {ARMATURE_NAME} with {len(BONE_TREE)} bones")
    return arm_obj


def ensure_filament_segment_meshes() -> None:
    """Create small FilamentBase / FilamentMid markers if missing (for multi-seg clips)."""
    fil = bpy.data.objects.get("Filament") or bpy.data.objects.get("Lira_Tail")
    tip = bpy.data.objects.get("FilamentTip") or bpy.data.objects.get("Lira_TailTip")
    if fil is None:
        return
    base_c = world_center(fil)
    tip_c = world_center(tip) if tip else base_c + Vector((0, 0.3, 0.2))

    def make_marker(name: str, loc: Vector, radius: float = 0.04) -> None:
        if name in bpy.data.objects:
            return
        bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc)
        o = bpy.context.active_object
        o.name = name
        log(f"created joint marker {name}")

    make_marker("FilamentBase", base_c.lerp(tip_c, 0.25), 0.035)
    make_marker("FilamentMid", base_c.lerp(tip_c, 0.55), 0.032)
    # FilamentTip already maps from artist TailTip after rename


def bone_parent(obj: bpy.types.Object, arm_obj: bpy.types.Object, bone_name: str) -> None:
    """Parent object to armature bone, preserving world transform."""
    if bone_name not in arm_obj.data.bones:
        log(f"WARN no bone {bone_name} for {obj.name}")
        return
    mw = obj.matrix_world.copy()
    obj.parent = arm_obj
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    # Restore world matrix after bone parenting
    obj.matrix_world = mw
    log(f"bone-parent {obj.name} → {bone_name}")


def parent_meshes_to_bones(arm_obj: bpy.types.Object) -> None:
    # Prefer runtime names; also accept artist names via MESH_TO_BONE keys
    for obj_name, bone_name in MESH_TO_BONE.items():
        o = bpy.data.objects.get(obj_name)
        if o is None or o.type == "ARMATURE":
            continue
        bone_parent(o, arm_obj, bone_name)

    # Parent remaining Lira_* artist parts under Body if unparented
    for o in list(bpy.data.objects):
        if o == arm_obj or o.type == "ARMATURE":
            continue
        if o.parent is None and (o.name.startswith("Lira_") or o.name in MESH_TO_BONE):
            bone_parent(o, arm_obj, "Body")


def parent_armature_under_root() -> None:
    root = bpy.data.objects.get("LiraRoot") or bpy.data.objects.get("Lira_ROOT")
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if root is None or arm is None:
        return
    if arm.parent != root:
        mw = arm.matrix_world.copy()
        arm.parent = root
        arm.matrix_world = mw
        log(f"parented {ARMATURE_NAME} under {root.name}")


def validate_armature() -> None:
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if arm is None or arm.type != "ARMATURE":
        raise SystemExit("armature missing after build")
    bones = {b.name for b in arm.data.bones}
    required = {
        "Root",
        "Body",
        "Head",
        "LeftEar",
        "RightEar",
        "Tail",
        "Filament",
        "FilamentTip",
        "CoreGlow",
        "GroundShadow",
    }
    missing = sorted(required - bones)
    if missing:
        raise SystemExit(f"armature missing bones: {missing}")
    log(f"armature OK bones={len(bones)} required_present")


def build() -> bpy.types.Object:
    ensure_filament_segment_meshes()
    arm = create_armature()
    parent_meshes_to_bones(arm)
    parent_armature_under_root()
    validate_armature()
    return arm


def main() -> None:
    # When run as blender --python, file is already open.
    # Optional CLI path after --
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
        if argv:
            path = Path(argv[0])
            if path.is_file():
                bpy.ops.wm.open_mainfile(filepath=str(path))
                log(f"open {path}")
    build()
    # Optional save path as second arg
    if len(argv) > 1:
        out = Path(argv[1])
        out.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out))
        log(f"saved {out}")


if __name__ == "__main__":
    main()
