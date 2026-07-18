import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).parents[1] / "analyze_ar3_frame_pacing.py"
SPEC = importlib.util.spec_from_file_location("analyze_ar3_frame_pacing", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)

SCHEMA = """
<schema name="displayed-surfaces-interval">
  <col><mnemonic>start</mnemonic></col>
  <col><mnemonic>duration</mnemonic></col>
  <col><mnemonic>cpu-to-display-latency</mnemonic></col>
  <col><mnemonic>display-name</mnemonic></col>
  <col><mnemonic>connection-UUID</mnemonic></col>
  <col><mnemonic>surface-id</mnemonic></col>
  <col><mnemonic>pixel-format</mnemonic></col>
  <col><mnemonic>color</mnemonic></col>
  <col><mnemonic>event-priority</mnemonic></col>
  <col><mnemonic>event-label</mnemonic></col>
  <col><mnemonic>category</mnemonic></col>
  <col><mnemonic>event-depth</mnemonic></col>
  <col><mnemonic>direct-to-display</mnemonic></col>
</schema>
"""


def displayed_surface_row(
    timestamp: int,
    duration: str,
    frame: int,
    process: str = "Waykin AR Lab",
) -> str:
    return f"""
    <row>
      <start-time>{timestamp}</start-time>
      <duration>{duration}</duration>
      <sentinel/><display-name>Display 1</display-name><connection-uuid64>1</connection-uuid64>
      <uint64>1</uint64><string></string><render-buffer-depth>1</render-buffer-depth>
      <metal-workload-priority>1</metal-workload-priority>
      <narrative fmt="Direct to Display (Surface 1, {process} (42) :Frame {frame:,} :Surface 1)"></narrative>
      <display-event-name>Display</display-event-name><metal-nesting-level>0</metal-nesting-level>
      <boolean fmt="Yes">1</boolean>
    </row>
    """


class AnalyzeAR3FramePacingTests(unittest.TestCase):
    def write_xml(self, rows: str) -> Path:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "trace.xml"
        path.write_text(f"<trace-query-result>{SCHEMA}{rows}</trace-query-result>")
        return path

    def test_parser_filters_process_and_converts_nanoseconds(self):
        path = self.write_xml(
            displayed_surface_row(1, "16669500", 1)
            + displayed_surface_row(2, "33339000", 3)
            + displayed_surface_row(3, "99999999", 4, process="Other App")
        )

        durations, frames, timestamps = MODULE.parse_samples(path, "Waykin AR Lab")

        self.assertEqual(durations, [16.6695, 33.339])
        self.assertEqual(frames, [1, 3])
        self.assertEqual(timestamps, [0.000000001, 0.000000002])
        self.assertEqual(MODULE.frame_sequence(frames), (1, True))

    def test_parser_accepts_grouped_frame_numbers_from_instruments(self):
        path = self.write_xml(
            displayed_surface_row(1, "16669500", 999)
            + displayed_surface_row(2, "16669500", 1000)
            + displayed_surface_row(3, "16669500", 1001)
        )

        _, frames, _ = MODULE.parse_samples(path, "Waykin AR Lab")

        self.assertEqual(frames, [999, 1000, 1001])
        self.assertEqual(MODULE.frame_sequence(frames), (0, True))

    def test_parser_resolves_reused_duration_and_direct_flag_cells(self):
        first = displayed_surface_row(1, "16669500", 1).replace(
            "<duration>16669500</duration>", '<duration id="duration-1">16669500</duration>'
        ).replace('<boolean fmt="Yes">1</boolean>', '<boolean id="direct-1" fmt="Yes">1</boolean>')
        second = displayed_surface_row(2, "16669500", 2).replace(
            "<duration>16669500</duration>", '<duration ref="duration-1"/>'
        ).replace('<boolean fmt="Yes">1</boolean>', '<boolean ref="direct-1"/>')
        path = self.write_xml(first + second)

        durations, frames, timestamps = MODULE.parse_samples(path, "Waykin AR Lab")

        self.assertEqual(durations, [16.6695, 16.6695])
        self.assertEqual(frames, [1, 2])
        self.assertEqual(len(timestamps), 2)

    def test_nearest_rank_percentiles_are_deterministic(self):
        values = [1.0, 2.0, 3.0, 4.0, 5.0]

        self.assertEqual(MODULE.nearest_rank(values, 0.5), 3.0)
        self.assertEqual(MODULE.nearest_rank(values, 0.95), 5.0)
        self.assertEqual(MODULE.nearest_rank(values, 0.99), 5.0)

    def test_parser_uses_schema_mnemonics_instead_of_fixed_positions(self):
        path = self.write_xml("")
        path.write_text(
            """
            <trace-query-result>
              <schema name="displayed-surfaces-interval">
                <col><mnemonic>event-label</mnemonic></col>
                <col><mnemonic>direct-to-display</mnemonic></col>
                <col><mnemonic>duration</mnemonic></col>
                <col><mnemonic>start</mnemonic></col>
              </schema>
              <row>
                <narrative fmt="Direct to Display (Surface 1, Waykin AR Lab (42) :Frame 7 :Surface 1)"/>
                <boolean fmt="Yes">1</boolean>
                <duration>16669500</duration>
                <start-time>2000000000</start-time>
              </row>
            </trace-query-result>
            """
        )

        durations, frames, timestamps = MODULE.parse_samples(path, "Waykin AR Lab")

        self.assertEqual(durations, [16.6695])
        self.assertEqual(frames, [7])
        self.assertEqual(timestamps, [2.0])

    def test_analyze_reports_pass_and_fail_from_thresholds(self):
        passing_thresholds = MODULE.Thresholds(
            minimum_samples=3,
            minimum_span_seconds=2,
            maximum_median_ms=17,
            maximum_p95_ms=34,
            maximum_p99_ms=34,
            maximum_over_34_percent=0,
            maximum_missing_frame_percent=0,
            maximum_frame_ms=34,
        )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            passed = MODULE.analyze(
                [16.0, 17.0, 33.0], [1, 2, 3], [0.0, 1.0, 2.0], passing_thresholds
            )

        self.assertTrue(passed)
        self.assertIn("AR3_FRAME_PACING_GATE=PASS", output.getvalue())

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            passed = MODULE.analyze([16.0, 17.0], [1, 2], [0.0, 1.0], passing_thresholds)

        self.assertFalse(passed)
        self.assertIn("FAIL sample_count", output.getvalue())
        self.assertIn("AR3_FRAME_PACING_GATE=FAIL", output.getvalue())

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            passed = MODULE.analyze(
                [16.0, 17.0, 18.0], [1, 2, 2], [0.0, 1.0, 2.0], passing_thresholds
            )

        self.assertFalse(passed)
        self.assertIn("FAIL frame_numbers_strictly_increasing", output.getvalue())


if __name__ == "__main__":
    unittest.main()
