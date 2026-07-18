#!/usr/bin/env python3

import argparse
import math
import re
import statistics
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Thresholds:
    minimum_samples: int = 4_500
    minimum_span_seconds: float = 88.0
    maximum_median_ms: float = 17.5
    maximum_p95_ms: float = 20.0
    maximum_p99_ms: float = 34.0
    maximum_over_34_percent: float = 1.0
    maximum_missing_frame_percent: float = 1.0
    maximum_frame_ms: float = 100.0


def resolved_cell(cell: ET.Element, ids: dict[str, ET.Element]) -> ET.Element:
    reference = cell.get("ref")
    if reference:
        return ids.get(reference, cell)
    identifier = cell.get("id")
    if identifier:
        ids[identifier] = cell
    return cell


def cell_text(cell: ET.Element) -> str:
    return cell.get("fmt") or cell.text or ""


def nearest_rank(values: list[float], percentile: float) -> float:
    if not values:
        raise ValueError("cannot calculate a percentile without samples")
    ordered = sorted(values)
    index = max(0, math.ceil(percentile * len(ordered)) - 1)
    return ordered[index]


def schema_indices(root: ET.Element) -> dict[str, int]:
    schema = root.find(".//schema")
    if schema is None:
        raise ValueError("displayed-surfaces schema is missing")
    indices = {
        column.findtext("mnemonic", default=""): index
        for index, column in enumerate(schema.findall("col"))
    }
    required = {"start", "duration", "event-label", "direct-to-display"}
    missing = required - indices.keys()
    if missing:
        raise ValueError(f"displayed-surfaces schema is missing columns: {sorted(missing)}")
    return indices


def parse_samples(path: Path, process_name: str) -> tuple[list[float], list[int], list[float]]:
    if not process_name.strip():
        raise ValueError("process name must not be empty")
    root = ET.parse(path).getroot()
    indices = schema_indices(root)
    ids: dict[str, ET.Element] = {}
    durations_ms: list[float] = []
    frame_numbers: list[int] = []
    timestamps_seconds: list[float] = []

    for row in root.findall(".//row"):
        cells = [resolved_cell(cell, ids) for cell in list(row)]
        if len(cells) < len(indices):
            continue

        narrative = cell_text(cells[indices["event-label"]])
        direct_to_display = cell_text(cells[indices["direct-to-display"]])
        match = re.search(
            r",\s*(?P<process>.*?)\s+\(\d+\)\s*:Frame\s+(?P<frame>[\d,]+)\s*:",
            narrative,
        )
        if (
            direct_to_display not in {"1", "Yes"}
            or match is None
            or match.group("process") != process_name
        ):
            continue

        try:
            timestamp_ns = int((cells[indices["start"]].text or "").strip())
            duration_ns = int((cells[indices["duration"]].text or "").strip())
        except ValueError:
            continue
        timestamps_seconds.append(timestamp_ns / 1_000_000_000)
        durations_ms.append(duration_ns / 1_000_000)
        frame_numbers.append(int(match.group("frame").replace(",", "")))

    if not durations_ms:
        raise ValueError(f"no displayed-surface samples found for {process_name!r}")
    return durations_ms, frame_numbers, timestamps_seconds


def frame_sequence(frame_numbers: list[int]) -> tuple[int, bool]:
    missing = 0
    strictly_increasing = True
    for previous, current in zip(frame_numbers, frame_numbers[1:]):
        if current > previous + 1:
            missing += current - previous - 1
        elif current <= previous:
            strictly_increasing = False
    return missing, strictly_increasing


