# AGENTS.md — Waykin Engineering Contract

This file governs autonomous and assisted engineering work in this repository.

## Objective

Build and validate `WAYKIN_MPOC` as a coherent executable vertical slice. Do not substitute plans, schemas, or placeholder files for implementation.

## Read First

Before changing code, read:

1. `IDEA.md`
2. `PRODUCT_SCOPE.md`
3. `ARCHITECTURE.md`
4. `DEMO_SCRIPT.md`
5. `ROADMAP.md`

## Required Working Method

1. Inspect the repository and establish the current build/test baseline.
2. Preserve existing working behavior unless replacement is necessary and validated.
3. Implement the smallest complete slice supporting the current roadmap phase.
4. Run relevant builds and tests after each material change.
5. Repair observed failures before expanding scope.
6. Update documentation only to reflect verified repository state.

## Scope Rules

Required MPOC capabilities:

- Walk and run sessions
- Real and simulated movement providers
- Shared Movement Engine
- Modular Experience Engine
- Companion Walk, Orc Pursuit, and Future Self
- Day/night variants
- Local persistence
- Deterministic memories and recommendations
- Demo Mode
- Map and audio presentation
- Tests and run documentation

Out of scope unless explicitly authorized:

- Marketplace or creator SDK
- Multiplayer or social feed
- Payments, subscriptions, accounts, or cloud sync
- Android, Apple Watch, or glasses applications
- Voice conversation
- Licensed content
- Computer-vision climbing analysis
- Outdoor climbing guidance
- Emergency services integration

## Architecture Invariants

- The Movement Engine owns sensor/session state, not experience rules.
- The Experience Engine consumes movement snapshots and emits presentation-neutral events and commands.
- Experience implementations must not directly control GPS, persistence, navigation, audio playback, or AR rendering.
- Demo Mode must exercise the same domain and experience code as real movement.
- Safety-critical logic must be deterministic and must not depend on an LLM.
- External credentials must not be required to build or demonstrate the MPOC.
- Incomplete functionality must be explicitly marked.

## Quality Rules

- Prefer working code over speculative abstraction.
- Avoid global mutable state and force unwraps in production paths.
- Use typed domain models; avoid untyped dictionaries.
- Handle denied permissions, missing sensors, empty history, and unavailable environmental data.
- Keep fixed-input experience behavior deterministic.
- Add tests for every experience rule and persistence boundary changed.
- Do not fabricate test, build, device, or runtime results.

## Provenance

Use these labels in engineering reports:

- `OBSERVED`: directly verified
- `INFERRED`: supported conclusion
- `SPECULATIVE`: future opportunity
- `NOT_COMPUTABLE`: insufficient evidence or unperformed validation

## SHADOW Lane

Detect and report only concrete drift or defects:

- Build drift
- Scope drift
- Architectural coupling
- Missing validation
- Unsupported claims
- Unhandled failure paths
- Nondeterministic behavior
- Unsafe interaction design

## FORECAST Lane

Infer only from evidence:

- What can reasonably be completed next
- Which architecture supports the next phase
- Which limitations block expansion
- Which proof points were actually demonstrated

## Validation Gate

Never emit `WAYKIN_MPOC_VALID` unless every signal in the completion gate in `IDEA.md` has been directly verified. Unperformed validation is `NOT_COMPUTABLE`.

## Final Implementation Receipt

Every substantial build pass must report:

- Baseline and environment
- Files changed and purpose
- Implemented capability by subsystem
- Exact build and test commands
- Exact observed results
- Demo scenarios verified
- SHADOW findings
- Known limitations
- Final status: `WAYKIN_MPOC_VALID`, `WAYKIN_MPOC_PARTIAL`, or `WAYKIN_MPOC_BLOCKED`
- One next recommended build objective
