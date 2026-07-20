#!/usr/bin/env python3
"""
Heat-map skin Lira multi-mesh parts onto LiraArmature (mid-LOD).

Evidence class target: ARTIST_BLEND_SKINNED_MID_LOD

Strategy (runtime-safe):
  1. Merge torso organics Body+Chest+Neck → Body (one shell for smooth torso deform).
  2. Optional: merge Snout → Head (keep Head name for A1 / hierarchy contract).
  3. Automatic weights (ARMATURE_AUTO) on deformable meshes — heat-map vertex groups.
  4. Keep spectral FX rigid bone-parented: CoreGlow/Halo, Filament*, Tail, GroundShadow,
     StatusIndicator (puppet channels + readability).

Does NOT replace heat-map with artist paint; auto-weights are the shippable mid-LOD skin.

Invoked from export_lira_blend_to_usdz.py after armature build + scale.
Standalone:
  blender --background prepared.blend --python scripts/skin_lira_armature.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

ARMATURE_NAME = "LiraArmature"

# Meshes that receive heat-map weights (automatic).
SKIN_MESHES = [
    "Body",
    "Head",
    "LeftEar",
    "RightEar",
    "Snout",  # may be merged into Head first
    # Legs / paws — soft bind for walk-ish deform if present
    "Lira_Leg.Front.L",
    "Lira_Leg.Front.R",
    "Lira_Leg.Hind.L",
    "Lira_Leg.Hind.R",
    "Lira_Paw.Front.L",
    "Lira_Paw.Front.R",
    "Lira_Paw.Hind.L",
    "Lira_Paw.Hind.R",
    "Lira_InnerEar.L",
    "Lira_InnerEar.R",
    "Lira_Eye.L",
    "Lira_Eye.R",
    "Lira_Nose",
    "Lira_ForeheadGlow",
    "Lira_TempleMark.L",
    "Lira_TempleMark.R",
]

# Stay rigid bone-parent (no vertex weights) for FX + path anchors.
RIGID_KEEP = {
    "CoreGlow",
    "CoreHalo",
    "Filament",
    "FilamentBase",
    "FilamentMid",
    "FilamentTip",
    "Tail",
    "GroundShadow",
    "StatusIndicator",
}


def log(msg: str) -> None:
    print(f"[skin_armature] {msg}")


def object_mode() -> None:
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")


def clear_parent_keep_transform(obj: bpy.types.Object) -> None:
    object_mode()
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    # Blender 5: clear parent and keep transform
    try:
        bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    except Exception:
        mw = obj.matrix_world.copy()
        obj.parent = None
        obj.parent_type = "OBJECT"
        obj.parent_bone = ""
        obj.matrix_world = mw


def remove_modifiers(obj: bpy.types.Object, types: set[str] | None = None) -> None:
    for m in list(obj.modifiers):
        if types is None or m.type in types:
            obj.modifiers.remove(m)


def join_named(source_names: list[str], target_name: str) -> bpy.types.Object | None:
    """Join existing meshes into target_name (first existing becomes active base)."""
    object_mode()
    objs = [bpy.data.objects[n] for n in source_names if n in bpy.data.objects and bpy.data.objects[n].type == "MESH"]
    if not objs:
        return None
    if len(objs) == 1:
        objs[0].name = target_name
        log(f"single mesh rename → {target_name}")
        return objs[0]

    # Prefer an object already named target_name as base
    base = next((o for o in objs if o.name == target_name), objs[0])
    for o in objs:
        clear_parent_keep_transform(o)
        remove_modifiers(o, {"ARMATURE", "SUBSURF"})  # clean join; mid-LOD without heavy subsurf

    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()
    joined = bpy.context.active_object
    joined.name = target_name
    log(f"joined {[n for n in source_names if n != target_name]} → {target_name} verts={len(joined.data.vertices)}")
    return joined


def merge_torso_and_head() -> None:
    """Body+Chest+Neck → Body; Head+Snout → Head. Preserves required Head/Body names."""
    join_named(["Body", "Chest", "Neck"], "Body")
    # Snout into Head for continuous A1 shell (Head name preserved)
    if "Snout" in bpy.data.objects and "Head" in bpy.data.objects:
        join_named(["Head", "Snout"], "Head")
    # Optional nose into head if present
    if "Lira_Nose" in bpy.data.objects and "Head" in bpy.data.objects:
        join_named(["Head", "Lira_Nose"], "Head")


def ensure_rest_pose(arm: bpy.types.Object) -> None:
    arm.data.pose_position = "REST"


def skin_meshes_auto(arm: bpy.types.Object) -> list[str]:
    """Parent listed meshes to armature with automatic weights."""
    object_mode()
    ensure_rest_pose(arm)

    targets: list[bpy.types.Object] = []
    for name in SKIN_MESHES:
        o = bpy.data.objects.get(name)
        if o is None or o.type != "MESH":
            continue
        if name in RIGID_KEEP:
            continue
        targets.append(o)

    if not targets:
        raise SystemExit("no skin target meshes found")

    skinned: list[str] = []
    for o in targets:
        clear_parent_keep_transform(o)
        # Drop old armature mods / subsurf before auto-weight
        remove_modifiers(o, {"ARMATURE", "SUBSURF"})
        # Clear old vertex groups
        o.vertex_groups.clear()

    bpy.ops.object.select_all(action="DESELECT")
    for o in targets:
        o.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    for o in targets:
        # Confirm armature modifier + weights
        has_arm = any(m.type == "ARMATURE" for m in o.modifiers)
        vg = len(o.vertex_groups)
        if not has_arm or vg == 0:
            log(f"WARN skin incomplete for {o.name} arm_mod={has_arm} vgroups={vg}")
        else:
            log(f"skinned {o.name} vgroups={vg} verts={len(o.data.vertices)}")
            skinned.append(o.name)
    return skinned


def re_rigid_bind_fx(arm: bpy.types.Object) -> None:
    """Ensure FX meshes stay bone-parented (no weights)."""
    for name in RIGID_KEEP:
        o = bpy.data.objects.get(name)
        if o is None or o.type != "MESH":
            continue
        # Clear any accidental armature skin
        remove_modifiers(o, {"ARMATURE"})
        o.vertex_groups.clear()
        bone = name if name in arm.data.bones else "Body"
        if name.startswith("Filament") and name != "Filament":
            bone = name if name in arm.data.bones else "Filament"
        mw = o.matrix_world.copy()
        o.parent = arm
        o.parent_type = "BONE"
        o.parent_bone = bone if bone in arm.data.bones else "Body"
        o.matrix_world = mw
        log(f"rigid FX {o.name} → bone {o.parent_bone}")


def weight_stats(obj: bpy.types.Object) -> dict:
    """OBSERVED heat-map metrics for provenance."""
    mesh = obj.data
    multi = 0
    max_influences = 0
    for v in mesh.vertices:
        # count groups with nonzero weight
        weights = [g.weight for g in v.groups if g.weight > 1e-4]
        n = len(weights)
        if n > 1:
            multi += 1
        max_influences = max(max_influences, n)
    return {
        "verts": len(mesh.vertices),
        "vgroups": len(obj.vertex_groups),
        "multi_bone_verts": multi,
        "max_influences": max_influences,
    }


def validate_skin() -> dict:
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if arm is None:
        raise SystemExit("LiraArmature missing")
    body = bpy.data.objects.get("Body")
    head = bpy.data.objects.get("Head")
    if body is None or head is None:
        raise SystemExit("Body/Head missing after skin merge")
    for o in (body, head):
        if not any(m.type == "ARMATURE" for m in o.modifiers):
            raise SystemExit(f"{o.name} missing Armature modifier")
        if len(o.vertex_groups) < 2:
            raise SystemExit(f"{o.name} expected multiple vertex groups, got {len(o.vertex_groups)}")
    stats = {"Body": weight_stats(body), "Head": weight_stats(head)}
    # Heat-map signal: at least some multi-bone verts on Body or Head
    if stats["Body"]["multi_bone_verts"] + stats["Head"]["multi_bone_verts"] < 1:
        log("WARN no multi-bone weighted verts detected (weights may be single-bone only)")
    log(f"skin stats {stats}")
    return stats


def skin() -> dict:
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if arm is None or arm.type != "ARMATURE":
        raise SystemExit("LiraArmature required before skinning — run build_lira_armature first")
    merge_torso_and_head()
    skinned = skin_meshes_auto(arm)
    re_rigid_bind_fx(arm)
    stats = validate_skin()
    stats["skinned_objects"] = skinned
    return stats


def main() -> None:
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
        if argv:
            path = Path(argv[0])
            if path.is_file():
                bpy.ops.wm.open_mainfile(filepath=str(path))
                log(f"open {path}")
    stats = skin()
    if len(argv) > 1:
        out = Path(argv[1])
        out.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out))
        log(f"saved {out}")
    log(f"done skinned={stats.get('skinned_objects')}")


if __name__ == "__main__":
    main()
