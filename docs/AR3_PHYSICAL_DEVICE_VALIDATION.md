# AR-3 Physical-Device Validation

## Evidence

- Date: 2026-07-17
- Runtime repair revision: `344ded6147d5919642a1ecd4a4e488240d38acc1`
- Allocation-repair base revision: `e2524fa3ed8fce0df22b72cdeb37150377b60cf1`
- Allocation-repair production-source identity:
  - `App/AR/ARPlacementResolver.swift`: `25851aefb60df7056427fd94acad548899e521a5c91cc11f60044b15f3076ab6`
  - `App/AR/ARSessionCoordinator.swift`: `7ca5a28a645ee4dc057f0514a32dcb8054a543087979f6962bbb3a0333d51a73`
  - `App/AR/Companion/CompanionEntityFactory.swift`: `c0a556b8b51c4a8b9812181e29a0e191e6d48b18d0a29c4adb8058d7143181fc`
- Device: iPhone 17 Pro
- Build: signed Debug build of `WaykinARLab`
- Installed bundle: `com.waykin.arlab`
- Physically validated executable SHA-256: `3af1ab7dd0372eda60e3fd045ae212c43eb954028c2c80308eefa0e00af7ac11`
- Allocation-repair executable SHA-256: `9d6f84e9cfc39adafaba527a99eb4021376f722e19f61444f233b9f45f4c46f5`
- Allocation-repair debug dylib SHA-256: `9fb89d49d1bf2af32e14d6dcc0a408174cf4d3ea8c33f07ea5932fd6dbccc4b1`
- Final allocation-repair automated baseline: 60 Swift package tests, 134 native tests, and 9 UI tests passed
- Focused lifecycle/runtime subset: 21 tests passed
- Game Performance trace manifest SHA-256: `0156eddfa4da41fffb8f7cfdc57862de56277d44028a793a6f69e7722633eb47`
- Game Memory trace manifest SHA-256: `4373c0ad802e7b48c0d9a8577322565d934aa16ce35c7c562b0c743e017a33b9`
- Active Activity Monitor trace manifest SHA-256: `b055c1352be0a1ae8203773c067f11ae03c15b1d7f64189ad89c043e001908fa`
- Detailed Allocations trace manifest SHA-256: `40c58a09d98d89e0257bb372d97a1492aa27b00d466618ba20684b6b0dfdf686`
- First protocol attempt trace manifest SHA-256: `278709a049056b2c7e6a477592f79256e9ab439f6470d8e614b01cda144d945e`
- Confirmatory protocol attempt trace manifest SHA-256: `8030d1e8ce4e4c85c02b4d60bc198f3492b7e4ed37fd3d912b0046d17a30ca09`
- Matched idle-control trace manifest SHA-256: `5153bd4c1493cb41aed20fa0ed976b321c25da2eadfcc4307cf6d17eaac4053c`
- Allocation-repair acceptance trace manifest SHA-256: `515f1825ef575c99fb78d7266aa47290314dc6c63e54291c27cefd780e467adc`
- Automated frame-workload trace manifest SHA-256: `10f1cb0459f9b9cfc42918b198febf1472883cb293356f2bdee51a5429266cc7`
- First operator-driven frame-gate trace manifest SHA-256: `9391ea97dec6580f5fc6a7c0ccc29c83834fd041d36a7bbfee77e3c7ea9d9ec2`
- Confirmed operator-driven rolling-window trace manifest SHA-256: `99ecf6fa5f5b038f9d6b2dc2b8acbc26df379b62172e7e700d2113f42cc2fe11`
- Default-window frame-gate trace manifest SHA-256: `d137639c030d30ce467f505711f3fbf59af5c50ab3ebb3bf7408ed288f8a05c4`
- Mirroring-invalidated deferred trace manifest SHA-256: `6f1c96e896db485a1798552b758cbdc3516b44d3be9da6aeedd1d4215ae8a502`
- Accepted physical-phone frame-pacing trace manifest SHA-256: `9df7feb4e59e638df8467652c0d613b5bb688dbfdfbc280c4895834d1af60f36`
- Allocation workload confirmation: the operator confirmed the successful warm-up and followed the three-cycle timing cues during the acceptance capture; Activity Monitor did not record gameplay event markers.
- Frame workload confirmation: with iPhone Mirroring closed, the operator confirmed all three physical-phone cycles completed, each Clear returned entity count to `0`, and the app remained alive and foregrounded.

