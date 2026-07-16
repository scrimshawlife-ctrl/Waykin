# Waykin Known Limitations

## Observed Validated Surface

- Package build and tests pass for the deterministic walking loop.
- Demo Mode runs without location permission.
- Native app build passes in the available Xcode simulator environment.
- SwiftData persistence covers Bond and session memories.
- The app exposes one primary Begin Walk path.

## NOT_COMPUTABLE Until Direct Device Evidence

- Physical-device GPS behavior.
- Outdoor route accuracy.
- Battery behavior during real walks.
- Physical audio playback behavior.
- Headphone or spatial-audio behavior.
- Physical-device interruption behavior.

No physical walk receipt has been filled in this repository. Do not mark these as PASS from simulator or package evidence.

## Deferred Product Scope

- Walking is the MVP focus.
- Event variety is intentionally bounded.
- Production audio assets may remain incomplete.
- There is no AR implementation.
- There is no multiplayer.
- There is no backend.
- There are no accounts or authentication.
- There is no marketplace or creator SDK.
- There is no generalized narrative engine or generative AI.
- Run, cycle, hike, and climb model values may exist for compatibility, but they are not validated MVP capabilities.

## Compatibility Debt

Some earlier proof-of-concept code for Orc Pursuit and Future Self remains. It should not be expanded or advertised as current product scope unless the solo MVP expansion gate is satisfied.
