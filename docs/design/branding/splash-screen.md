# Waykin Time-Aware Splash Screen

```yaml
document_id: WAYKIN-SPLASH-001
status: IMPLEMENTED_V1
scope: presentation_only
implementation: App/Splash/WaykinSplashBootstrap.m
```

## Decision

Waykin uses two launch presentation directions selected from the approved concept board:

- **Daytime:** dark, cosmic trail direction.
- **Nighttime:** light, watercolor trail direction.

This intentionally follows the product decision to use the dark composition during the day and the light composition at night.

## Runtime rule

The initial implementation uses the device's local civil time:

```text
07:00 <= local hour < 19:00  -> dark daytime artwork
otherwise                    -> light nighttime artwork
```

The rule is deterministic, offline, and does not request location permission. Astronomical sunrise/sunset switching is deferred because the splash must not create a new location dependency or delay launch.

## Presentation behavior

- Appears once per process launch when the app first becomes active.
- Does not intercept touch input.
- Fades in quickly, holds briefly, then crossfades to the app.
- Is disabled under `-WAYKIN_UI_TESTING` to preserve deterministic UI automation.
- Exposes one accessibility element with identifier `waykin.splash` and label `Waykin. Walk. Bond. Become.`
- Contains no gameplay state, persistence, network access, audio, HealthKit, camera, or location logic.

## Visual contract

Both variants preserve:

- Waykin circular brush emblem.
- `W A Y K I N` title treatment.
- `WALK. BOND. BECOME.` tagline.
- A small companion-presence mark.
- Full-bleed portrait composition with safe central typography.

### Dark daytime variant

- Deep indigo and violet field.
- Sparse star-like points.
- Vertical path/threshold beam.
- White title with violet accent.

### Light nighttime variant

- Warm off-white watercolor field.
- Muted sage wash and contour rings.
- Ink-dark title with earthen accent.
- Lower visual contrast to avoid a harsh white flash while preserving the selected light direction.

## Engineering boundary

This is an app-presentation bootstrap under `App/Splash`. XcodeGen includes it through the existing recursive `App` source declaration. The implementation is isolated from `WaykinCore` and does not alter the bounded movement runtime.

## Follow-up production asset path

When final hand-polished artwork is approved, replace the procedural backgrounds with asset-catalog images while retaining the same switching and accessibility contract:

```text
App/Resources/Assets.xcassets/
  SplashDayDark.imageset/
  SplashNightLight.imageset/
```

Final production exports should be portrait, edge-to-edge, and contain no critical content outside the centered safe region. The logo and text should remain separable from the background master so layout can be tuned without regenerating the art.