## Observations

Unless a row explicitly says outdoor, exploratory, pre-repair, or control, the behavioral `PASS` observations below were repeated on the final allocation-repair executable and debug dylib identified above.

| Check | Result | Evidence |
| --- | --- | --- |
| Start Arc places procedural Lira | PASS | Confirmed during the indoor device run. |
| Direct idle, follow, investigate, alert, and celebrate states render | PASS | Confirmed during the indoor device run. |
| Seven-event canonical sequence advances in order | PASS | Confirmed through the final Bond moment. |
| Threat appears and intensifies without changing identity or anchor | PASS | Threat appearance and in-place intensification were confirmed. |
| Threat disappears when pursuit fades | PASS | Removal was confirmed during the canonical sequence. |
| Final celebration ends the demo session | PASS | Final state and normal session closure were confirmed. |
| Manual Discovery places its engineering placeholder | PASS | Confirmed during the indoor device run. |
| Clear removes rendered entities | PASS | Confirmed during the indoor device run. |
| Background and foreground recovery | PASS | The repaired build cleared the prior run and rendered entities, resumed tracking, and placed Lira from a fresh Start Arc after reopen. |
| Tracking interruption recovery | NOT_COMPUTABLE | Backgrounding does not exercise an ARKit interruption callback. |
| Battery and thermal behavior | NOT_COMPUTABLE | A retained 10-second performance window reported nominal thermal state, but neither sustained thermal behavior nor battery use was characterized. |
| Bounded outdoor placement and anchor stability | PASS | During the confirmed outdoor run, Lira placed successfully and remained usable while the tester moved approximately 2-3 meters around the anchor; no failure was reported. |
| Outdoor canonical arc and cleanup | PASS | Start Arc, the complete threat and celebration sequence, and Clear completed successfully outdoors. |
| Outdoor background and foreground recovery | PASS | The prior run cleared, tracking resumed, and a fresh Start Arc placed Lira after reopen. |
| Sunlight readability | NOT_COMPUTABLE | No sunlight-readability observation was supplied. This remains an M8 Outdoor Alpha characterization item. |
| Exploratory frame pacing | PASS_BOUNDED | Across a retained 4.184-second Game Performance window, 251 target-frame records averaged 16.736 ms; p95 and p99 were 16.6695 ms, the maximum was 33.339 ms, and one frame-number gap occurred. This bounded observation does not cover the complete three-cycle workload and is not proof of sustained 60 FPS or zero dropped frames. |
| Exploratory active-process footprint | PASS_BOUNDED | In a separate Activity Monitor trace, the central 45-second interval increased by 4.50 MiB and the final cleared 20-second interval remained flat at 439.69 MiB, within a 437.44-439.69 MiB range. This was not captured under the predeclared allocation protocol and does not establish a leak-free runtime or an allocation budget. |
| Exploratory Metal allocated-size stability | PASS_BOUNDED | In a separate Game Memory trace, Metal allocated size remained at 176.86 MiB throughout the retained 59.93-second interval. |
| Pre-repair retained-memory attempts | FAIL | Two protocol-conforming three-cycle captures exceeded the predeclared `+10 MiB` footprint-growth budget: `450.74 -> 492.00 MiB` (`+41.26 MiB`) and `483.08 -> 512.24 MiB` (`+29.16 MiB`). The second capture also exceeded the `5 MiB` final-stability budget with a `10.91 MiB` range. |
| Matched cleared-idle control | PASS | With the same warmed process and no scene cycles, median footprint remained effectively flat at `480.94 -> 481.03 MiB` (`+0.09 MiB`) with a `0.09 MiB` final range, attributing the failed growth to the cycle workload rather than idle AR session drift. |
| Scene-anchor cleanup | PASS | A native regression test confirms `AREntityRegistry.clear()` removes registered `AnchorEntity` instances from `ARView.scene.anchors`; the retained footprint was not caused by scene anchors remaining registered. |
| Repaired retained-memory gate | PASS | After reusing immutable procedural meshes/materials and disabling unused automatic environment texturing, the operator-confirmed three-cycle capture moved from a `455.49 MiB` initial median to a `434.20 MiB` final median (`-21.29 MiB`). The `1.02 MiB` final range passed the `5 MiB` stability budget. Activity Monitor did not independently mark gameplay event timing. |
| Allocation-repair outdoor regression | PENDING | The earlier bounded outdoor run used the pre-repair executable. The final repaired executable still requires a bounded outdoor placement, arc, cleanup, and visual-readability regression before integration. |
| Allocation-repair frame-pacing gate | PASS | With iPhone Mirroring closed, the exact repaired candidate retained 5,410 Waykin-attributed direct-to-display samples across 90.6653 seconds. Median, p95, and p99 were each `16.6695 ms`; 3 samples exceeded 34 ms (`0.0555%`); 24 frame slots were missing (`0.4417%`); frame numbers were strictly increasing; and the maximum was `41.6737 ms`. Every predeclared numeric threshold passed, and the operator confirmed all three cycles, cleanup after each, and foreground liveness. |
| Absolute production memory and leak freedom | NOT_COMPUTABLE | The passing gate proves bounded post-warm-up retained-memory behavior for this workload only. Aggregate allocation traces and framework-managed graphics pools are not before-and-after states and do not establish an absolute production budget or leak freedom. |

