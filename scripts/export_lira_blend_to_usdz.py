#!/usr/bin/env python3
"""
Export Desktop/repo lira.blend → runtime Lira_AR_Base.usdz with Waykin node names.

Evidence class: ARTIST_BLEND_HERO_DCC_MID_LOD
  (artist multi-mesh + LiraArmature + hero region weight paint + DCC action
   clips Idle/Follow/Investigate/Alert/Celebrate/Spawn; FX rigid bone-parent).

Requires: Blender 3+ with USD export (wm.usd_export).
Invoked by: scripts/export_lira_blend_to_usdz.sh
"""

from __future__ import annotations

import importlib.util
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

    # DCC clips ship by default; set LIRA_EXPORT_ANIM=0 to strip animation.
    import os

    anim_env = os.environ.get("LIRA_EXPORT_ANIM", "1").strip().lower()
    export_anim = anim_env not in {"0", "false", "no", "off"}
    # Blender 5 USD export RNA (no visible_objects_only / export_textures flags)
    try:
        bpy.ops.wm.usd_export(
            filepath=str(path),
            check_existing=False,
            selected_objects_only=True,
            export_animation=export_anim,
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


def build_armature() -> None:
    """Load scripts/build_lira_armature.py and run build() in this Blender session."""
    path = ROOT / "scripts" / "build_lira_armature.py"
    if not path.is_file():
        raise SystemExit(f"missing armature builder: {path}")
    spec = importlib.util.spec_from_file_location("build_lira_armature", path)
    if spec is None or spec.loader is None:
        raise SystemExit("cannot load build_lira_armature")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.build()
    log("armature build complete")


def validate_armature() -> None:
    arm = bpy.data.objects.get("LiraArmature")
    if arm is None or arm.type != "ARMATURE":
        raise SystemExit("LiraArmature missing after build")
    bones = {b.name for b in arm.data.bones}
    for need in ("Body", "Head", "Filament", "CoreGlow", "LeftEar", "RightEar", "Tail"):
        if need not in bones:
            raise SystemExit(f"armature missing bone {need}")
    # Skinning binds automatic weights at rest and older art sources were saved
    # still in REST, which freezes every deformer: the mesh ignores the clips in
    # renders and in any pose-evaluated export. Force POSE so a rest-frozen
    # source cannot ship silently.
    if arm.data.pose_position != "POSE":
        log(f"armature pose_position={arm.data.pose_position} → POSE")
        arm.data.pose_position = "POSE"
    log(f"armature validated bones={len(bones)}")


def _load_mod(name: str, path: Path):
    if not path.is_file():
        raise SystemExit(f"missing script: {path}")
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load {name}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def skin_armature() -> dict:
    """Load scripts/skin_lira_armature.py and run skin() after scale."""
    mod = _load_mod("skin_lira_armature", ROOT / "scripts" / "skin_lira_armature.py")
    stats = mod.skin()
    log(f"skin complete multi_body={stats.get('Body')}")
    return stats


def hero_paint() -> dict:
    """Region-aware hero weight paint on top of auto-skin."""
    mod = _load_mod("paint_lira_hero_weights", ROOT / "scripts" / "paint_lira_hero_weights.py")
    stats = mod.paint()
    log(f"hero paint complete Body={stats.get('Body')}")
    return stats


def author_dcc_clips() -> list[str]:
    """Author Blender actions + NLA tracks for presentation states."""
    mod = _load_mod("author_lira_armature_clips", ROOT / "scripts" / "author_lira_armature_clips.py")
    names = mod.author()
    log(f"dcc clips authored {names}")
    return names


def _action_fcurve_count(action: bpy.types.Action) -> int:
    """F-curve count across Blender 5 slotted actions and legacy actions.

    Blender 5 moved curves to `layers[].strips[].channelbags[].fcurves` and
    removed `Action.fcurves`; the legacy path is kept for older Blenders.
    """
    legacy = getattr(action, "fcurves", None)
    if legacy is not None:
        return len(legacy)
    total = 0
    for layer in getattr(action, "layers", []):
        for strip in getattr(layer, "strips", []):
            for channelbag in getattr(strip, "channelbags", []):
                total += len(channelbag.fcurves)
    return total


def export_clip_animation_usds(out_dir: Path, clip_names: list[str]) -> list[Path]:
    """
    Export one USD per DCC action so RealityKit can discover multiple animations.
    Main package only binds the active action; sidecar clip USDs are zipped in.
    """
    arm = bpy.data.objects.get("LiraArmature")
    if arm is None or not arm.animation_data:
        return []
    written: list[Path] = []
    # Select armature hierarchy for lean clip packages
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    for o in bpy.data.objects:
        if o.parent == arm or (o.parent and o.parent.type == "ARMATURE"):
            o.select_set(True)
    bpy.context.view_layer.objects.active = arm
    scene = bpy.context.scene
    for name in clip_names:
        action = bpy.data.actions.get(name)
        if action is None:
            continue
        # A silently keyframe-less action exports as a static rest pose and
        # RealityKit reports availableAnimations=0 (#225). Fail loud instead.
        if _action_fcurve_count(action) == 0:
            raise SystemExit(f"clip action has no fcurves (nothing to bake): {name}")
        arm.animation_data.action = action
        # The USD exporter samples scene.frame_start…frame_end, NOT the action's
        # own range, and assigning .action from Python does not re-evaluate the
        # rig. Without both of these the exporter samples an unposed armature and
        # writes flat default joint arrays with no timeSamples (#225).
        start, end = action.frame_range
        scene.frame_start = int(round(start))
        scene.frame_end = max(int(round(end)), scene.frame_start + 1)
        scene.frame_set(scene.frame_start)
        bpy.context.view_layer.update()
        path = out_dir / f"{name}.usd"
        try:
            bpy.ops.wm.usd_export(
                filepath=str(path),
                check_existing=False,
                selected_objects_only=True,
                export_animation=True,
                export_hair=False,
                export_uvmaps=False,
                export_normals=True,
                export_materials=False,
                use_instancing=False,
                evaluation_mode="RENDER",
                convert_orientation=True,
                relative_paths=True,
                root_prim_path=f"/{name}",
                export_armatures=True,
                convert_scene_units="METERS",
                meters_per_unit=1.0,
            )
            if path.is_file():
                written.append(path)
                log(f"clip usd {path.name}")
        except Exception as e:
            log(f"WARN clip export {name}: {e}")
    # Blender 5's USD writer emits the SkelAnimation prim with static default
    # joint arrays and no timeSamples, so RealityKit reports
    # availableAnimations=0 (#225). Bake the real per-frame joint transforms
    # and splice them in. Verified: this is what flips clipSource puppet->dcc.
    _inject_baked_skel_animation(out_dir, clip_names, written)
    # Restore idle as default active
    idle = bpy.data.actions.get("Lira_Idle")
    if idle is not None:
        arm.animation_data.action = idle
    return written


def _usd_joint_paths(usd_path: Path) -> list[str]:
    """Read the SkelAnimation `joints` token order straight from the export."""
    import re
    import subprocess

    text = subprocess.run(
        ["usdcat", str(usd_path)], check=True, capture_output=True, text=True
    ).stdout
    match = re.search(r"uniform token\[\] joints = \[(.*?)\]", text, re.S)
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))


