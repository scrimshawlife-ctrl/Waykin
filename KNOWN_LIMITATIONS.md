# Waykin Known Limitations

This document lists gates that remain unproven until executed under full Xcode + simulator.

## Package Level (currently validated)
- Core engines and typed state
- Deterministic simulation
- Test coverage for repaired contracts

## Native Execution (NOT_COMPUTABLE until proven in simulator)

- SIMULATOR_APP_LAUNCH=NOT_COMPUTABLE
- CALM_DAY_WALK_VISIBLE_RUNTIME=NOT_COMPUTABLE
- NIGHT_ORC_PURSUIT_VISIBLE_RUNTIME=NOT_COMPUTABLE
- FUTURE_SELF_INTERVAL_VISIBLE_RUNTIME=NOT_COMPUTABLE
- MAPKIT_RENDERING=NOT_COMPUTABLE
- SWIFTDATA_RELAUNCH_PERSISTENCE=NOT_COMPUTABLE
- PHYSICAL_DEVICE_LOCATION=NOT_COMPUTABLE
- AUDIO_RUNTIME=NOT_COMPUTABLE
- PHONE_AR_RUNTIME=NOT_COMPUTABLE

These items must be directly observed in a booted simulator session with the native app before they can be marked PASS.

Do not infer success from package tests or build success alone.
