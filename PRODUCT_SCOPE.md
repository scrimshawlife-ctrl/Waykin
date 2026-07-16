# Waykin MPOC Product Scope

## Proof Objective

Prove that one reusable movement runtime can drive multiple emotionally and mechanically distinct experiences while preserving companion continuity across sessions.

## Required User Flow

1. Create or select a companion.
2. Choose walk or run.
3. Choose Companion Walk, Orc Pursuit, or Future Self.
4. Start real movement or a deterministic simulation.
5. Observe experience-specific reactions to movement.
6. Pause, resume, and complete the session.
7. View a session summary and outcome.
8. Generate and persist one deterministic memory.
9. Relaunch and retrieve companion/session continuity.
10. Receive an explained day/night recommendation.

## Required Experiences

### Companion Walk

- Low-pressure following and leading behavior
- Bond progression
- Daytime exploratory variant
- Nighttime protective/lantern variant

### Orc Pursuit

- Pursuer distance, threat, and escape momentum
- Pursuers gain when the user slows or stops
- Pressure freezes or softens while paused
- Bounded difficulty and no unsafe speed rewards
- Daytime raiding-party and nighttime torch/suspense variants

### Future Self

- Adaptive target pace based on current and prior performance
- Bounded lead distance
- Attainable catch windows
- Improvement rewarded separately from raw speed
- Daytime rival and nighttime ghost variants

## Required Surfaces

- Home and companion state
- Activity selection
- Experience selection
- Active session
- Session summary
- Memory history
- `PHONE_MAP`
- `AUDIO_ONLY`
- `DEMO_MODE`

`PHONE_AR` is optional until the required loop is stable.

## Required Nonfunctional Properties

- No external credential required
- Denied location permission does not break the app
- Deterministic fixed-input simulation
- Local persistence across termination/relaunch
- Typed domain models
- Testable providers for location, motion, and clock
- Presentation-neutral experience output
- Explicit handling of unavailable context

## Explicit Exclusions

Marketplace, creator tooling, multiplayer, social feed, payments, subscriptions, cloud accounts, cloud synchronization, Android, Apple Watch, full glasses integration, voice conversation, licensed characters, combat, computer-vision climbing analysis, outdoor climbing guidance, emergency dispatch, and seasonal live operations.

## Acceptance Status

Use exactly one:

- `WAYKIN_MPOC_VALID`
- `WAYKIN_MPOC_PARTIAL`
- `WAYKIN_MPOC_BLOCKED`

`VALID` requires direct evidence for every completion-gate signal in `IDEA.md`.
