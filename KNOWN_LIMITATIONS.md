# Waykin Known Limitations

## Package Level (VALID)
- Core engines and typed state
- Deterministic simulation
- Test coverage for repaired contracts
- Canonical validation harness (make validate)

## Simulator Runtime (this pass)
- XCODEGEN_UI_TEST_TARGET_VALID: PASS (type: bundle.ui-testing)
- WAYKIN_UI_TESTS_DISCOVERED: PASS
- WAYKIN_UI_TESTS_EXECUTED: PASS (7 tests discovered and run)
- APP_LAUNCHES: PASS
- DEMO_MODE_IS_REACHABLE: PASS
- MAPKIT_RENDERING: PARTIAL (basic Map view present in ActiveSessionView and builds)
- CALM_DAY_WALK_VISIBLE_RUNTIME: PARTIAL (flow in UI + test attempts)
- Similar for other scenarios
- SWIFTDATA_RELAUNCH_PERSISTENCE: PARTIAL (SwiftData wiring + ModelContainer present; full relaunch test not yet automated in harness)

## Still NOT_COMPUTABLE (require physical device or fuller implementation)
- PHYSICAL_DEVICE_LOCATION=NOT_COMPUTABLE
- AUDIO_DEVICE_PLAYBACK=NOT_COMPUTABLE
- PHONE_AR_RUNTIME=NOT_COMPUTABLE
- AR_GLASSES_RUNTIME=NOT_COMPUTABLE
- OUTDOOR_ROUTE_ACCURACY=NOT_COMPUTABLE

These must be directly observed before marking PASS.
