"""
Bake Blender pose-bone animation into USD SkelAnimation timeSamples (#225).

Why this exists
---------------
Blender 5.x stores actions in the slotted (layered) system. Its USD exporter
writes the SkelAnimation prim with **static** default arrays for
`translations` / `rotations` / `scales` and emits no per-joint timeSamples,
so RealityKit reports `availableAnimations = 0` even though the rig animates
correctly in Blender. Verified on Blender 5.2.0 LTS: assigning the action,
binding the slot, setting the scene frame range, and refreshing the depsgraph
all evaluate the pose correctly, yet the exported USD still contains no
animated joint curves.

This module runs inside Blender, samples each joint's parent-local transform
per frame in the same convention Blender itself uses for the static arrays
(verified equal at the rest pose), and emits JSON that
`scripts/inject_usd_skel_timesamples.py` splices into the exported USD.

Joint-local convention (matches USD SkelAnimation and Blender's static write):
    rest:  parent.matrix_local.inverted() @ bone.matrix_local
    posed: parent_pose.matrix.inverted()  @ pose_bone.matrix
"""

from __future__ import annotations

import json
from pathlib import Path

import bpy


def _rest_local_matrix(bone: bpy.types.Bone):
    """Bone's rest transform relative to its parent (USD joint-local rest)."""
    if bone.parent is not None:
        return bone.parent.matrix_local.inverted() @ bone.matrix_local
    return bone.matrix_local.copy()


def _joint_local_matrix(arm: bpy.types.Object, joint_path: str):
    """Parent-local posed matrix for a USD joint path like `Root/Body/Chest`.

    Composed as `rest_local @ matrix_basis` rather than read from
    `pose_bone.matrix`. `pose_bone.matrix` is the *evaluated* pose, which is
    only meaningful once the depsgraph has refreshed and the armature is in
    POSE mode — a rest-frozen or unrefreshed rig reports the rest pose for
    every frame, which is precisely how a clip bakes to a static pose.
    `matrix_basis` is the animation channel itself, so it always reflects the
    current frame regardless of evaluation state. At frame 1 this reduces to
    the rest transform, matching the values Blender's own exporter writes into
    the static arrays.
    """
    name = joint_path.split("/")[-1]
    pose_bone = arm.pose.bones.get(name)
    if pose_bone is None:
        return None
    return _rest_local_matrix(pose_bone.bone) @ pose_bone.matrix_basis


def sample_clip(
    arm: bpy.types.Object,
    action: bpy.types.Action,
    joint_paths: list[str],
) -> dict:
    """Sample every joint over the action's frame range.

    Returns {"frames": [...], "translations": [[...]], "rotations": [[...]],
    "scales": [[...]]} with per-frame lists ordered to match `joint_paths`.
    """
    scene = bpy.context.scene
    start = int(round(action.frame_range[0]))
    end = max(int(round(action.frame_range[1])), start + 1)

    # Bind the action (Blender 5 auto-selects the matching slot; bind
    # explicitly when it does not so the pose actually evaluates).
    anim = arm.animation_data
    anim.action = action
    if getattr(anim, "action_slot", None) is None and action.slots:
        anim.action_slot = action.slots[0]

    scene.frame_start, scene.frame_end = start, end

    frames: list[int] = []
    translations: list[list[list[float]]] = []
    rotations: list[list[list[float]]] = []
    scales: list[list[list[float]]] = []

    for frame in range(start, end + 1):
        # `frame_set` alone is enough here; calling `view_layer.update()` in
        # this loop crashes background Blender 5.2.
        scene.frame_set(frame)
        frame_t, frame_r, frame_s = [], [], []
        for joint in joint_paths:
            matrix = _joint_local_matrix(arm, joint)
            if matrix is None:
                # Joint present in USD but not in the rig (e.g. a mesh-only
                # node): hold identity so array lengths stay aligned.
                frame_t.append([0.0, 0.0, 0.0])
                frame_r.append([1.0, 0.0, 0.0, 0.0])
                frame_s.append([1.0, 1.0, 1.0])
                continue
            translation = matrix.to_translation()
            quaternion = matrix.to_quaternion()
            scale = matrix.to_scale()
            frame_t.append([translation.x, translation.y, translation.z])
            # USD quatf is (w, x, y, z) — same order Blender reports.
            frame_r.append([quaternion.w, quaternion.x, quaternion.y, quaternion.z])
            frame_s.append([scale.x, scale.y, scale.z])
        frames.append(frame)
        translations.append(frame_t)
        rotations.append(frame_r)
        scales.append(frame_s)

    return {
        "action": action.name,
        "frames": frames,
        "translations": translations,
        "rotations": rotations,
        "scales": scales,
    }


def bake_clips(joint_paths: list[str], clip_names: list[str], out_path: Path) -> Path:
    """Bake every named clip and write one JSON payload."""
    arm = bpy.data.objects.get("LiraArmature")
    if arm is None or arm.animation_data is None:
        raise SystemExit("LiraArmature missing or has no animation data")

    payload = {"joints": joint_paths, "clips": {}}
    for name in clip_names:
        action = bpy.data.actions.get(name)
        if action is None:
            continue
        sampled = sample_clip(arm, action, joint_paths)
        # A clip whose joints never move is the exact failure this fixes.
        moved = any(
            sampled["rotations"][i] != sampled["rotations"][0]
            or sampled["translations"][i] != sampled["translations"][0]
            for i in range(1, len(sampled["frames"]))
        )
        if not moved:
            raise SystemExit(f"clip {name} sampled to a static pose (no motion)")
        payload["clips"][name] = sampled
        print(f"[bake_skel] {name}: {len(sampled['frames'])} frames x {len(joint_paths)} joints")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload))
    print(f"[bake_skel] wrote {out_path}")
    return out_path
