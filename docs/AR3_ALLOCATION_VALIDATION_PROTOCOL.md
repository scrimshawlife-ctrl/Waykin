# AR-3 Allocation Validation Protocol

## Purpose

Measure whether repeated deterministic AR-3 cycles retain app-process memory after scene cleanup. This protocol does not set an absolute ARKit or RealityKit memory budget and does not prove leak freedom.

## Preconditions

- Use the signed allocation-candidate `WaykinARLab` build identified by executable SHA-256 in `docs/AR3_PHYSICAL_DEVICE_VALIDATION.md`.
- Run on the recorded physical iPhone with the app foregrounded and the display awake.
- Keep the device unlocked on the AR Lab screen throughout the capture.
- Before recording, complete one successful **Start Arc -> Run Arc** warm-up cycle, verify the AR Lab reports **Demo arc complete**, then press **Clear** so lazily initialized meshes, materials, render paths, and framework resources are resident.
- Confirm that no companion, discovery, or threat entity remains before recording starts.

## Capture

Record the app with the Instruments **Activity Monitor** template for 180 seconds. The extended duration prevents Instruments attachment latency from consuming either evaluated window.

1. After the warm-up cycle, keep the cleared foreground camera view idle while Instruments attaches.
2. After Instruments reports that recording started, leave the scene cleared through the initial baseline window, then complete three **Start Arc -> Run Arc -> Clear** cycles between seconds 20 and 90.
3. Keep the cleared foreground scene idle for the rest of the recording.

Use the `activity-monitor-process-live` table's `Memory` (`memory-physical-footprint`) samples.

## Predeclared M3 Acceptance

- Initial baseline: median physical footprint from seconds 10 through 20.
- Final plateau: median physical footprint from seconds 150 through 180.
- Retained-growth budget: final median is no more than 10 MiB above the initial median.
- Final-stability budget: maximum minus minimum physical footprint during seconds 150 through 180 is no more than 5 MiB.
- The app remains alive for the complete capture.

A pass establishes only bounded post-warm-up retained-memory behavior for three deterministic AR-3 cycles on the tested build and device. It does not establish an absolute production memory budget, sustained outdoor behavior, battery behavior, or absence of leaks.
