# Waykin Roadmap

Waykin advances by proving one bounded layer before promoting the next. This roadmap is directional; GitHub issues and accepted milestone documents authorize implementation.

## Status Legend

- **IMPLEMENTED** — present in the repository.
- **VALIDATION** — implemented but awaiting required simulator or device evidence.
- **NEAR TERM** — eligible for issue-scoped promotion after current gates pass.
- **RELEASE CANDIDATE** — a bounded post-MVP product candidate with defined gates, but no implementation authority until promoted.
- **FUTURE** — preserved as design reference only.

## Current Vertical Slice

| Capability | Status | Promotion gate |
|---|---|---|
| Walking session loop | IMPLEMENTED | Continue regression coverage |
| Lira companion runtime | IMPLEMENTED | Preserve one-companion scope |
| Bond progression | IMPLEMENTED | Validate memory and persistence behavior |
| Semantic audio (produced WAVs) | VALIDATION | Physical outdoor audibility / interruption evidence |
| Real-walk movement integrity | VALIDATION | Repeated outdoor walk receipts (#41) |
| Path progress (semantic) | IMPLEMENTED | Not navigation-grade; outdoor path feel open |
| AR app adapter + real-walk commands | IMPLEMENTED (frozen) | Outdoor tracking re-walk (#41 PARTIAL historically) |
| HealthKit read enrichment | IMPLEMENTED | Code hardened (#104); physical HK evidence open |
| Local session memories | IMPLEMENTED | Preserve concise, privacy-bounded format |
| Deterministic Demo Mode | IMPLEMENTED | Keep parity with the canonical loop |

## Near-Term Milestones

### 1. Physical Loop Proof

- Validate GPS acceptance under representative walks.
- Validate audio playback, interruption recovery, and safe silence.
- Review privacy-filtered receipts against subjective notes.
- Calibrate only from direct device evidence.

### 2. AR Outdoor Evidence

- Preserve `WaykinCore` as ARKit/RealityKit-free.
- App-target AR command bridge and MVP freeze are **shipped** (maintenance/defects only).
- Validate placement continuity, tracking loss, interruption recovery, battery, and thermal behavior **on device** after mitigations.
- Do not create alternate AR gameplay truth or continuous walker re-anchor without product ratification.

### 3. Experience Tuning

- Production cue WAVs are **shipped**; outdoor loudness and masking remain open.
- Event weights already light-tuned for companion-first pacing; revise only from outdoor receipts.
- Improve Lira presentation while preserving stable semantic behavior.
- Remove deprecated compatibility surfaces only through migration issues.

### 4. HealthKit Device Evidence

- Code-side read hardening (#104) is **shipped** (request completion vs availability, ordered refresh, soft energy only).
- Collect physical-device authorization, empty-sample, denial, and lifecycle evidence.
- Preserve: previous-hour step band = activity volume, not live cadence; Demo never blocked by Health.

## Post-MVP AI Director Release Candidates

**Authority: RELEASE_CANDIDATE_REFERENCE_ONLY.** These candidates are product-planning targets, not implementation authorization. The deterministic Waykin runtime remains complete and functional without cloud AI.

### RC-AI-01 — Conversation Director

Use a provider-neutral AI Director, with Grok as one replaceable adapter candidate, to propose bounded Lira dialogue from approved semantic context.

Promotion gates:

1. Provider-neutral request/response contracts and deterministic fallbacks.
2. Privacy review of every transmitted field.
3. Validation, length, frequency, interruption, and content-consistency controls.
4. Provider timeout, outage, malformed-response, and prompt-injection tests.
5. Physical-device latency, audio coexistence, battery, network, and cost evidence.
6. Explicit user control to disable cloud AI and clear retained AI-related data.

The model may propose dialogue. It may not change movement, events, pursuit, Bond, memories, rewards, session outcome, or safety controls.

### RC-AI-02 — Pathfinder Director

Use the AI Director to propose experiential route intent and rank mapping-provider-supplied candidate places. An approved routing service remains authoritative for geometry, legality, reachability, closures, and return-path feasibility.

Promotion gates:

1. Conversation-independent provider-neutral AI contracts.
2. Route-intent schema with confidence and explicit assumptions.
3. Authoritative map validation of every accepted candidate.
4. Rejection of fabricated, unreachable, restricted, private, or unsupported locations.
5. Immediate cancellation, rerouting, pause, and return controls.
6. Physical-device privacy, latency, battery, network, and degraded-mode evidence.

The model may suggest where an experience should lead. It may not act as turn-by-turn navigation, generate authoritative geometry, alter movement acceptance, or own session outcome.

Conversation and Pathfinder receive independent ship/no-ship decisions. Neither requires promotion of a generalized autonomous world director.

See `docs/design/AI_DIRECTOR_RELEASE_CANDIDATES.md` for the bounded architecture, non-goals, promotion sequence, and evidence requirements.

## Apple Watch Reference Sequence (FUTURE / REFERENCE ONLY)

**Authority: REFERENCE_ONLY.** This section does **not** authorize implementation, target creation, or entitlement expansion. Status is deferred foresight until a promoted GitHub issue and architecture review exist.

When (and only when) promoted, the intended sequence is:

1. Optional HealthKit workout writing on iPhone with explicit authorization and duplicate protection.
2. Minimal watchOS target with Ready, Active, and Summary surfaces.
3. `HKWorkoutSession` and live workout builder for outdoor walking.
4. Workout-session mirroring with idempotent iPhone reconciliation.
5. Non-authoritative Lira, pursuit, Bond, phrase, and haptic synchronization.
6. Paired-device validation for lifecycle, disconnection, recovery, permissions, battery, thermal, audio, and haptics.

The iPhone remains canonical for movement integrity, event generation, Lira, pursuit, Bond, memories, and final session outcome. Do not implement watchOS, mirroring, or WatchConnectivity from this roadmap section alone.

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
- Generalized autonomous world director beyond the two bounded AI release candidates
- AR-glasses dependency

## Decision Rule

A future capability becomes implementable only when:

1. Current evidence gates are satisfied.
2. A GitHub issue defines the user outcome, allowed systems, frozen systems, tests, and non-goals.
3. Canonical scope and architecture documents are updated when necessary.
4. Architecture review or an ADR approves material boundary changes.

See `WAYKIN_SPEC.md`, `docs/design/AI_DIRECTOR_RELEASE_CANDIDATES.md`, `docs/design/HEALTHKIT.md`, `docs/canonical/CURRENT_CAPABILITY_MATRIX.md`, and `docs/governance/DOCUMENT_AUTHORITY.md`.