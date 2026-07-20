# Waykin Roadmap

Waykin advances by proving one bounded layer before promoting the next. This roadmap is directional; GitHub issues and accepted milestone documents authorize implementation.

## Status Legend

- **IMPLEMENTED** — present in the repository.
- **VALIDATION** — implemented but awaiting required simulator or device evidence.
- **NEAR TERM** — eligible for issue-scoped promotion after current gates pass.
- **FUTURE** — preserved as design reference only.

## Current Vertical Slice

| Capability | Status | Promotion gate |
|---|---|---|
| Walking session loop | IMPLEMENTED | Continue regression coverage |
| Lira companion runtime | IMPLEMENTED | Preserve one-companion scope |
| Bond progression | IMPLEMENTED | Validate memory and persistence behavior |
| Semantic audio | VALIDATION | Physical-device playback evidence |
| Real-walk movement integrity | VALIDATION | Repeated outdoor walk receipts |
| HealthKit read enrichment | IMPLEMENTED | Harden authorization/query semantics and collect device evidence |
| Local session memories | IMPLEMENTED | Preserve concise, privacy-bounded format |
| Deterministic Demo Mode | IMPLEMENTED | Keep parity with the canonical loop |

## Near-Term Milestones

### 1. Physical Loop Proof

- Validate GPS acceptance under representative walks.
- Validate audio playback, interruption recovery, and safe silence.
- Review privacy-filtered receipts against subjective notes.
- Calibrate only from direct device evidence.

### 2. AR Presentation

- Preserve `WaykinCore` as ARKit/RealityKit-free.
- Complete app-target rendering of existing semantic commands.
- Validate placement, tracking loss, interruption recovery, battery, and thermal behavior on device.
- Do not create alternate AR gameplay truth.

### 3. Experience Tuning

- Replace engineering tones with production sound design.
- Tune event weights and cooldowns without adding a narrative engine.
- Improve Lira presentation while preserving stable semantic behavior.
- Remove deprecated compatibility surfaces only through migration issues.

### 4. HealthKit V1 Hardening

- Correct read-authorization semantics without claiming access HealthKit cannot prove.
- Fix enrichment ordering so real-session context always receives the result.
- Distinguish no data, unavailable service, unreadable data, and query failure.
- Clarify that the existing previous-hour step band measures recent activity volume rather than live cadence.
- Add bounded refresh lifecycle and direct-device evidence.
- Decide whether daily walking distance has a bounded product purpose.

## Apple Watch Reference Sequence

Apple Watch remains non-authorizing until promoted through issue scope and architecture review. When promoted, implement in this order:

1. Optional HealthKit workout writing on iPhone with explicit authorization and duplicate protection.
2. Minimal watchOS target with Ready, Active, and Summary surfaces.
3. `HKWorkoutSession` and live workout builder for outdoor walking.
4. Workout-session mirroring with idempotent iPhone reconciliation.
5. Non-authoritative Lira, pursuit, Bond, phrase, and haptic synchronization.
6. Paired-device validation for lifecycle, disconnection, recovery, permissions, battery, thermal, audio, and haptics.

The iPhone remains canonical for movement integrity, event generation, Lira, pursuit, Bond, memories, and final session outcome.

## Future Reference

The following remain non-authorizing until promoted through `docs/governance/SPEC_PROMOTION_PROCESS.md`:

- Apple Watch implementation beyond the approved reference contract
- Additional activity modes
- Experience Pack runtime
- Broader companion roster
- Backend accounts and cloud synchronization
- Multiplayer and social systems
- Marketplace or creator SDK
- Economy and LiveOps
- Generalized AI Director or generative runtime
- AR-glasses dependency

## Decision Rule

A future capability becomes implementable only when:

1. Current evidence gates are satisfied.
2. A GitHub issue defines the user outcome, allowed systems, frozen systems, tests, and non-goals.
3. Canonical scope and architecture documents are updated when necessary.
4. Architecture review or an ADR approves material boundary changes.

See `WAYKIN_SPEC.md`, `docs/design/HEALTHKIT.md`, `docs/canonical/CURRENT_CAPABILITY_MATRIX.md`, and `docs/governance/DOCUMENT_AUTHORITY.md`.