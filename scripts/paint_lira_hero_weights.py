#!/usr/bin/env python3
"""
Hero-grade weight paint for Lira multi-mesh on LiraArmature.

Evidence target: ARTIST_BLEND_HERO_WEIGHTS (reproducible distance+region paint,
not freehand DCC stroke logs — still higher quality than raw ARMATURE_AUTO).

Strategy:
  1. Require existing Armature modifier + LiraArmature (after skin_lira_armature).
  2. For each skinned mesh, assign bone influence sets by semantic region.
  3. Distance falloff from bone heads (world space) → heat map.
  4. Mirror L/R groups for symmetric parts.
  5. Smooth passes + influence cap + normalize.
  6. Gate: multi-bone ratio + max influences.

Invoked from export_lira_blend_to_usdz.py after auto-skin.
Standalone:
  blender --background prepared.blend --python scripts/paint_lira_hero_weights.py
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ARMATURE_NAME = "LiraArmature"
MAX_INFLUENCES = 4
SMOOTH_ITERS = 2
SIGMA_SCALE = 0.22  # falloff relative to character height (~0.72m)

# Mesh → preferred deform bones (in priority order). Others get residual weight.
REGION_BONES: dict[str, list[str]] = {
    "Body": ["Body", "Chest", "Neck", "Root", "LegFrontL", "LegFrontR", "LegHindL", "LegHindR"],
    "Head": ["Head", "Neck", "Snout", "LeftEar", "RightEar", "Chest"],
    "LeftEar": ["LeftEar", "Head", "Neck"],
    "RightEar": ["RightEar", "Head", "Neck"],
    "Lira_InnerEar.L": ["LeftEar", "Head"],
    "Lira_InnerEar.R": ["RightEar", "Head"],
    "Lira_Eye.L": ["Head", "LeftEar"],
    "Lira_Eye.R": ["Head", "RightEar"],
    "Lira_ForeheadGlow": ["Head", "Neck"],
    "Lira_TempleMark.L": ["Head", "LeftEar"],
    "Lira_TempleMark.R": ["Head", "RightEar"],
    "Lira_Leg.Front.L": ["LegFrontL", "PawFrontL", "Body", "Chest"],
    "Lira_Leg.Front.R": ["LegFrontR", "PawFrontR", "Body", "Chest"],
    "Lira_Leg.Hind.L": ["LegHindL", "PawHindL", "Body"],
    "Lira_Leg.Hind.R": ["LegHindR", "PawHindR", "Body"],
    "Lira_Paw.Front.L": ["PawFrontL", "LegFrontL", "Body"],
    "Lira_Paw.Front.R": ["PawFrontR", "LegFrontR", "Body"],
    "Lira_Paw.Hind.L": ["PawHindL", "LegHindL", "Body"],
    "Lira_Paw.Hind.R": ["PawHindR", "LegHindR", "Body"],
}

MIRROR_PAIRS = [
    ("LeftEar", "RightEar"),
    ("LegFrontL", "LegFrontR"),
    ("LegHindL", "LegHindR"),
    ("PawFrontL", "PawFrontR"),
    ("PawHindL", "PawHindR"),
]


def log(msg: str) -> None:
    print(f"[hero_paint] {msg}")


def object_mode() -> None:
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")


def bone_world_heads(arm: bpy.types.Object) -> dict[str, Vector]:
    mw = arm.matrix_world
    heads: dict[str, Vector] = {}
    for b in arm.data.bones:
        heads[b.name] = mw @ b.head_local
    return heads


def ensure_vertex_groups(obj: bpy.types.Object, bone_names: list[str]) -> None:
    for name in bone_names:
        if name not in obj.vertex_groups:
            obj.vertex_groups.new(name=name)


def clear_all_weights(obj: bpy.types.Object) -> None:
    for vg in obj.vertex_groups:
        try:
            vg.remove(range(len(obj.data.vertices)))
        except Exception:
            pass


def paint_mesh(obj: bpy.types.Object, arm: bpy.types.Object, heads: dict[str, Vector], sigma: float) -> None:
    preferred = REGION_BONES.get(obj.name)
    if not preferred:
        # default organic shell
        preferred = ["Body", "Chest", "Neck", "Head"]
    available = [b for b in preferred if b in heads]
    if not available:
        available = [b for b in heads if b not in {"GroundShadow", "StatusIndicator", "CoreHalo"}]
    ensure_vertex_groups(obj, list(heads.keys()))
    clear_all_weights(obj)

    mesh = obj.data
    mw = obj.matrix_world
    for v in mesh.vertices:
        wp = mw @ v.co
        scores: list[tuple[str, float]] = []
        for bi, bname in enumerate(available):
            d = (wp - heads[bname]).length
            # Prefer earlier bones slightly (region priority)
            priority = 1.0 + 0.15 * (len(available) - bi)
            w = math.exp(-(d * d) / (2.0 * sigma * sigma)) * priority
            scores.append((bname, w))
        # Keep top influences only among preferred set
        scores.sort(key=lambda x: x[1], reverse=True)
        top = scores[:MAX_INFLUENCES]
        total = sum(w for _, w in top) or 1.0
        for bname, w in top:
            obj.vertex_groups[bname].add([v.index], w / total, "REPLACE")


def smooth_weights(obj: bpy.types.Object, iterations: int = SMOOTH_ITERS) -> None:
    """Average vertex weights with mesh neighbors (simple Laplacian on weights)."""
    mesh = obj.data
    # adjacency
    adj: list[set[int]] = [set() for _ in range(len(mesh.vertices))]
    for poly in mesh.polygons:
        ids = list(poly.vertices)
        for i, a in enumerate(ids):
            for b in ids:
                if a != b:
                    adj[a].add(b)

    vg_index = {vg.index: vg for vg in obj.vertex_groups}
    for _ in range(iterations):
        # snapshot weights per vert: {group_index: weight}
        snap: list[dict[int, float]] = []
        for v in mesh.vertices:
            snap.append({g.group: g.weight for g in v.groups if g.weight > 1e-6})
        for vi, v in enumerate(mesh.vertices):
            neigh = adj[vi]
            if not neigh:
                continue
            acc: dict[int, float] = {}
            for ni in neigh:
                for gi, w in snap[ni].items():
                    acc[gi] = acc.get(gi, 0.0) + w
            for gi in acc:
                acc[gi] /= len(neigh)
            # blend 50% self / 50% neighbor average
            self_w = snap[vi]
            keys = set(self_w) | set(acc)
            blended: list[tuple[int, float]] = []
            for gi in keys:
                val = 0.5 * self_w.get(gi, 0.0) + 0.5 * acc.get(gi, 0.0)
                if val > 1e-5:
                    blended.append((gi, val))
            blended.sort(key=lambda x: x[1], reverse=True)
            blended = blended[:MAX_INFLUENCES]
            total = sum(w for _, w in blended) or 1.0
            # clear then set
            for gi in list(self_w.keys()):
                try:
                    vg_index[gi].remove([vi])
                except Exception:
                    pass
            for gi, w in blended:
                vg_index[gi].add([vi], w / total, "REPLACE")


def limit_normalize(obj: bpy.types.Object) -> None:
    for v in obj.data.vertices:
        groups = [(g.group, g.weight) for g in v.groups if g.weight > 1e-5]
        if not groups:
            continue
        groups.sort(key=lambda x: x[1], reverse=True)
        keep = groups[:MAX_INFLUENCES]
        drop = groups[MAX_INFLUENCES:]
        for gi, _ in drop:
            try:
                obj.vertex_groups[gi].remove([v.index])
            except RuntimeError:
                pass
        total = sum(w for _, w in keep) or 1.0
        for gi, w in keep:
            obj.vertex_groups[gi].add([v.index], w / total, "REPLACE")


def weight_stats(obj: bpy.types.Object) -> dict:
    multi = 0
    max_inf = 0
    for v in obj.data.vertices:
        n = sum(1 for g in v.groups if g.weight > 1e-4)
        if n > 1:
            multi += 1
        max_inf = max(max_inf, n)
    verts = max(1, len(obj.data.vertices))
    return {
        "verts": len(obj.data.vertices),
        "vgroups": len(obj.vertex_groups),
        "multi_bone_verts": multi,
        "multi_bone_ratio": round(multi / verts, 4),
        "max_influences": max_inf,
    }


def skinned_targets() -> list[bpy.types.Object]:
    out = []
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        if any(m.type == "ARMATURE" for m in o.modifiers):
            out.append(o)
    return out


def paint() -> dict:
    arm = bpy.data.objects.get(ARMATURE_NAME)
    if arm is None or arm.type != "ARMATURE":
        raise SystemExit("LiraArmature required")
    heads = bone_world_heads(arm)
    # sigma from character height
    zs = [h.z for h in heads.values()]
    height = max(zs) - min(zs) if zs else 0.72
    sigma = max(0.05, height * SIGMA_SCALE)
    log(f"sigma={sigma:.4f} height≈{height:.3f}")

    targets = skinned_targets()
    if not targets:
        raise SystemExit("no armature-skinned meshes found — run skin_lira_armature first")

    for o in targets:
        paint_mesh(o, arm, heads, sigma)
        smooth_weights(o)
        limit_normalize(o)
        log(f"painted {o.name} {weight_stats(o)}")

    body = bpy.data.objects.get("Body")
    head = bpy.data.objects.get("Head")
    stats = {
        "Body": weight_stats(body) if body else {},
        "Head": weight_stats(head) if head else {},
        "meshes": [o.name for o in targets],
    }
    if body:
        if stats["Body"].get("multi_bone_ratio", 0) < 0.2:
            raise SystemExit(f"hero paint quality gate failed Body={stats['Body']}")
        if stats["Body"].get("max_influences", 0) > MAX_INFLUENCES:
            raise SystemExit(f"influence cap failed Body={stats['Body']}")
    log(f"hero paint complete {stats}")
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
    stats = paint()
    if len(argv) > 1:
        out = Path(argv[1])
        out.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(out))
        log(f"saved {out}")
    log(f"done meshes={stats.get('meshes')}")


if __name__ == "__main__":
    main()
