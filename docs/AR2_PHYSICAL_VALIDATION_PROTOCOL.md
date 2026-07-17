# Waykin AR-2 Physical Validation Protocol

Do not mark AR-2 valid until the automated gate passes and this protocol is completed on a physical iPhone.

## Automated gate

```bash
swift test
swift test --filter ARPresentationContract
xcodegen generate
make build
make validate
make validate-simulator
git diff --check
```

Verify that this returns no matches:

```bash
grep -RInE '^[[:space:]]*import[[:space:]]+(ARKit|RealityKit)' Sources/WaykinCore
```

## Physical session

1. Launch the Waykin AR Lab executable.
2. Confirm camera feed and normal tracking.
3. Tap **Place Lira**.
4. Confirm a recognizable spirit-animal placeholder appears at plausible scale.
5. Confirm the entity is grounded and has a distinguishable front and rear.
6. Re-place Lira and confirm the prior anchor is replaced rather than duplicated.
7. Trigger `idle`, `follow`, `investigate`, `alert`, `celebrate`, then `idle`.
8. Confirm every state is visually distinguishable and bounded.
9. Confirm the registry count remains stable during state-only updates.
10. Tap a surface to place the retained AR-1 marker and confirm it remains independent of Lira.
11. Press **Clear** and confirm all registered AR entities disappear.
12. Background and foreground the application; confirm recovery or an explicit limited-tracking state.

## Receipt

```text
WAYKIN_AR2_PHYSICAL_VALIDATION
Device:
iOS:
Branch:
HEAD:
Camera feed: PASS/FAIL
Tracking normal: PASS/FAIL
Lira placement: PASS/FAIL
Lira replacement: PASS/FAIL
Idle: PASS/FAIL
Follow: PASS/FAIL
Investigate: PASS/FAIL
Alert: PASS/FAIL
Celebrate: PASS/FAIL
Registry stability: PASS/FAIL
Clear cleanup: PASS/FAIL
Background recovery: PASS/FAIL
Observed defects:
Final status: WAYKIN_AR2_PHYSICAL_VALID / WAYKIN_AR2_REPAIR_REQUIRED
```

## Non-claims

This protocol does not validate outdoor readability, walking-driven follow behavior, long-session battery use, final character art, or production animation quality.
