# Waykin Known Limitations

## Observed Validated Surface

- Package build and tests pass for the deterministic walking loop.
- Demo Mode runs without location permission.
- Native app build passes in the available Xcode simulator environment.
- SwiftData persistence covers Bond and session memories.
- The app exposes one primary Begin Walk path.
- Real walking sessions use foreground When-In-Use location only and pause when the app becomes inactive or enters the background.
- Real samples pass through conservative accuracy, age, ordering, displacement, and walking-speed checks before affecting session state.

## NOT_COMPUTABLE Until Direct Device Evidence

- Physical-device GPS behavior.
- Outdoor route accuracy.
- Battery behavior during real walks.
- Physical audio playback behavior.
- Headphone and Bluetooth routing behavior.
- Interaction with podcasts, music, route changes, lock screen, and background execution.
- Outdoor audibility, playback latency, and audio-related battery impact.
- Physical-device interruption behavior.
- Whether the conservative defaults are appropriate across devices, terrain, urban canyons, and accessibility-related walking patterns.

No physical walk receipt has been filled in this repository. Do not mark these as PASS from simulator or package evidence.

The local field-test receipt is engineering evidence only. It has no remote analytics or automatic upload, and receipt creation does not validate physical behavior. Timestamps may reveal session timing when a receipt is shared, field-test ratings remain manual, and receipt-related battery impact is unverified.

Receipt schema v2 can now distinguish semantic cue requests from software-stage playback diagnostics such as planner acceptance or suppression, asset lookup, audio-session setup, player activity, interruptions, stop or fade requests, observed player stops, and coarse output-route categories. That added detail still does not prove human audibility, accessory behavior, or perceived loudness, and it intentionally omits asset paths, raw error payloads, device or accessory names, port labels, coordinates, volume, and related identifiers.

The recorded route is measurement support for the active Companion Walk only. It is not navigation-grade, does not provide route planning or guidance, and has no background-location guarantee. Battery impact is not characterized.

## Accessibility Evidence

### OBSERVED Simulator Evidence

- At the largest simulator text-size setting, the accessibility UI test confirms traversal through the presence, phrase, initial quiet Path status, controls, and waiting map in the intended order.
- In that initial quiet state, the simulator exposes Path status as "The path is quiet," Time as "0 seconds," and Distance as "0 meters."
- The UI assertion measures the active-session Pause and End controls at 44 points or larger. This is simulator evidence, not a physical-device reachability or ergonomics claim.

### Code-Inspected Behavior

- Elapsed time and distance retain their compact visible formats while exposing singular/plural VoiceOver values.
- All pursuit states have distinct human pressure descriptions in source, and Path status is their sole semantic owner; the presence element does not duplicate behavior or pressure speech.
- Active-session Pause, Resume, and End control labels have source-level minimum dimensions of 48 by 48 points.
- Pressure changes the outer-ring thickness as well as color, providing a presentation-only non-color distinction.
- The view consults SwiftUI's Reduce Motion environment when selecting its bounded animation. Live setting changes have not been verified on hardware.
- Located and waiting map states have coordinate-free semantic descriptions in code. The located-marker state has not been exercised as physical runtime evidence.

### NOT_COMPUTABLE Until Direct Device Evidence

- VoiceOver speech quality, navigation, and announcement timing on physical devices.
- Physical-device Dynamic Type fit, control ergonomics, and interaction with other accessibility settings.
- Live hardware Reduce Motion toggling during an active session.
- Located-marker accessibility behavior during a physical walk.

## Deferred Product Scope

- Walking is the MVP focus.
- Event variety is intentionally bounded.
- Bundled WAV files are deterministic engineering placeholders, not production sound design.
- No advanced spatial audio is implemented; the adapter uses only restrained stereo pan.
- There is no AR implementation.
- There is no multiplayer.
- There is no backend.
- There are no accounts or authentication.
- There is no marketplace or creator SDK.
- There is no generalized narrative engine or generative AI.
- There is no generalized telemetry or analytics platform.
- Run, cycle, hike, and climb model values may exist for compatibility, but they are not validated MVP capabilities.

## Compatibility Debt

Deprecated proof-of-concept runtime types for Orc Pursuit and Future Self remain only for temporary source/API compatibility. They are not returned by recommendations, Demo Mode, variants, or primary UI, and should not be expanded unless the solo MVP expansion gate is satisfied.
