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

# Pose values are radians. A bone entry is either
#   (rx, ry, rz)                      rotation only
#   (rx, ry, rz, lx, ly, lz)          rotation + bone-local translation
#
# Amplitude note (#225 follow-up): the first pass moved 3-5 of 25 bones by
# under 10 degrees, which read as a static model on device. The rig ships
# legs, paws, neck, chest and a three-segment filament that were never keyed.
# These clips drive the whole rig at amplitudes that survive a phone screen in
# daylight; `scripts/measure_lira_motion.py` reports per-clip maxima.
#
# Leg convention: rotation X swings a limb forward (+) / back (-); paws
# counter-rotate about half as far so the foot stays readable on contact.

# Bone rotations are parent-local and compound down a chain, so four
# similar-looking local values silently become their sum. Authoring the crouch
# as Body .34 / Chest .24 / Neck .40 / Head .44 asked for a ~20 deg tip and
# produced 1.42 rad — 81 deg, a face-plant through the floor. Spine and
# filament poses are therefore authored as CUMULATIVE targets and converted to
# local deltas by `_chain`.
_SPINE = ("Body", "Chest", "Neck", "Head")            # Body→Chest→Neck→Head
_FILAMENT = ("Filament", "FilamentBase", "FilamentMid", "FilamentTip")


def _chain(names: tuple[str, ...], targets: tuple[float, ...]) -> dict[str, tuple[float, ...]]:
    """Cumulative X-pitch targets (radians) → parent-local rotations."""
    out: dict[str, tuple[float, ...]] = {}
    running = 0.0
    for name, target in zip(names, targets):
        out[name] = (target - running, 0.0, 0.0)
        running = target
    return out


def _spine(
    body: float, chest: float, neck: float, head: float,
    lift: float = 0.0, roll: float = 0.0, yaw: float = 0.0,
) -> dict[str, tuple[float, ...]]:
    """Spine pose from cumulative pitch. Positive noses down, negative lifts.

    `lift` raises the body along its own axis, `roll` banks it, and `yaw`
    turns the head — spread up the chain so the look reads as a head turn
    rather than a twisted torso.
    """
    out = _chain(_SPINE, (body, chest, neck, head))
    out["Body"] = (out["Body"][0], 0.0, roll, 0.0, lift, 0.0)
    out["Chest"] = (out["Chest"][0], yaw * 0.15, -roll * 0.5)
    out["Neck"] = (out["Neck"][0], yaw * 0.35, 0.0)
    out["Head"] = (out["Head"][0], yaw * 0.50, 0.0)
    return out


def _filament(
    root: float, base: float, mid: float, tip: float, yaw: float = 0.0,
) -> dict[str, tuple[float, ...]]:
    """Filament pose from cumulative pitch, with yaw growing toward the tip."""
    out = _chain(_FILAMENT, (root, base, mid, tip))
    for i, name in enumerate(_FILAMENT):
        out[name] = (out[name][0], yaw * (0.6 + 0.25 * i), 0.0)
    return out


# Quadruped diagonal gait: front-left travels with hind-right.
_SWING = 0.50   # ~29 deg leg swing
_PAW = 0.26     # ~15 deg paw counter-rotation
_BOB = 0.055    # body rise at mid-stride (bone-local units)


def _walk_pose(phase: str) -> dict[str, tuple[float, ...]]:
    """One key of the walk cycle.

    `contact_a`  front-left + hind-right reaching forward
    `pass_a`     legs under the body, weight high
    `contact_b`  mirrored reach
    `pass_b`     mirrored passing
    """
    if phase == "contact_a":
        fl, hr, fr, hl, bob, roll = _SWING, _SWING, -_SWING, -_SWING, 0.0, 0.035
    elif phase == "pass_a":
        fl, hr, fr, hl, bob, roll = 0.10, 0.10, 0.10, 0.10, _BOB, 0.0
    elif phase == "contact_b":
        fl, hr, fr, hl, bob, roll = -_SWING, -_SWING, _SWING, _SWING, 0.0, -0.035
    else:  # pass_b
        fl, hr, fr, hl, bob, roll = 0.10, 0.10, 0.10, 0.10, _BOB, 0.0
    forward = 1.0 if phase in {"contact_a", "pass_a"} else -1.0
    return {
        "LegFrontL": (fl, 0.0, 0.0),
        "PawFrontL": (-fl * (_PAW / _SWING), 0.0, 0.0),
        "LegHindR": (hr, 0.0, 0.0),
        "PawHindR": (-hr * (_PAW / _SWING), 0.0, 0.0),
        "LegFrontR": (fr, 0.0, 0.0),
        "PawFrontR": (-fr * (_PAW / _SWING), 0.0, 0.0),
        "LegHindL": (hl, 0.0, 0.0),
        "PawHindL": (-hl * (_PAW / _SWING), 0.0, 0.0),
        # Body rises between contacts and rolls gently into each stride; the
        # head stays level (cumulative ~0) so the walk reads as travel, not a
        # nod.
        **_spine(
            body=-0.05 + bob * 0.6, chest=-0.02, neck=-0.06, head=0.0,
            lift=bob, roll=roll, yaw=roll * 2.0,
        ),
        **_filament(0.18, 0.26, 0.32, 0.38, yaw=forward * 0.34),
        "Tail": (0.22, forward * 0.30, 0.0),
        "LeftEar": (0.10, 0.0, forward * 0.10),
        "RightEar": (0.10, 0.0, -forward * 0.10),
    }


