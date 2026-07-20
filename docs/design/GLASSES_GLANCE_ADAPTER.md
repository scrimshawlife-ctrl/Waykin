# Glasses Glance Adapter (#115)

```yaml
document_id: WAYKIN-WEARABLES-GLANCE-001
version: 0.1
status: SHIPPED_MOCK_FIRST
expansion: RATIFIED
physical_glasses: NOT_COMPUTABLE
feature_flag_default: OFF
```

## Outcome

Phone-stays-in-pocket **2D glance** surface for an active walk: presence phrase, path/pressure status, elapsed, distance, and cue-adjacent state. Presentation-only; driven by existing `CompanionPresencePresentation`.

## Architecture

```text
CompanionPresencePresentation (read-only)
  → GlassesGlanceSnapshot (privacy-safe; no coordinates / health)
  → GlassesGlanceAdapter (protocol)
       ├─ NullGlassesGlanceAdapter     (default — flag off)
       └─ DefaultGlassesGlanceAdapter
            └─ GlassesHUDTransport
                 ├─ MockGlassesHUDTransport     (tests / Mock Device Kit stand-in)
                 └─ MetaWearablesHUDTransport   (partner SDK slot; unavailable until linked)
```

| Path | Role |
| ---- | ---- |
| `App/Wearables/**` | Adapter, snapshot, feature flag, transports |
| `App/WaykinApp.swift` | Session start/advance/pause/end publish hooks |

**Frozen:** WaykinCore, AR production, Bond, persistence semantics, audio cue meanings.

## Feature flag

| Mechanism | Behavior |
| --------- | -------- |
| Default | **Off** (`UserDefaults` false) |
| `UserDefaults` key `waykin.wearables.glassesGlance.enabled` | Persist enable |
| Process arg `-WAYKIN_GLASSES_GLANCE` / `=YES` | Lab / UI-test enable |

When off: `NullGlassesGlanceAdapter` — zero connects, zero publishes.

## Privacy

Glance snapshot **never** includes:

- latitude / longitude
- HealthKit / steps / energy samples
- precise location or camera data

## Meta Device Access Toolkit

Partner Swift SDK is not bundled in this repo until select-partner linking is available. `MetaWearablesHUDTransport` is the isolated integration point:

- without SDK: `connectionState = .unavailable` (no false physical claims)
- lab: optional mock fallback for adapter plumbing tests

Physical Ray-Ban Display legibility, audibility, and battery remain **NOT_COMPUTABLE** without a named-device receipt.

## Tests

`AppTests/GlassesGlanceAdapterTests.swift` — snapshot privacy, null no-op, mock publish, factory defaults, app model demo publish when enabled.

## Non-goals

- World-anchored AR on glasses
- Meta account / publishing
- Android
- New gameplay systems
