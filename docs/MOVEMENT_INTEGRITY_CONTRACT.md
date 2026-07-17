# Movement Integrity Contract

WP3 hardens the existing foreground Companion Walk input path. It does not add a movement capability or change Companion Walk event-generation semantics.

## Ownership

- `RealLocationProvider` adapts Core Location authorization, signal state, and raw `CLLocation` batches into timestamp-ordered `LocationSample` values.
- `MovementIntegrityProcessor` owns real-sample validation, fresh-anchor behavior, speed fallback and stabilization, movement hysteresis, and accepted distance deltas.
- `MovementEngine` owns session transitions, route points, elapsed time, active time, distance, current speed, and average speed.
- `WaykinAppModel` owns permission and foreground lifecycle orchestration. It forwards only accepted `MovementSnapshot` values into Companion Walk and semantic audio.
- Demo Mode remains deterministic and bypasses Core Location filtering.

## Conservative Defaults

| Rule | Default | Conservative rationale |
|---|---:|---|
| Maximum horizontal accuracy | 30 m | Ignore fixes too coarse for initial walking measurement. |
| Maximum sample age | 15 s | Prevent delayed fixes from mutating current state. |
| Maximum future timestamp skew | 2 s | Tolerate minor clock skew without accepting future data. |
| Minimum counted displacement | 1.5 m | Suppress small stationary GPS drift. |
| Maximum walking speed | 4.5 m/s | Reject displacement clearly outside ordinary walking input. |
| Maximum single displacement | 60 m | Bound one accepted segment independently of timing. |
| Stationary threshold | 0.25 m/s | Require a sustained low stabilized speed before stopping. |
| Moving threshold | 0.55 m/s | Require a distinct higher speed before movement begins. |
| Fresh-anchor gap | 15 s | Avoid bridging a prolonged sample gap. |
| Rolling speed window | 3 samples | Reduce single-sample oscillation with minimal lag. |

These values are code-owned in `MovementIntegrityConfiguration.conservativeWalking`. They are safety defaults, not validated physical-device calibration.

## Acceptance Rules

A real sample cannot affect route, metrics, world state, events, or audio when its coordinate or accuracy is invalid; its accuracy is negative or above the limit; its timestamp is stale, too far in the future, duplicated, or out of order; the session is paused or stopped; or its displacement implies non-walking movement.

Negative, unavailable, nonfinite, or implausibly high reported speed falls back to accepted displacement over time. A rolling average and separate moving/stationary thresholds reduce single-sample state oscillation. Distance is monotonic and accumulates only for accepted moving displacement at or above the minimum threshold.

The first valid sample after start, resume, foreground return, or a long sample gap establishes a fresh anchor. It does not create distance, elapsed time, a downstream movement snapshot, an event, or audio.

## Lifecycle

- A real session starts only after When-In-Use authorization is confirmed.
- Duplicate start, pause, resume, and end transitions are rejected or ignored safely.
- Inactive and background transitions stop location updates, pause movement, pause audio, and discard the movement anchor.
- Foreground return resumes only a session suspended by lifecycle handling; a manually paused session stays paused.
- Fatal provider failures stop the active session without exposing provider internals to the user.
- Active sessions are not persisted, so process termination cannot restore stale tracking state.

## Diagnostics And Evidence

Diagnostics contain disposition, accuracy bucket, derived speed, and whether distance accumulated. They contain no coordinates. Physical GPS accuracy, outdoor distance behavior, battery use, and device audio remain unverified until a completed physical-device receipt exists.
