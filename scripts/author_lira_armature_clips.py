#!/usr/bin/env python3
"""
Scaffold DCC action clips on LiraArmature (idle / alert / follow).

Evidence: ARTIST_BLEND_SKINNED_MID_LOD companion — optional DCC clip library.
Runtime still prefers puppet entity clips (`LiraSkeletalAnimationLibrary`); these
Blender actions enable future export_animation=True packages and DCC authoring.

Usage (after prepared blend exists):
  blender --background ArtSource/Companion/Lira/Lira_AR_Base_prepared.blend \\
    --python scripts/author_lira_armature_clips.py -- \\
    ArtSource/Companion/Lira/Lira_AR_Base_prepared.blend \\
    ArtSource/Companion/Lira/Lira_AR_Base_with_clips.blend

Export with animation (optional env):
  LIRA_EXPORT_ANIM=1 ./scripts/export_lira_blend_to_usdz.sh ...
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy
from mathutils import Euler

ARMATURE_NAME = "LiraArmature"
FPS = 24


def log(msg: str) -> None:
    print(f"[author_clips] {msg}")


def ensure_pose_mode(arm: bpy.types.Object) -> None:
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")


def clear_actions() -> None:
    for action in list(bpy.data.actions):
        if action.name.startswith("Lira_"):
            bpy.data.actions.remove(action)


def key_bone(arm: bpy.types.Object, bone_name: str, frame: int, euler_xyz: tuple[float, float, float]) -> None:
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        return
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = Euler(euler_xyz, "XYZ")
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)


def make_action(arm: bpy.types.Object, name: str, frames: list[tuple[int, dict[str, tuple[float, float, float]]]]) -> None:
    """frames: list of (frame_number, {bone: (rx,ry,rz)})"""
    action = bpy.data.actions.new(name=name)
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    ensure_pose_mode(arm)
    # Rest pose first
    for b in arm.pose.bones:
        b.rotation_mode = "XYZ"
        b.rotation_euler = (0, 0, 0)
        b.keyframe_insert(data_path="rotation_euler", frame=1)
    for frame, bones in frames:
        for bone_name, eul in bones.items():
            key_bone(arm, bone_name, frame, eul)
    log(f"action {name} keys={len(frames)}")


def author() -> None:
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if arm is None or arm.type != "ARMATURE":
        raise SystemExit(f"missing {ARMATURE_NAME}")
    clear_actions()
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = 1
    scene.frame_end = 48

    # Idle: soft head + filament sway
    make_action(
        arm,
        "Lira_Idle",
        [
            (1, {}),
            (24, {"Head": (0.04, 0.06, 0.0), "Filament": (0.08, 0.03, 0.0), "CoreGlow": (0, 0, 0)}),
            (48, {"Head": (0.0, -0.04, 0.0), "Filament": (-0.05, -0.02, 0.0)}),
        ],
    )
    # Follow: stronger head yaw + filament lag
    make_action(
        arm,
        "Lira_Follow",
        [
            (1, {"Head": (0.0, 0.05, 0.0)}),
            (24, {"Head": (0.05, 0.14, 0.0), "Filament": (0.1, -0.05, 0.0), "Tail": (0.08, 0.0, 0.0)}),
            (48, {"Head": (0.02, 0.08, 0.0), "Filament": (0.04, 0.04, 0.0)}),
        ],
    )
    # Alert: ear tension + tighter filament
    make_action(
        arm,
        "Lira_Alert",
        [
            (1, {"Head": (0.02, 0.04, 0.0)}),
            (12, {"LeftEar": (0.1, 0.0, 0.08), "RightEar": (0.1, 0.0, -0.08), "Filament": (0.14, 0.06, 0.0)}),
            (24, {"LeftEar": (0.05, 0.0, 0.04), "RightEar": (0.05, 0.0, -0.04), "Filament": (0.08, -0.04, 0.0)}),
            (48, {"Head": (0.02, 0.06, 0.0)}),
        ],
    )
    # Default active idle for authoring preview
    arm.animation_data.action = bpy.data.actions.get("Lira_Idle")
    bpy.ops.object.mode_set(mode="OBJECT")
    log("authored Lira_Idle, Lira_Follow, Lira_Alert")


def main() -> None:
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []
    if argv:
        path = Path(argv[0])
        if path.is_file():
            bpy.ops.wm.open_mainfile(filepath=str(path))
            log(f"open {path}")
    author()
    if len(argv) > 1:
        out = Path(argv[1])
        out.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out))
        log(f"saved {out}")


if __name__ == "__main__":
    main()