## Final repaired-executable outdoor regression gate

Run this gate against the already identified allocation-repair executable SHA-256 `9d6f84e9cfc39adafaba527a99eb4021376f722e19f61444f233b9f45f4c46f5` and debug-dylib SHA-256 `9fb89d49d1bf2af32e14d6dcc0a408174cf4d3ea8c33f07ea5932fd6dbccc4b1`. Verify both build-artifact hashes before installation, install that artifact, and cold-launch the installed bundle. A rebuild, source change, signing change that replaces either binary, or different hash invalidates the result and requires the relevant validation ladder to be repeated for the new candidate.

1. Record the date, general weather/light condition, outdoor surface type, device, installed bundle, executable SHA-256, and debug-dylib SHA-256. Do not record a route, image, camera transform, latitude, or longitude.
2. Launch `WaykinARLab` outdoors, wait for active tracking, and aim at usable ground.
3. Press **Start Arc**. Confirm entity count `1` and that Lira remains fixed relative to a selected ground feature while the tester moves approximately 2-3 meters around it. Record any visible jump, continuous drift, or tracking loss as a failure.
4. Complete the seven-event arc with **Next Event** or **Run Arc**. Confirm the displayed canonical sequence, Lira's investigate/alert/follow/celebrate states, one stable threat that raises entity count to `2`, intensifies in place, and is removed on pursuit fade so the count returns to `1`; confirm final completion and no duplicate companion.
5. Keep the AR Lab active outdoors for at least five minutes total while observing placement and tracking. Press **Clear** and confirm the rendered scene and entity count return to `0`.
6. Background and reopen the app. Confirm the prior run remains cleared with entity count `0`, tracking recovers, and a fresh **Start Arc** places exactly one Lira with entity count `1`.
7. Press **Clear** again and confirm entity count `0`. Record outdoor readability for the observed conditions. Record direct-sunlight readability as `NOT_COMPUTABLE` unless direct sunlight was actually present.
8. Record each criterion as `PASS`, `FAIL`, or `NOT_COMPUTABLE`, plus the total observed duration. A verbal confirmation without candidate identity and per-criterion results is supporting context, not a complete gate receipt.

The gate passes only if placement, bounded anchor stability, entity-count transitions, the canonical arc, in-place threat lifecycle, cleanup, background/reopen recovery, and fresh placement all pass on that exact executable and debug dylib without a crash or unrecoverable tracking failure. Readability must be reported for the observed outdoor conditions. Direct-sunlight characterization is an M8 item and does not become proven by an overcast, shaded, dusk, or indoor run.

This is an isolated AR Lab regression. It does not prove physical Companion Walk integration, GPS behavior, movement integrity, audio behavior, battery life, sustained thermal behavior, or production outdoor-alpha readiness.

## Decision

M2 companion embodiment and the M3 deterministic indoor runtime-integration gate are validated on the final repaired executable. An earlier executable passed the bounded outdoor run, and the repaired executable passes the operator-confirmed post-warm-up retained-memory gate and predeclared 90-second frame-pacing gate. The repaired executable still requires its bounded outdoor regression before integration, so M3 is not yet merge-ready and M4 must not begin. Sunlight readability remains unreported and is deferred to M8 Outdoor Alpha.

The validation is limited to the isolated AR Lab. It does not validate sunlight readability, sustained battery or thermal behavior, M4 locomotion or eye contact, M5 discovery gameplay, M6 threat gameplay, a complete AR Companion Walk, or the broader M8 outdoor-alpha goals.