def analyze(
    durations_ms: list[float],
    frame_numbers: list[int],
    timestamps_seconds: list[float],
    thresholds: Thresholds,
) -> bool:
    sample_count = len(durations_ms)
    if len(frame_numbers) != sample_count or len(timestamps_seconds) != sample_count:
        raise ValueError("duration, frame-number, and timestamp sample counts differ")
    span_seconds = max(timestamps_seconds) - min(timestamps_seconds)
    median_ms = statistics.median(durations_ms)
    p95_ms = nearest_rank(durations_ms, 0.95)
    p99_ms = nearest_rank(durations_ms, 0.99)
    maximum_ms = max(durations_ms)
    over_34_count = sum(duration > 34.0 for duration in durations_ms)
    over_34_percent = (over_34_count / sample_count) * 100
    missing_frames, frame_numbers_increasing = frame_sequence(frame_numbers)
    frame_slots = sample_count + missing_frames
    missing_frame_percent = (missing_frames / frame_slots) * 100 if frame_slots else 0

    checks = [
        ("sample_count", sample_count, ">=", thresholds.minimum_samples, sample_count >= thresholds.minimum_samples),
        (
            "span_seconds",
            span_seconds,
            ">=",
            thresholds.minimum_span_seconds,
            span_seconds >= thresholds.minimum_span_seconds,
        ),
        ("median_ms", median_ms, "<=", thresholds.maximum_median_ms, median_ms <= thresholds.maximum_median_ms),
        ("p95_ms", p95_ms, "<=", thresholds.maximum_p95_ms, p95_ms <= thresholds.maximum_p95_ms),
        ("p99_ms", p99_ms, "<=", thresholds.maximum_p99_ms, p99_ms <= thresholds.maximum_p99_ms),
        (
            "over_34_percent",
            over_34_percent,
            "<=",
            thresholds.maximum_over_34_percent,
            over_34_percent <= thresholds.maximum_over_34_percent,
        ),
        (
            "missing_frame_percent",
            missing_frame_percent,
            "<=",
            thresholds.maximum_missing_frame_percent,
            missing_frame_percent <= thresholds.maximum_missing_frame_percent,
        ),
        (
            "frame_numbers_strictly_increasing",
            int(frame_numbers_increasing),
            "==",
            1,
            frame_numbers_increasing,
        ),
        ("maximum_ms", maximum_ms, "<=", thresholds.maximum_frame_ms, maximum_ms <= thresholds.maximum_frame_ms),
    ]

    print(
        " ".join(
            [
                f"samples={sample_count}",
                f"span_seconds={span_seconds:.4f}",
                f"median_ms={median_ms:.4f}",
                f"p95_ms={p95_ms:.4f}",
                f"p99_ms={p99_ms:.4f}",
                f"maximum_ms={maximum_ms:.4f}",
                f"over_34_count={over_34_count}",
                f"over_34_percent={over_34_percent:.4f}",
                f"frame_numbers={len(frame_numbers)}",
                f"missing_frame_numbers={missing_frames}",
                f"missing_frame_percent={missing_frame_percent:.4f}",
                f"frame_numbers_strictly_increasing={str(frame_numbers_increasing).lower()}",
            ]
        )
    )
    for name, observed, relation, limit, passed in checks:
        observed_text = f"{observed:.4f}" if isinstance(observed, float) else str(observed)
        print(
            f"{'PASS' if passed else 'FAIL'} {name} "
            f"observed={observed_text} required={relation}{limit}"
        )

    passed = all(check[-1] for check in checks)
    print(f"AR3_FRAME_PACING_GATE={'PASS' if passed else 'FAIL'}")
    return passed


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Analyze an exported AR-3 displayed-surfaces-interval XML table."
    )
    parser.add_argument("xml", type=Path, help="XML exported from an Instruments displayed-surfaces table")
    parser.add_argument("--process", default="Waykin AR Lab", help="Target process name")
    arguments = parser.parse_args()

    try:
        durations_ms, frame_numbers, timestamps_seconds = parse_samples(
            arguments.xml, arguments.process
        )
    except (ET.ParseError, OSError, ValueError) as error:
        print(f"analysis error: {error}", file=sys.stderr)
        return 2

    return 0 if analyze(durations_ms, frame_numbers, timestamps_seconds, Thresholds()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
