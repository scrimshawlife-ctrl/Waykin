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

## Future Reference

The following remain non-authorizing until promoted through `docs/governance/SPEC_PROMOTION_PROCESS.md`:

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

See `WAYKIN_SPEC.md`, `docs/canonical/CURRENT_CAPABILITY_MATRIX.md`, and `docs/governance/DOCUMENT_AUTHORITY.md`.