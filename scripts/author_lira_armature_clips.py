#!/usr/bin/env python3
"""
Author DCC action clips on LiraArmature (full presentation set).

Clips (Blender actions → USD animation when LIRA_EXPORT_ANIM=1 / default export):
  Lira_Idle, Lira_Follow, Lira_Investigate, Lira_Alert, Lira_Celebrate, Lira_Spawn

Runtime maps these names into LiraSkeletalPlayer DCC library when present on the
loaded USDZ; otherwise puppet entity clips remain fallback.

Usage:
  blender --background prepared.blend --python scripts/author_lira_armature_clips.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy
from mathutils import Euler

ARMATURE_NAME = "LiraArmature"
FPS = 24

# Clip name → list of (frame, {bone: (rx, ry, rz) radians})
CLIPS: dict[str, list[tuple[int, dict[str, tuple[float, float, float]]]]] = {
    "Lira_Idle": [
        (1, {}),
        (24, {"Head": (0.03, 0.05, 0.0), "Filament": (0.07, 0.03, 0.0), "Tail": (0.04, 0.0, 0.0)}),
        (48, {"Head": (0.0, -0.04, 0.0), "Filament": (-0.05, -0.02, 0.0), "Tail": (-0.03, 0.02, 0.0)}),
    ],
    "Lira_Follow": [
        (1, {"Head": (0.0, 0.06, 0.0)}),
        (24, {"Head": (0.04, 0.14, 0.0), "Filament": (0.1, -0.05, 0.0), "Tail": (0.08, 0.0, 0.0), "Body": (0.0, 0.0, 0.02)}),
        (48, {"Head": (0.02, 0.08, 0.0), "Filament": (0.05, 0.04, 0.0), "Tail": (0.03, -0.02, 0.0)}),
    ],
    "Lira_Investigate": [
        (1, {"Head": (-0.12, -0.1, 0.0)}),
        (24, {"Head": (-0.18, -0.2, 0.05), "Filament": (0.06, 0.05, 0.0), "LeftEar": (0.05, 0.0, 0.04)}),
        (48, {"Head": (-0.14, -0.14, 0.0), "Filament": (0.04, 0.02, 0.0)}),
    ],
    "Lira_Alert": [
        (1, {"Head": (0.02, 0.04, 0.0)}),
        (12, {"LeftEar": (0.08, 0.0, 0.1), "RightEar": (0.08, 0.0, -0.1), "Filament": (0.14, 0.06, 0.0), "Body": (0.0, 0.0, -0.02)}),
        (24, {"LeftEar": (0.04, 0.0, 0.05), "RightEar": (0.04, 0.0, -0.05), "Filament": (0.09, -0.04, 0.0)}),
        (48, {"Head": (0.02, 0.06, 0.0), "Filament": (0.06, 0.02, 0.0)}),
    ],
    "Lira_Celebrate": [
        (1, {"Head": (0.0, 0.0, 0.0), "Tail": (0.0, 0.0, 0.0)}),
        (12, {"Head": (-0.05, 0.16, 0.0), "Tail": (0.14, 0.08, 0.0), "Filament": (0.1, 0.08, 0.0)}),
        (24, {"Head": (0.0, -0.12, 0.0), "Tail": (0.1, -0.06, 0.0)}),
        (36, {"Head": (-0.04, 0.1, 0.0), "Tail": (0.12, 0.04, 0.0)}),
    ],
    "Lira_Spawn": [
        (1, {"Body": (0.0, 0.0, 0.0), "Head": (0.1, 0.0, 0.0)}),
        (12, {"Body": (0.0, 0.0, 0.0), "Head": (0.04, 0.0, 0.0), "Filament": (0.05, 0.0, 0.0)}),
        (24, {}),
    ],
}


def log(msg: str) -> None:
    print(f"[author_clips] {msg}")


def ensure_pose_mode(arm: bpy.types.Object) -> None:
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")


def clear_lira_actions() -> None:
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


def make_action(
    arm: bpy.types.Object,
    name: str,
    frames: list[tuple[int, dict[str, tuple[float, float, float]]]],
) -> None:
    action = bpy.data.actions.new(name=name)
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = action
    ensure_pose_mode(arm)
    # Rest at frame 1 baseline for all pose bones
    for b in arm.pose.bones:
        b.rotation_mode = "XYZ"
        b.rotation_euler = (0, 0, 0)
        b.keyframe_insert(data_path="rotation_euler", frame=1)
    for frame, bones in frames:
        # Reset unspecified bones to rest at this frame for clean loops
        for b in arm.pose.bones:
            if b.name not in bones:
                b.rotation_mode = "XYZ"
                b.rotation_euler = (0, 0, 0)
                b.keyframe_insert(data_path="rotation_euler", frame=frame)
        for bone_name, eul in bones.items():
            key_bone(arm, bone_name, frame, eul)
    # Mark fake user so action survives
    action.use_fake_user = True
    end = action_end_frame(action)
    log(f"action {name} keys={len(frames)} end_frame={end}")


def action_end_frame(action: bpy.types.Action) -> int:
    """Blender 5 actions no longer expose .fcurves on Action; use frame_range."""
    try:
        fr = action.frame_range
        return max(2, int(fr[1]))
    except Exception:
        return 48


def push_nla(arm: bpy.types.Object) -> None:
    """Stack actions on NLA so USD export can see multiple clips."""
    if arm.animation_data is None:
        arm.animation_data_create()
    ad = arm.animation_data
    # Clear old tracks
    while ad.nla_tracks:
        ad.nla_tracks.remove(ad.nla_tracks[0])
    start = 1
    for name in CLIPS:
        action = bpy.data.actions.get(name)
        if action is None:
            continue
        track = ad.nla_tracks.new()
        track.name = name
        end = action_end_frame(action)
        try:
            strip = track.strips.new(name, int(start), action)
        except TypeError:
            # Blender version variance: (name, start, action) vs keyword forms
            strip = track.strips.new(name, int(start), action)
        strip.action = action
        try:
            strip.frame_end = float(strip.frame_start) + float(max(1, end - 1))
        except Exception:
            pass
        log(f"nla track {name} start={start} end≈{end}")
        start = int(start) + int(end) + 2
    # Active action = idle for default
    ad.action = bpy.data.actions.get("Lira_Idle")


def author() -> list[str]:
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if arm is None or arm.type != "ARMATURE":
        raise SystemExit(f"missing {ARMATURE_NAME}")
    clear_lira_actions()
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = 1
    scene.frame_end = 48

    names: list[str] = []
    for name, frames in CLIPS.items():
        make_action(arm, name, frames)
        names.append(name)
    push_nla(arm)
    bpy.ops.object.mode_set(mode="OBJECT")
    log(f"authored {names}")
    return names


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
    names = author()
    if len(argv) > 1:
        out = Path(argv[1])
        out.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out))
        log(f"saved {out}")
    log(f"done clips={names}")


if __name__ == "__main__":
    main()
