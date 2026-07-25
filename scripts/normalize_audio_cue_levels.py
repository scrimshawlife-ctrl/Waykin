#!/usr/bin/env python3
"""Gain-match the produced cue WAVs to one reference loudness.

`docs/design/LIRA_AUDIO_CUE_FAMILY.md` requires every cue mastered to the same
reference, with the per-cue `volume` in `App/AppAudioCuePlayer.swift` as the
single source of relative balance. Level differences must not be baked into the
files — otherwise the catalog volume applies the difference a second time.

This does level only. It never re-synthesizes: each file is scaled by a single
constant, so the produced sound design is preserved exactly.

Loudness is a gated RMS: 400 ms blocks below the relative gate are dropped
before averaging, so long tails and lead-in silence don't drag the measurement
down and cause an over-boost. This approximates EBU R128 gating without
requiring ffmpeg.

Usage:
    python3 scripts/normalize_audio_cue_levels.py            # report only
    python3 scripts/normalize_audio_cue_levels.py --apply    # rewrite in place
"""

import argparse
import glob
import math
import os
import struct
import sys
import wave

AUDIO_DIR = "App/Resources/Audio"
# Cues mastered in #232; used as the reference the older cues are matched to.
REFERENCE_FILES = {
    "lira_launch_theme",
    "lira_companion_reveal",
    "lira_spawn_theme",
    "lira_bond_milestone",
}
TRUE_PEAK_CEILING_DB = -3.0
BLOCK_MS = 400
RELATIVE_GATE_DB = 20.0   # drop blocks >20 dB below the loudest block
ABSOLUTE_GATE_DB = -70.0
FULL_SCALE = 32768.0


def db(x):
    return 20 * math.log10(x) if x > 0 else float("-inf")


def read_wav(path):
    with wave.open(path, "rb") as w:
        params = w.getparams()
        raw = w.readframes(params.nframes)
    if params.sampwidth != 2:
        raise ValueError(f"{path}: expected 16-bit, got {params.sampwidth * 8}-bit")
    count = len(raw) // 2
    return params, list(struct.unpack("<%dh" % count, raw[: count * 2]))


def write_wav(path, params, samples):
    clipped = [max(-32768, min(32767, int(round(s)))) for s in samples]
    with wave.open(path, "wb") as w:
        w.setparams(params)
        w.writeframes(struct.pack("<%dh" % len(clipped), *clipped))


def gated_rms_db(samples, framerate, channels):
    """Mean-square over blocks that survive an absolute + relative gate."""
    block = max(1, int(framerate * channels * BLOCK_MS / 1000))
    powers = []
    for i in range(0, len(samples) - block + 1, block):
        chunk = samples[i : i + block]
        ms = sum(s * s for s in chunk) / len(chunk)
        if ms > 0:
            powers.append(ms)
    if not powers:
        return float("-inf")
    loudest = max(powers)
    gate = max(loudest / (10 ** (RELATIVE_GATE_DB / 10)), (10 ** (ABSOLUTE_GATE_DB / 10)) * FULL_SCALE**2)
    kept = [p for p in powers if p >= gate] or powers
    return db(math.sqrt(sum(kept) / len(kept)) / FULL_SCALE)


def peak_db(samples):
    peak = max((abs(s) for s in samples), default=0)
    return db(peak / FULL_SCALE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="rewrite files in place")
    args = ap.parse_args()

    if not os.path.isdir(AUDIO_DIR):
        sys.exit(f"run from repo root: {AUDIO_DIR} not found")

    measured = {}
    for path in sorted(glob.glob(os.path.join(AUDIO_DIR, "*.wav"))):
        name = os.path.basename(path)[:-4]
        params, samples = read_wav(path)
        measured[name] = {
            "path": path,
            "params": params,
            "samples": samples,
            "rms": gated_rms_db(samples, params.framerate, params.nchannels),
            "peak": peak_db(samples),
        }

    refs = [m["rms"] for n, m in measured.items() if n in REFERENCE_FILES]
    if not refs:
        sys.exit("no reference files found")
    target = sum(refs) / len(refs)
    print(f"reference cues: {', '.join(sorted(REFERENCE_FILES))}")
    print(f"target gated RMS: {target:.1f} dBFS   true-peak ceiling: {TRUE_PEAK_CEILING_DB:.1f} dBFS\n")

    header = f"{'file':<28}{'gain':>8}{'RMS →':>16}{'peak →':>16}"
    print(header)
    print("-" * len(header))

    changed = 0
    for name in sorted(measured):
        m = measured[name]
        if name in REFERENCE_FILES:
            # Deliberately mastered in #232 — these define the target, never rewritten.
            print(f"{name:<28}{'ref':>8}{m['rms']:>10.1f}     {m['peak']:>11.1f}")
            continue
        gain_db = target - m["rms"]
        gain = 10 ** (gain_db / 20)
        # Do not let the gain push true peak past the ceiling.
        headroom_db = TRUE_PEAK_CEILING_DB - (m["peak"] + gain_db)
        if headroom_db < 0:
            gain_db += headroom_db
            gain = 10 ** (gain_db / 20)
        if abs(gain_db) < 0.05:
            print(f"{name:<28}{'—':>8}{m['rms']:>10.1f} (ok){m['peak']:>11.1f} (ok)")
            continue
        scaled = [s * gain for s in m["samples"]]
        new_rms = gated_rms_db(scaled, m["params"].framerate, m["params"].nchannels)
        new_peak = peak_db(scaled)
        flag = "  <-- large boost, check noise floor" if gain_db > 12 else ""
        print(
            f"{name:<28}{gain_db:>+7.1f}dB{m['rms']:>8.1f}→{new_rms:>6.1f}{m['peak']:>9.1f}→{new_peak:>6.1f}{flag}"
        )
        if args.apply:
            write_wav(m["path"], m["params"], scaled)
            changed += 1

    if args.apply:
        print(f"\nrewrote {changed} file(s)")
    else:
        print("\ndry run — pass --apply to rewrite")


if __name__ == "__main__":
    main()