# Clip name → list of (frame, {bone: pose})
CLIPS: dict[str, list[tuple[int, dict[str, tuple[float, ...]]]]] = {
    # Breathing, weight shift, slow tail and filament drift, ear flick.
    "Lira_Idle": [
        (1, {}),
        (
            12,
            {
                **_spine(-0.04, 0.01, -0.04, 0.02, lift=0.030, roll=0.02, yaw=0.18),
                **_filament(0.22, 0.34, 0.44, 0.52, yaw=0.22),
                "LeftEar": (0.16, 0.0, 0.10),
                "RightEar": (0.07, 0.0, -0.05),
                "Tail": (0.20, 0.24, 0.0),
                "LegFrontL": (0.06, 0.0, 0.0),
                "LegHindR": (-0.05, 0.0, 0.0),
            },
        ),
        (
            24,
            {
                **_spine(0.0, 0.0, 0.0, 0.02, lift=0.008, yaw=-0.10),
                **_filament(0.10, 0.16, 0.20, 0.24, yaw=-0.12),
                "LeftEar": (0.04, 0.0, 0.03),
                "Tail": (0.10, -0.06, 0.0),
            },
        ),
        (
            36,
            {
                **_spine(-0.04, 0.01, -0.04, 0.02, lift=0.030, roll=-0.02, yaw=-0.20),
                **_filament(0.22, 0.34, 0.44, 0.52, yaw=-0.22),
                "LeftEar": (0.06, 0.0, 0.04),
                "RightEar": (0.15, 0.0, -0.11),
                "Tail": (0.20, -0.24, 0.0),
                "LegFrontR": (0.06, 0.0, 0.0),
                "LegHindL": (-0.05, 0.0, 0.0),
            },
        ),
        (48, {}),
    ],
    # Two full strides of a diagonal walk — the core companion motion.
    "Lira_Follow": [
        (1, _walk_pose("contact_a")),
        (7, _walk_pose("pass_a")),
        (13, _walk_pose("contact_b")),
        (19, _walk_pose("pass_b")),
        (25, _walk_pose("contact_a")),
        (31, _walk_pose("pass_a")),
        (37, _walk_pose("contact_b")),
        (43, _walk_pose("pass_b")),
        (48, _walk_pose("contact_a")),
    ],
    # Nose down, sweeping the ground left then right, one paw lifted.
    "Lira_Investigate": [
        (1, {}),
        (
            10,
            {
                # Head reaches ~40 deg nose-down; the torso barely tips so the
                # weight stays over the legs.
                **_spine(0.08, 0.14, 0.45, 0.70, lift=-0.030, yaw=-0.40),
                **_filament(0.30, 0.44, 0.54, 0.62, yaw=0.26),
                "Snout": (0.10, 0.0, 0.0),
                "LeftEar": (0.26, 0.0, 0.20),
                "RightEar": (0.24, 0.0, -0.16),
                "LegFrontL": (0.34, 0.0, 0.0),
                "PawFrontL": (-0.22, 0.0, 0.0),
                "Tail": (0.16, 0.14, 0.0),
            },
        ),
        (
            26,
            {
                **_spine(0.08, 0.14, 0.45, 0.70, lift=-0.030, yaw=0.46),
                **_filament(0.30, 0.44, 0.54, 0.62, yaw=-0.28),
                "Snout": (0.10, 0.0, 0.0),
                "LeftEar": (0.22, 0.0, 0.16),
                "RightEar": (0.28, 0.0, -0.20),
                "LegFrontL": (0.05, 0.0, 0.0),
                "Tail": (0.16, -0.18, 0.0),
            },
        ),
        (
            38,
            {
                **_spine(0.0, 0.02, 0.14, 0.26, yaw=0.10),
                **_filament(0.16, 0.24, 0.30, 0.34, yaw=0.08),
                "LeftEar": (0.14, 0.0, 0.10),
                "RightEar": (0.14, 0.0, -0.10),
            },
        ),
        (48, {}),
    ],
    # Snap to attention: weight back, chest up, ears pinned forward, filament
    # spikes, then a held tremor rather than a return to neutral.
    "Lira_Alert": [
        (1, {}),
        (
            6,
            {
                # Chest lifts and the head comes back level — a braced stance,
                # not a rear. Filament spikes hard; that is the read at range.
                **_spine(-0.10, -0.18, -0.30, -0.22, lift=0.050),
                **_filament(0.46, 0.72, 0.92, 1.06),
                "LeftEar": (0.34, 0.0, 0.26),
                "RightEar": (0.34, 0.0, -0.26),
                "Tail": (0.40, 0.0, 0.0),
                "LegFrontL": (-0.26, 0.0, 0.0),
                "LegFrontR": (-0.26, 0.0, 0.0),
                "LegHindL": (0.22, 0.0, 0.0),
                "LegHindR": (0.22, 0.0, 0.0),
            },
        ),
        (
            18,
            {
                **_spine(-0.09, -0.16, -0.27, -0.20, lift=0.044, roll=0.020, yaw=0.24),
                **_filament(0.42, 0.66, 0.84, 0.96, yaw=0.16),
                "LeftEar": (0.32, 0.0, 0.24),
                "RightEar": (0.30, 0.0, -0.22),
                "Tail": (0.36, 0.10, 0.0),
                "LegFrontL": (-0.24, 0.0, 0.0),
                "LegFrontR": (-0.24, 0.0, 0.0),
            },
        ),
        (
            32,
            {
                **_spine(-0.09, -0.16, -0.27, -0.20, lift=0.044, roll=-0.020, yaw=-0.28),
                **_filament(0.42, 0.66, 0.84, 0.96, yaw=-0.18),
                "LeftEar": (0.30, 0.0, 0.22),
                "RightEar": (0.32, 0.0, -0.24),
                "Tail": (0.36, -0.10, 0.0),
                "LegFrontL": (-0.24, 0.0, 0.0),
                "LegFrontR": (-0.24, 0.0, 0.0),
            },
        ),
        (
            48,
            {
                **_spine(-0.10, -0.17, -0.29, -0.21, lift=0.046),
                **_filament(0.44, 0.69, 0.88, 1.02),
                "LeftEar": (0.33, 0.0, 0.25),
                "RightEar": (0.33, 0.0, -0.25),
                "Tail": (0.38, 0.0, 0.0),
                "LegFrontL": (-0.25, 0.0, 0.0),
                "LegFrontR": (-0.25, 0.0, 0.0),
            },
        ),
    ],
    # Two bounding hops with a big tail wag and a head toss.
    "Lira_Celebrate": [
        (1, {}),
        (
            8,
            {
                # Airborne: body pitches up ~9 deg, head tossed back ~26 deg.
                # Height comes from `lift` and the tucked legs, not from
                # rotating the whole character.
                **_spine(-0.16, -0.22, -0.38, -0.45, lift=0.115, yaw=0.24),
                **_filament(0.40, 0.62, 0.80, 0.92, yaw=0.40),
                "LeftEar": (-0.20, 0.0, 0.22),
                "RightEar": (-0.20, 0.0, -0.22),
                "LegFrontL": (-0.55, 0.0, 0.0),
                "PawFrontL": (0.30, 0.0, 0.0),
                "LegFrontR": (-0.55, 0.0, 0.0),
                "PawFrontR": (0.30, 0.0, 0.0),
                "LegHindL": (0.34, 0.0, 0.0),
                "LegHindR": (0.34, 0.0, 0.0),
                "Tail": (0.44, 0.42, 0.0),
            },
        ),
        (
            16,
            {
                # Landing: compress, head dips forward, tail whips the other way.
                **_spine(0.08, 0.12, 0.18, 0.24, lift=-0.030, yaw=-0.32),
                **_filament(0.18, 0.28, 0.36, 0.42, yaw=-0.44),
                "LegFrontL": (0.20, 0.0, 0.0),
                "LegFrontR": (0.20, 0.0, 0.0),
                "Tail": (0.20, -0.40, 0.0),
            },
        ),
        (
            24,
            {
                **_spine(-0.15, -0.21, -0.36, -0.43, lift=0.105, yaw=-0.24),
                **_filament(0.38, 0.59, 0.76, 0.88, yaw=0.38),
                "LeftEar": (-0.18, 0.0, 0.20),
                "RightEar": (-0.18, 0.0, -0.20),
                "LegFrontL": (-0.52, 0.0, 0.0),
                "PawFrontL": (0.28, 0.0, 0.0),
                "LegFrontR": (-0.52, 0.0, 0.0),
                "PawFrontR": (0.28, 0.0, 0.0),
                "LegHindL": (0.32, 0.0, 0.0),
                "LegHindR": (0.32, 0.0, 0.0),
                "Tail": (0.42, 0.40, 0.0),
            },
        ),
        (
            32,
            {
                **_spine(0.05, 0.07, 0.09, 0.10, lift=-0.018, yaw=0.20),
                **_filament(0.20, 0.30, 0.38, 0.44, yaw=-0.32),
                "Tail": (0.22, -0.30, 0.0),
            },
        ),
        (36, {}),
    ],
    # Materialize: crouched and coiled, unfold, shake out, settle.
    "Lira_Spawn": [
        (
            1,
            {
                # Coiled low: the crouch is `lift` plus folded legs. Cumulative
                # head pitch stays ~17 deg so the face clears the ground.
                **_spine(0.14, 0.20, 0.26, 0.30, lift=-0.120),
                **_filament(-0.34, -0.52, -0.66, -0.76),
                "LeftEar": (0.40, 0.0, -0.24),
                "RightEar": (0.40, 0.0, 0.24),
                "LegFrontL": (0.52, 0.0, 0.0),
                "PawFrontL": (-0.30, 0.0, 0.0),
                "LegFrontR": (0.52, 0.0, 0.0),
                "PawFrontR": (-0.30, 0.0, 0.0),
                "LegHindL": (-0.46, 0.0, 0.0),
                "LegHindR": (-0.46, 0.0, 0.0),
                "Tail": (-0.30, 0.0, 0.0),
            },
        ),
        (
            10,
            {
                # Unfold: chest lifts, filament snaps upright.
                **_spine(-0.08, -0.13, -0.22, -0.26, lift=0.048),
                **_filament(0.40, 0.62, 0.80, 0.92),
                "LeftEar": (0.30, 0.0, 0.22),
                "RightEar": (0.30, 0.0, -0.22),
                "LegFrontL": (-0.22, 0.0, 0.0),
                "LegFrontR": (-0.22, 0.0, 0.0),
                "Tail": (0.34, 0.0, 0.0),
            },
        ),
        (
            16,
            {
                # Shake out — a hard roll and head-whip, legs braced.
                **_spine(0.02, 0.03, 0.03, 0.06, lift=0.010, roll=0.045, yaw=0.40),
                **_filament(0.24, 0.37, 0.48, 0.56, yaw=0.34),
                "LeftEar": (0.20, 0.0, 0.26),
                "RightEar": (0.14, 0.0, -0.12),
                "Tail": (0.22, 0.30, 0.0),
            },
        ),
        (
            20,
            {
                **_spine(0.0, 0.0, 0.0, 0.02, lift=0.006, roll=-0.040, yaw=-0.36),
                **_filament(0.16, 0.25, 0.32, 0.38, yaw=-0.30),
                "Tail": (0.16, -0.26, 0.0),
            },
        ),
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


def key_bone(arm: bpy.types.Object, bone_name: str, frame: int, pose: tuple[float, ...]) -> None:
    """Key one bone. `pose` is (rx, ry, rz) or (rx, ry, rz, lx, ly, lz).

    Bone-local translation carries the body bob in the walk cycle; rotation
    alone cannot lift the whole silhouette off its contact pose.
    """
    pb = arm.pose.bones.get(bone_name)
    if pb is None:
        return
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = Euler(tuple(pose[:3]), "XYZ")
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)
    pb.location = tuple(pose[3:6]) if len(pose) >= 6 else (0.0, 0.0, 0.0)
    pb.keyframe_insert(data_path="location", frame=frame)


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
        b.location = (0.0, 0.0, 0.0)
        b.keyframe_insert(data_path="rotation_euler", frame=1)
        b.keyframe_insert(data_path="location", frame=1)
    for frame, bones in frames:
        # Reset unspecified bones to rest at this frame for clean loops
        for b in arm.pose.bones:
            if b.name not in bones:
                b.rotation_mode = "XYZ"
                b.rotation_euler = (0, 0, 0)
                b.location = (0.0, 0.0, 0.0)
                b.keyframe_insert(data_path="rotation_euler", frame=frame)
                b.keyframe_insert(data_path="location", frame=frame)
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
