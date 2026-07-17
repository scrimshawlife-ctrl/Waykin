# Waykin AR-2 Physical Validation Protocol

## Preconditions

- Automated validation passes from `agent/ar2-companion-embodiment-swarm`.
- The standard Waykin scheme launches the AR Lab executable.
- A physical ARKit-capable iPhone is selected.

## Test Sequence

1. Launch and confirm a live camera feed.
2. Wait for the status to report active tracking.
3. Aim the center of the display at a horizontal surface.
4. Tap **Place Lira**.
5. Confirm the procedural companion is readable as a spirit-animal form with body, head, ears, tail, glow, shadow, and status indicator hierarchy.
6. Tap **Place Lira** again and confirm clean replacement with a registry count of one companion.
7. Trigger states in order: Idle, Follow, Investigate, Alert, Celebrate, Idle.
8. Confirm every state creates a visibly distinct bounded pose.
9. Spawn Discovery and Threat placeholders and verify they are visually distinct from Lira and each other.
10. Use Clear and verify all entities disappear and the registry count returns to zero.
11. Re-place Lira, background the app, return, and verify tracking recovers or explicitly reports a limited state.
12. Use Reset, re-place Lira, and confirm the session remains usable.

## Evidence Classification

### OBSERVED

Record only behavior directly seen on the device.

### NOT_COMPUTABLE

Do not claim the following from this pass unless specifically measured:

- outdoor readability
- battery impact
- long-duration anchor stability
- walking-driven following
- GPS-to-AR alignment
- production animation quality
- final art suitability

## Receipt

```text
WAYKIN AR-2 DEVICE RECEIPT
Device:
iOS:
Branch:
HEAD:
Camera feed:
Tracking active:
Lira first placement:
Lira replacement:
Idle:
Follow:
Investigate:
Alert:
Celebrate:
Discovery:
Threat:
Clear cleanup:
Background recovery:
Reset recovery:
Console errors:
Final status: WAYKIN_AR2_DEVICE_VALID / WAYKIN_AR2_REPAIR_REQUIRED
```
