# AR-1 Physical-Device Validation

## Evidence

- Date: 2026-07-17
- Revision: `a9fc0911894fc78a9e623ad9b4b60bdd731a1e81`
- Device: iPhone 17 Pro
- Build: signed Debug build of `WaykinARLab`
- Installation: `com.waykin.arlab` installed and launched through CoreDevice
- Automated baseline: 60 Swift package tests, 109 native tests, and 9 UI tests passed

## Observations

| Check | Result | Evidence |
| --- | --- | --- |
| Camera session starts | PASS | Camera feed and tracking were observed on device. |
| Tracking recovers after background and reopen | PASS | Tracking recovery was observed after the lifecycle transition. |
| Surface detection | PARTIAL | Detection functions, but physical calibration still needs refinement. |
| Marker placement | PARTIAL | Placement functions, but physical calibration still needs refinement. |
| Same-ID marker replacement | PASS | A second placement removed the original marker so exactly one marker remained. |
| Tracking interruption recovery | NOT_COMPUTABLE | Background recovery does not prove recovery from an AR session interruption. |
| Battery and thermal behavior | NOT_COMPUTABLE | The validation session did not characterize either behavior. |

## Decision

AR-1 is physically runnable and its required camera, tracking, surface detection, placement, replacement, and lifecycle path functions on the tested device. The AR-1 functional gate is validated. Calibration, interruption recovery, battery, and thermal behavior remain explicit follow-up work and must not be represented as complete.

This evidence applies only to the isolated AR Lab shell. It does not validate Lira embodiment, CompanionRuntime integration, discovery or threat rendering, AR gameplay, or an outdoor session.
