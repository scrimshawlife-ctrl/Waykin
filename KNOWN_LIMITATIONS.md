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

The recorded route is measurement support for the active Companion Walk only. It is not navigation-grade, does not provide route planning or guidance, and has no background-location guarantee. Battery impact is not characterized.

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
