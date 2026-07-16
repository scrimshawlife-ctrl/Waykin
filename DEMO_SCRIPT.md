# Waykin Demo Script

## Terminal Demo

```bash
swift run WaykinDemo
```

The terminal demo is retained as a fast package-level smoke path.

## iOS Demo Mode

1. `make generate`
2. Open `Waykin.xcodeproj`
3. Select the Waykin scheme and an iPhone Simulator
4. Launch the app
5. Tap `Begin Walk`
6. In the active session, use `Run to End`
7. Tap `End`
8. Confirm Session Summary appears
9. Return home and open Memory History

Demo Mode uses the same deterministic walking loop as the core package and does not require location permission.

## Real Walk Path

The `Start Real Walk` button starts the physical-device Core Location path for manual validation. It requests When-In-Use location authorization only when the real walk starts.

Physical GPS behavior, outdoor route accuracy, battery impact, and physical audio behavior remain `NOT_COMPUTABLE` until directly observed on device.
