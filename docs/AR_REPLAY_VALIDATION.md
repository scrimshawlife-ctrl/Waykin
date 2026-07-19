# AR Command Replay & Soak Validation (Issue #46)

Deterministic, simulator-only validation of the canonical
runtime → `ARWorldCommand` → host → renderer integration delivered by
PR #45. No wall-clock sleeps: traces drive the production
`CanonicalARSessionRuntime` through explicit `receive()` calls with an
injectable render policy, so deferral pressure is deterministic and never
raycast- or camera-dependent.

## Trace definitions

| Trace | Steps |
|---|---|
| `companion-discovery-pursuit` | spawn → follow → distantPresence → pursuitBegins → pursuitIntensifies → pursuitFades → bondMoment → rest → clear |
| `detach-reattach-restore` | spawn → pursuitBegins → detach → reattach → drain → snapshot(.approaching) → pursuitFades → clear |
| `pursuit-deferral-soak` | spawn + 500 alternating pursuitBegins/pursuitIntensifies updates under a permanently-deferring render policy |
| `mixed-soak` | spawn + 200 iterations cycling distantPresence / pursuitBegins / pursuitFades / behavior(follow) → clear |

## Deterministic replay receipt (OBSERVED, simulator)

- Identical traces replay **byte-identically**: rendered command order,
  final pending queue, final companion state, and max-pending watermark all
  compare equal across independent runs (asserted for both traces and the
  200-iteration mixed soak — >400 rendered commands per run).
- **Maximum pending-command bound under permanent deferral: 4** across 500
  iterations (one slot per stable identity: companion spawn, companion
  update, discovery, threat), asserted every iteration.
- Clear synchronously empties pending work; after detach + reattach a fresh
  host renders **zero** stale commands.
- Stale host teardown is a no-op against a newer host (exactly one live
  command handler survives handover; the newer host keeps rendering).
- Snapshot restoration matrix at trace level: `.noticed` → discovery only;
  `.approaching`/`.close` → threat; `.inactive`/`.fading` → companion only.
- Transient discoveries are removed before unrelated subsequent projections.
- 500-iteration soak leaves canonical gameplay inputs bit-identical.

## Test totals

- New: 9 tests in `AppTests/ARCommandReplaySoakTests.swift` plus the
  `ARCommandReplayFixture.swift` support fixture (traces, harness, receipt).
- Full native suite at this commit: **163/163** passing; UI 9/9; package
  60/60; `make validate` and `make validate-simulator` OVERALL PASS;
  framework-isolation guard clean.

## Evidence boundary

Simulator-only. Physical readability, placement quality, tracking,
thermal, and device lifecycle behavior remain `NOT_COMPUTABLE` and belong
to Issue #41. No production code was changed by this slice.
