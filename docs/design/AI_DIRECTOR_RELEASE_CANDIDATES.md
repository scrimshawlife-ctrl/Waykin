# AI Director Release Candidates

**Authority: RELEASE_CANDIDATE_REFERENCE_ONLY**

This document identifies two bounded post-MVP candidates for a generalized AI Director. It does not authorize implementation, network access, model-provider integration, prompt storage, user-memory expansion, or gameplay-state mutation.

Waykin remains deterministic and locally authoritative. An AI provider such as Grok may propose language or route intent only through validated, replaceable adapters.

## Candidate Set

### RC-AI-01 — Conversation Director

**Outcome:** Lira can produce context-aware, companion-consistent spoken or displayed dialogue without requiring a generalized narrative engine.

Allowed proposal inputs may include bounded, privacy-reviewed summaries of:

- current semantic world state;
- current companion state;
- Bond band rather than unrestricted raw history;
- time-of-day and coarse environment context;
- recent deterministic event identifiers;
- concise, user-approved memory facts.

Allowed output:

- one bounded dialogue proposal;
- optional semantic delivery metadata such as tone, urgency, or cue category;
- provenance and model-response metadata required for debugging and user transparency.

The deterministic runtime must validate, sanitize, length-bound, rate-limit, and either accept or reject every proposal. Rejection must fall back to local authored dialogue or silence without affecting session completion.

The Conversation Director must not:

- change Bond, movement, events, pursuit, rewards, memories, or session outcome;
- invent safety guidance, medical guidance, or navigational instructions;
- create durable personal profiles without explicit product and privacy approval;
- require connectivity for the canonical walking loop;
- speak continuously or interrupt critical safety and lifecycle controls.

### RC-AI-02 — Pathfinder Director

**Outcome:** Waykin can propose an experiential route intent—such as a calm loop, discovery-oriented walk, or return path—while platform routing and deterministic safety constraints remain authoritative.

Allowed proposal inputs may include bounded, privacy-reviewed summaries of:

- requested duration or distance;
- current accepted movement state;
- route style and accessibility preferences;
- coarse time and environment context;
- candidate points of interest supplied by an approved mapping provider;
- known closures or constraints supplied by authoritative services.

Allowed output:

- route-style intent;
- ranked candidate waypoints or points of interest from the supplied candidate set;
- narrative rationale suitable for companion presentation;
- confidence and explicit assumptions.

The AI Director must never generate authoritative geometry. MapKit or another approved routing provider must calculate the route, and the app must validate legality, reachability, distance, return-path feasibility, and user constraints before presenting it.

The Pathfinder Director must not:

- replace turn-by-turn navigation or claim navigation-grade accuracy;
- fabricate roads, trails, closures, hazards, or points of interest;
- modify movement acceptance or session outcome;
- route the user through unsafe, private, restricted, or unsupported terrain;
- prevent immediate user cancellation, rerouting, pause, or return;
- require cloud AI for the basic Companion Walk loop.

## Shared Architecture Contract

```text
WaykinCore canonical state
        ↓ bounded context projection
AIDirector protocol
        ↓
Provider adapter (Grok candidate; replaceable)
        ↓ untrusted proposal
Validation / policy / rate-limit boundary
        ↓ accepted semantic proposal or fallback
Conversation presentation or routing adapter
```

Required properties:

1. `WaykinCore` remains provider-agnostic and owns all canonical gameplay truth.
2. Grok is one adapter candidate, not a hard-coded product dependency.
3. Every model response is untrusted input.
4. Offline and provider-failure behavior remains functional and testable.
5. Prompts, context projections, schemas, validation, retention, and telemetry are versioned.
6. Raw coordinates, unrestricted route history, raw HealthKit samples, and private memory text are excluded unless separately approved.
7. No model output directly invokes AR, audio, persistence, rewards, movement, or event mutation.

## Promotion Sequence

### Gate 0 — MVP evidence

- Physical walking, audio, lifecycle, privacy, and AR evidence gates are sufficiently stable.
- The deterministic experience remains valuable without generative AI.

### Gate 1 — Provider-neutral contracts

- Define `AIDirector`, request/response schemas, context projections, validation rules, rate limits, cancellation, timeout, and deterministic fallbacks.
- Add contract tests using fixtures only; no production network dependency.

### Gate 2 — Conversation prototype

- Implement Conversation Director behind an internal feature flag.
- Use short-lived session context and authored fallback lines.
- Validate latency, interruption behavior, content consistency, privacy, cost, and offline degradation.

### Gate 3 — Pathfinder prototype

- Implement route-intent proposals using only mapping-provider-supplied candidates.
- Keep routing geometry and safety validation outside the model.
- Validate cancellation, unreachable-waypoint rejection, return-path behavior, battery, privacy, and network degradation.

### Gate 4 — Release-candidate decision

Each candidate receives an independent ship/no-ship decision. Conversation may ship without Pathfinder, and Pathfinder may remain experimental even if Conversation is accepted.

## Required Evidence

- deterministic schema and fallback tests;
- provider timeout, malformed response, refusal, and outage tests;
- prompt-injection and untrusted-context tests;
- privacy review of every transmitted field;
- latency, token/cost, battery, and network measurements;
- physical-device interruption and audio coexistence evidence;
- route validation against authoritative map responses for Pathfinder;
- user control for disabling cloud AI and clearing AI-related retained data;
- documented provider substitution and rollback path.

## Current Decision

| Candidate | Status | Implementation authority |
|---|---|---|
| Conversation Director | RELEASE CANDIDATE / REFERENCE ONLY | Not authorized |
| Pathfinder Director | RELEASE CANDIDATE / REFERENCE ONLY | Not authorized |
| Generalized autonomous world director | FUTURE / REFERENCE ONLY | Not authorized |
| AI-owned gameplay state | EXCLUDED | Prohibited |

Promotion requires an issue defining outcome, allowed and frozen systems, provider/data boundaries, tests, non-goals, rollback, and the exact evidence gate being advanced.