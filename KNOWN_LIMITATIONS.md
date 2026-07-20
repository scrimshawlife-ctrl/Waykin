# Waykin Known Limitations

## Observed Validated Surface

- Package build and tests pass for the deterministic walking loop.
- Demo Mode runs without location permission or HealthKit.
- Native app build passes in the available Xcode simulator environment.
- SwiftData persistence covers Bond and session memories.
- Home primary CTA is **Begin Walk** (real location walk). **Demo Walk** is secondary; UI tests still target `waykin.beginWalk` on Demo for determinism.
- Real walking sessions use foreground When-In-Use location only and pause when the app becomes inactive or enters the background.
- Real samples pass through conservative accuracy, age, ordering, displacement, and walking-speed checks before affecting session state.
- The iPhone app contains optional HealthKit read enrichment for recent steps and daily walking/running distance.

## NOT_COMPUTABLE Until Direct Device Evidence

- Physical-device GPS behavior.
- Outdoor route accuracy.
- Battery behavior during real walks.
- Physical audio playback behavior.
- Headphone and Bluetooth routing behavior.
- Interaction with podcasts, music, route changes, lock screen, and background execution.
- Outdoor audibility, playback latency, and audio-related battery impact.
- Physical-device interruption behavior.
- HealthKit authorization, denial, empty-sample, refresh, and lifecycle behavior on a physical iPhone.
- Whether Apple Watch-originated samples appear with the expected timing in the current iPhone HealthKit queries.
- Whether the conservative defaults are appropriate across devices, terrain, urban canyons, and accessibility-related walking patterns.

A **PARTIAL** outdoor AR operator receipt exists (`docs/design/receipts/OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md`, pre-mitigation continuity/audio notes). That is **not** a full outdoor COH PASS. Do not mark GPS, outdoor audio, battery, or outdoor AR quality as PASS from simulator, package evidence, or that PARTIAL alone. Issue #41 requires a daylight re-walk on current main tip.

The local field-test receipt is engineering evidence only. It has no remote analytics or automatic upload, and receipt creation does not validate physical behavior. Timestamps may reveal session timing when a receipt is shared, field-test ratings remain manual, and receipt-related battery impact is unverified.

Receipt schema v2 can distinguish semantic cue requests from software-stage playback diagnostics. That detail does not prove human audibility, accessory behavior, or perceived loudness, and it intentionally omits asset paths, raw error payloads, device or accessory names, port labels, coordinates, volume, raw health samples, sample identifiers, and related identifiers.

The recorded route is measurement support for the active Companion Walk only. It is not navigation-grade, does not provide route planning or guidance, and has no background-location guarantee. Battery impact is not characterized.

**Session map (#121 + #155 + #179):** The App may show a **presentation-only** polyline of the *current* session (`WalkPathTrace`: ≥4 m spacing, 400-point cap, never persisted, no coordinates in VoiceOver). Trace is fed by accepted real GPS fixes **and** demo synthetic movement `routePoints`. An optional **planned walking route** (`PlannedWalkRoute` via MapKit walking directions: place search / long-press) is a visual guide only—not turn-by-turn navigation, not movement/event truth, not persisted. Both surfaces clear on session **start, end, and fail**. Core `MapPresentationState` is legacy demo-controller-only and is not the App MapKit surface. Outdoor map readability remains `NOT_COMPUTABLE` until Issue #41 device evidence.

## HealthKit Limitations

- HealthKit enrichment is optional and non-authoritative.
- Successful authorization-request completion does not prove that read access was granted.
- Code-side hardening (#104) distinguishes request completion, metric availability, empty data, and query failure in the app adapter; **physical-device** authorization/deny/empty/lifecycle evidence remains NOT_COMPUTABLE until exercised on a named iPhone.
- The current previous-hour step band measures recent activity volume, not live walking cadence.
- Enrichment refresh runs at real-walk start/resume and on a bounded periodic interval while the walk is active (see `docs/design/HEALTHKIT.md`); device battery impact of refresh is NOT_COMPUTABLE.
- Daily walking/running distance may soft-fill energy presentation when steps are unavailable; it does not select events or Bond.
- Waykin does not write workouts to HealthKit.

## Apple Watch Limitations

Waykin currently has no watchOS target, Watch app, `HKWorkoutSession`, `HKLiveWorkoutBuilder`, workout-session mirroring, WatchConnectivity session, live heart-rate stream, Watch controls, Watch haptics, or Watch summary surface.

Apple Watch may indirectly contribute samples to HealthKit, but that is not implemented or validated Waykin Watch integration. No Watch behavior may be claimed until an issue-scoped implementation and paired-device protocol are completed.

## Accessibility Evidence

### OBSERVED Simulator Evidence

- At the largest simulator text-size setting, the accessibility UI test confirms traversal through the presence, phrase, initial quiet Path status, controls, and waiting map in the intended order.
- In that initial quiet state, the simulator exposes Path status as "The path is quiet," Time as "0 seconds," and Distance as "0 meters."
- The UI assertion measures the active-session Pause and End controls at 44 points or larger. This is simulator evidence, not a physical-device reachability or ergonomics claim.

### Code-Inspected Behavior

- Elapsed time and distance retain compact visible formats while exposing singular/plural VoiceOver values.
- All pursuit states have distinct human pressure descriptions in source.
- Active-session Pause, Resume, and End control labels have source-level minimum dimensions of 48 by 48 points.
- Pressure changes outer-ring thickness as well as color.
- The view consults Reduce Motion when selecting bounded animation.
- Located and waiting map states have coordinate-free semantic descriptions in code.

### NOT_COMPUTABLE Until Direct Device Evidence

- VoiceOver speech quality, navigation, and announcement timing on physical devices.
- Physical-device Dynamic Type fit, control ergonomics, and interaction with other accessibility settings.
- Live hardware Reduce Motion toggling during an active session.
- Located-marker accessibility behavior during a physical walk.
- Future Watch accessibility, haptic distinguishability, and control ergonomics.

## Deferred Product Scope

- Walking is the MVP focus.
- Event variety is intentionally bounded.
- Bundled WAV cues are produced sound design (owner-rendered, 2026-07-19); physical audibility, loudness balance, and outdoor masking remain NOT_COMPUTABLE until device walks.
- No advanced spatial audio is implemented; the adapter uses only restrained stereo pan.
- Production Companion Walk uses **app-target** AR (`App/AR/**`, session full-screen cover). `WaykinARLab` remains a separate engineering surface. Outdoor tracking quality is PARTIAL historically and requires re-walk for PASS (#41).
- Physical-device outdoor AR quality claims remain evidence-gated; do not equate code mitigations (#125 continuity, diagnostics) with outdoor PASS.
- Apple Watch implementation remains reference-only until promoted.
- There is no multiplayer, backend, account system, marketplace, creator SDK, generalized narrative engine, generative AI, or generalized analytics platform.
- Run, cycle, hike, and climb model values may exist for compatibility, but they are not validated MVP capabilities.

## Compatibility Debt

Deprecated proof-of-concept runtime types for Orc Pursuit and Future Self remain only for temporary source/API compatibility. They are not returned by recommendations, Demo Mode, variants, or primary UI, and should not be expanded unless the solo MVP expansion gate is satisfied.