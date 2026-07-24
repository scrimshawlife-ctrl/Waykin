#!/usr/bin/env python3
"""
Splice baked joint curves into a USD SkelAnimation prim (#225).

Blender 5.x's USD exporter writes SkelAnimation `translations` / `rotations` /
`scales` as **static** default arrays with no timeSamples, so RealityKit sees
`availableAnimations = 0`. `scripts/bake_lira_skel_animation.py` samples the
real per-frame joint transforms inside Blender; this script rewrites those
static attributes as timeSampled ones so the clip becomes a real animation.

Verified: identical file + real timeSamples took a clip from
`availableAnimations = 0` to `2` (root) / `7` (tree) under RealityKit.

Usage:
    inject_usd_skel_timesamples.py <clip.usd> <baked.json> <clip_name>

Requires `usdcat` (ships with Xcode) for crate <-> text round-tripping.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

TIMECODES_PER_SECOND = 24.0


def _usdcat(src: Path, dst: Path) -> None:
    subprocess.run(["usdcat", str(src), "-o", str(dst)], check=True)


def _fmt_float(value: float) -> str:
    # Trim noise from float32 round-tripping while staying lossless enough
    # for pose data (USD parses these as float32 anyway).
    return f"{value:.7g}"


def _fmt_vec(values: list[float]) -> str:
    return "(" + ", ".join(_fmt_float(v) for v in values) + ")"


def _fmt_array(rows: list[list[float]]) -> str:
    return "[" + ", ".join(_fmt_vec(r) for r in rows) + "]"


def _timesamples_block(
    indent: str,
    attr_type: str,
    attr_name: str,
    frames: list[int],
    per_frame: list[list[list[float]]],
) -> str:
    lines = [f"{indent}{attr_type} {attr_name}.timeSamples = {{"]
    for frame, rows in zip(frames, per_frame):
        lines.append(f"{indent}    {frame}: {_fmt_array(rows)},")
    lines.append(f"{indent}}}")
    return "\n".join(lines) + "\n"


def _replace_attr(
    text: str,
    attr_type: str,
    attr_name: str,
    frames: list[int],
    per_frame: list[list[list[float]]],
) -> str:
    """Replace a static `<type> <name> = [...]` with a timeSampled block."""
    pattern = re.compile(
        rf"(\n([ \t]*)){re.escape(attr_type)} {re.escape(attr_name)} = \[.*?\]\n",
        re.S,
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"static attribute not found: {attr_type} {attr_name}")
    indent = match.group(2)
    block = "\n" + _timesamples_block(indent, attr_type, attr_name, frames, per_frame)
    return text[: match.start()] + block + text[match.end() :]


def inject(usd_path: Path, baked_path: Path, clip_name: str) -> None:
    payload = json.loads(baked_path.read_text())
    clip = payload["clips"].get(clip_name)
    if clip is None:
        raise SystemExit(f"no baked data for clip: {clip_name}")

    baked_joints = payload["joints"]
    frames = clip["frames"]

    text_path = usd_path.with_suffix(".injected.usda")
    _usdcat(usd_path, text_path)
    text = text_path.read_text()

    # The baked joint order must match the USD's own `joints` token array, or
    # curves would be applied to the wrong bones.
    usd_joints = re.search(r'uniform token\[\] joints = \[(.*?)\]', text, re.S)
    if usd_joints:
        names = re.findall(r'"([^"]+)"', usd_joints.group(1))
        if names != baked_joints:
            raise SystemExit(
                f"joint order mismatch: usd={len(names)} baked={len(baked_joints)}"
            )

    text = _replace_attr(text, "float3[]", "translations", frames, clip["translations"])
    text = _replace_attr(text, "quatf[]", "rotations", frames, clip["rotations"])
    text = _replace_attr(text, "half3[]", "scales", frames, clip["scales"])

    # Keep stage timing consistent with the injected samples.
    text = re.sub(r"endTimeCode = [\d.]+", f"endTimeCode = {frames[-1]}", text, count=1)
    text = re.sub(r"startTimeCode = [\d.]+", f"startTimeCode = {frames[0]}", text, count=1)
    if "timeCodesPerSecond" not in text:
        text = text.replace(
            "metersPerUnit = 1",
            f"metersPerUnit = 1\n    timeCodesPerSecond = {TIMECODES_PER_SECOND}",
            1,
        )

    text_path.write_text(text)
    _usdcat(text_path, usd_path)  # back to crate, in place
    text_path.unlink(missing_ok=True)
    print(f"[inject_skel] {usd_path.name}: {len(frames)} timeSamples x {len(baked_joints)} joints")


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    inject(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3])


if __name__ == "__main__":
    main()
