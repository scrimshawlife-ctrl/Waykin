# Waykin Known Limitations

## Package Level (VALID)
- Core engines and typed state
- Deterministic simulation
- 17 package tests (make test)
- Canonical validation harness (make validate): OVERALL PASS

## Simulator Runtime
- Package + generation: VALIDATED (17 tests)
- UI smoke harness: targets 7 tests in WaykinUITests
- MapKit rendering: present in ActiveSessionView
- SwiftData + @Query memory restoration: implemented and used in app
- RealLocationProvider + live session start/pause/resume/end: implemented
- Demo scenarios (CALM_DAY_WALK / NIGHT_ORC_PURSUIT / FUTURE_SELF_INTERVAL): wired

## Still NOT_COMPUTABLE / Pending Physical Device
- PHYSICAL_DEVICE_LOCATION
- AUDIO_DEVICE_PLAYBACK
- PHONE_AR_RUNTIME
- AR_GLASSES_RUNTIME
- OUTDOOR_ROUTE_ACCURACY
- Full real GPS drift, battery, and background behavior

See docs/PHYSICAL_DEVICE_WALK_VALIDATION.md for the manual protocol. No filled receipt yet.

These must be directly observed before marking PASS.