def _inject_baked_skel_animation(
    out_dir: Path, clip_names: list[str], written: list[Path]
) -> None:
    if not written:
        return
    import subprocess

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from bake_lira_skel_animation import bake_clips  # noqa: E402
    from inject_usd_skel_timesamples import inject  # noqa: E402

    joint_paths = _usd_joint_paths(written[0])
    if not joint_paths:
        log("WARN no joints found in clip USD; skipping skel bake")
        return

    baked = bake_clips(joint_paths, clip_names, out_dir / "lira_skel_baked.json")
    # Call in-process: inside Blender, `sys.executable` is the Blender binary,
    # so shelling out to it as a Python interpreter would not work.
    for path in written:
        inject(path, baked, path.stem)


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
    # Armature + rigid bind first (anchors bones to mesh centers).
    build_armature()
    # Scale before heat-map so weights sit on final metric geometry.
    scale_to_canonical_height(root)
    validate_armature()
    # Merge torso + automatic weights, then hero region paint.
    skin_stats = skin_armature()
    hero_stats = hero_paint()
    clip_names = author_dcc_clips()
    validate_names()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    usd_path = OUT_DIR / "Lira_AR_Base.usd"
    export_usd(usd_path)
    # Per-clip animation USDs (active action only ships one SkelAnimation in main file).
    clip_usd_paths = export_clip_animation_usds(OUT_DIR, clip_names)

    # Also save a prepared blend into ArtSource for provenance
    ARTSOURCE.mkdir(parents=True, exist_ok=True)
    prepared = ARTSOURCE / "Lira_AR_Base_prepared.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(prepared))
    log(f"saved prepared blend {prepared}")
    # Mirror with_clips alias for tooling
    with_clips = ARTSOURCE / "Lira_AR_Base_with_clips.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(with_clips))
    log(f"saved clips blend {with_clips}")

    # Write marker for shell packaging
    body_stats = hero_stats.get("Body") or skin_stats.get("Body", {})
    marker = OUT_DIR / "EXPORT_OK"
    marker.write_text(
        f"usd={usd_path}\nblend={BLEND}\nevidence=ARTIST_BLEND_HERO_DCC_MID_LOD\n"
        f"armature=LiraArmature\nbone_bind=hero_region_paint\n"
        f"dcc_clips={','.join(clip_names)}\n"
        f"clip_usds={','.join(p.name for p in clip_usd_paths)}\n"
        f"body_vgroups={body_stats.get('vgroups')}\n"
        f"body_multi_bone_verts={body_stats.get('multi_bone_verts')}\n"
        f"body_multi_bone_ratio={body_stats.get('multi_bone_ratio')}\n"
        f"body_max_influences={body_stats.get('max_influences')}\n",
        encoding="utf-8",
    )
    log("done")


if __name__ == "__main__":
    main()
