# AR-3 Frame-Pacing Validation Protocol

## Purpose

Measure whether the exact repaired AR-3 candidate maintains bounded target-frame pacing during repeated deterministic scene cycles. This protocol does not prove sustained outdoor-alpha performance, battery life, thermal stability, or a production frame-rate guarantee.

## Candidate identity

- Base source revision: `e2524fa3ed8fce0df22b72cdeb37150377b60cf1`
- Device UDID: `00008150-000A6C120CB8401C`
- `App/AR/ARPlacementResolver.swift`: `25851aefb60df7056427fd94acad548899e521a5c91cc11f60044b15f3076ab6`
- `App/AR/ARSessionCoordinator.swift`: `7ca5a28a645ee4dc057f0514a32dcb8054a543087979f6962bbb3a0333d51a73`
- `App/AR/Companion/CompanionEntityFactory.swift`: `c0a556b8b51c4a8b9812181e29a0e191e6d48b18d0a29c4adb8058d7143181fc`
- Executable SHA-256: `9d6f84e9cfc39adafaba527a99eb4021376f722e19f61444f233b9f45f4c46f5`
- Debug-dylib SHA-256: `9fb89d49d1bf2af32e14d6dcc0a408174cf4d3ea8c33f07ea5932fd6dbccc4b1`

Verify both build-artifact hashes before installation. A rebuilt or replaced binary is a different candidate and cannot inherit this result.

## Preconditions

- Use the recorded iPhone 17 Pro with the display awake and the installed `com.waykin.arlab` bundle foregrounded.
- Close iPhone Mirroring and operate the physical phone; remote presentation prevents Waykin from being attributed as direct-to-display.
- Use a stable indoor surface so tracking or placement failure does not confound frame pacing.
- Complete one **Start Arc -> Run Arc -> Clear** warm-up and verify **Demo arc complete** before recording.
- Confirm tracking is active and entity count is `0`.

## Capture

The guarded capture helper verifies the exact candidate hashes, records the operator-driven workload in immediate mode, preserves uniquely named evidence, exports the required table, hashes the trace manifest, and runs the analyzer:

```sh
make validate-ar3-frame-pacing
```

The operator must provide an unlocked attached device, camera permission, a usable visible surface, and the three timed scene cycles. XCUITest can separately prove the deterministic workload and cleanup assertions, but its test-runner overlay changes direct-to-display compositing and therefore cannot establish the numeric frame-pacing gate. `WAYKIN_AR3_AUTOMATED=1` is retained for that supporting behavioral evidence only; do not treat its frame metrics as acceptance evidence.

### Manual equivalent

Record the app with the Instruments **Animation Hitches** template for 90 seconds. Its deferred recording mode retains the displayed-surface table required by this protocol without Game Performance's bounded high-frequency rolling store. Choose a new UTC-stamped capture ID and paths that do not already exist; do not append to an earlier trace:

```sh
CAPTURE_ID=20260718T000000Z
TRACE=/private/tmp/waykin-ar3-frame-pacing-$CAPTURE_ID.trace
XML=/private/tmp/waykin-ar3-frame-pacing-$CAPTURE_ID.xml
xcrun xctrace record \
  --template 'Animation Hitches' \
  --device 00008150-000A6C120CB8401C \
  --attach 'Waykin AR Lab' \
  --time-limit 90s \
  --output "$TRACE"
```

This template choice is evidence-driven: a 15-second diagnostic retained 921 target frames across 15.37 seconds and exported the same `displayed-surfaces-interval` schema consumed by the analyzer. Game Performance was rejected after `--window 90s` retained only about 28.45 seconds under its storage bound, while omitting `--window` selected its default five-second rolling window. The candidate, workload, metrics, and predeclared thresholds are unchanged.

1. Keep the cleared camera view idle for the first 10 seconds after recording begins.
2. Complete three **Start Arc -> Run Arc -> Clear** cycles between seconds 10 and 60.
3. Keep the cleared camera view idle from seconds 60 through 90.
4. Confirm the app remains alive, tracking remains recoverable, every cycle completes, and entity count returns to `0` after each Clear.

Use the target-frame duration records attributed to the `Waykin AR Lab` process. Preserve the trace manifest hash and report the retained sample count, median, p95, p99, maximum, and the percentage of samples above 34 milliseconds.

Export and analyze the target process's displayed surfaces:

```sh
xcrun xctrace export \
  --input "$TRACE" \
  --xpath '//trace-toc[1]/run[1]/data[1]/table[@schema="displayed-surfaces-interval"]' \
  --output "$XML"
python3 scripts/analyze_ar3_frame_pacing.py \
  "$XML"
```

The analyzer's exit code and `AR3_FRAME_PACING_GATE` line cover the numeric thresholds below. The operator must record that all three cycles completed, each Clear returned entity count to `0`, and the app remained foregrounded; the trace does not contain gameplay event markers. The dedicated UI test provides repeatable supporting evidence for those behaviors, but not the numeric frame gate.

The focused analyzer tests run with:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s scripts/Tests \
  -p 'test_analyze_ar3_frame_pacing.py'
```

## Predeclared M3 acceptance

- At least 4,500 target-frame duration samples are retained across the 90-second capture.
- The first-to-last retained target-frame timestamp span is at least 88 seconds.
- Median target-frame duration is no more than 17.5 milliseconds.
- p95 target-frame duration is no more than 20 milliseconds.
- p99 target-frame duration is no more than 34 milliseconds.
- No more than 1 percent of retained target-frame durations exceed 34 milliseconds.
- Frame numbers are strictly increasing and no more than 1 percent of frame slots are missing.
- No target-frame duration exceeds 100 milliseconds.
- The app remains alive and all three scene cycles complete with cleanup.

A pass establishes bounded frame pacing for this exact 90-second indoor workload and candidate only. It does not establish zero dropped frames, sustained 60 FPS, low allocation rate, leak freedom, outdoor tracking quality, battery behavior, or thermal stability.

## Accepted result

- Capture ID: `20260718T052748Z`
- Trace manifest SHA-256: `9df7feb4e59e638df8467652c0d613b5bb688dbfdfbc280c4895834d1af60f36`
- Exact executable and debug-dylib hashes matched the candidate identity above.
- Operator confirmation: three physical-phone cycles completed, every Clear returned entity count to `0`, and the app remained alive and foregrounded with iPhone Mirroring closed.
- Retained samples: `5,410` across `90.6653` seconds.
- Median / p95 / p99: `16.6695 / 16.6695 / 16.6695 ms`.
- Above 34 ms: `3` samples (`0.0555%`).
- Missing frame slots: `24` (`0.4417%`); frame numbers strictly increasing.
- Maximum: `41.6737 ms`.
- Result: `AR3_FRAME_PACING_GATE=PASS`.
