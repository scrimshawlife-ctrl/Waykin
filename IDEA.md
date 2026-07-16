# WAYKIN

## Status

`MINIMUM_PROOF_OF_CONCEPT`

## Product Definition

Waykin is a movement-driven experience platform in which persistent companions, rivals, hunters, guides, and environmental entities react to how a user moves through the physical world.

Waykin is not primarily a fitness tracker, virtual pet, route mapper, cosmetic skin system, or standalone AR game.

Its core thesis is:

> Real-world movement becomes more meaningful when it is experienced through a persistent character, adaptive challenge, or living narrative.

## Core User Loop

```text
Choose movement
→ Choose experience
→ Begin real or simulated session
→ Experience reacts to movement
→ Companion or entity behavior changes
→ Session concludes
→ Memory is created
→ Relationship or progression changes
→ New experiences are recommended
```

## Primary Differentiator

Most movement products optimize:

```text
Movement → Metrics → Comparison
```

Waykin optimizes:

```text
Movement → Emotion → Interaction → Memory → Story
```

## Experience Packs

A skin is functional, not merely cosmetic. An Experience Pack may define visual entities, entity count, behavior, objective, movement rules, difficulty, personality, animation, audio, narrative, rewards, progression, memory rules, time variants, compatible activities, and safety constraints.

Initial packs:

- `COMPANION_WALK`: calm companionship, exploration, and bond growth
- `ORC_PURSUIT`: adaptive pursuit pressure without unsafe speed incentives
- `FUTURE_SELF`: an attainable adaptive rival based on current and historical performance

## Supported Movement

MPOC implementation:

- `WALK`
- `RUN`

Extension boundaries only:

- `ROAD_CYCLE`
- `HIKE`
- `INDOOR_CLIMB`

Long-term activities may include trail cycling, outdoor climbing, skiing, paddling, exploration, and recovery.

## Canonical Architecture

```text
World Context
      ↓
Movement Engine
      ↓
Experience Engine
      ↓
Companion Runtime
      ↓
Memory and Progression
      ↓
Presentation Adapters
```

The Experience Engine consumes canonical movement state and emits presentation-neutral commands. It must not directly own GPS, persistence, UI navigation, audio playback, or AR rendering.

Presentation surfaces:

- `PHONE_MAP`
- `AUDIO_ONLY`
- `PHONE_AR`
- `WATCH`
- `FUTURE_GLASSES`

AR glasses are a presentation layer, not the foundation of the runtime.

## Time Context

Canonical states:

- `DAWN`
- `MORNING`
- `MIDDAY`
- `GOLDEN_HOUR`
- `TWILIGHT`
- `NIGHT`
- `DEEP_NIGHT`

Day and night variants must change behavior, audio, interaction density, and tone—not merely color grading.

## Safety and Attention

Canonical attention states:

- `IDLE`
- `LOW_ATTENTION_MOVEMENT`
- `HIGH_ATTENTION_MOVEMENT`
- `PAUSED`
- `RESTING`
- `POST_SESSION`

During high-attention movement, suppress long text and complex controls, prefer brief audio cues, queue nonessential narrative, and never reward dangerous speed.

Waykin is not safety equipment. Unsupported judgments must return `NOT_COMPUTABLE`.

## Active Implementation Decisions

- Target: iPhone-first MPOC
- Required surfaces: `PHONE_MAP`, `AUDIO_ONLY`, `DEMO_MODE`
- Secondary surface: `PHONE_AR`
- Persistence: local-first, preferably SwiftData
- AI: optional; deterministic local logic is mandatory
- Simulation: first-class and must use the same Movement Engine interfaces as real movement

Priority order:

1. Build reliability
2. Complete user loop
3. Deterministic Demo Mode
4. Experience modularity
5. Persistence
6. Tests
7. Audio
8. Map presentation
9. Lightweight AR
10. Future abstractions

## Unresolved Questions

- Should activity or experience be selected first?
- Is there one persistent companion with functional forms or multiple persistent entities?
- What pursuit pressure remains motivating rather than unpleasant?
- How should Future Self combine recent average and personal-best performance?
- Which events deserve persistent memories?
- Should time variants be automatic, manually overridable, or both?
- What minimum iOS target balances API support and reach?
- Can RealityKit be added without delaying the vertical slice?

Unverified answers remain `NOT_COMPUTABLE`.

## Deferred Opportunities

- Cycling, hiking, climbing, skiing, paddling, and recovery adapters
- Creator SDK and Waykin Studio
- Experience marketplace
- Social expeditions and asynchronous rival ghosts
- Consumer AR glasses adapters
- Weather, biome, calendar, sleep, and recovery-aware recommendations

These opportunities must not expand the current MPOC scope.

## Active Risks

- AR destabilizes the vertical slice
- Demo Mode diverges from the real Movement Engine
- Experience logic couples to UI or sensors
- Pursuit mechanics encourage unsafe behavior
- External services become mandatory
- Persistence schemas drift during rapid implementation
- Documentation claims exceed observed implementation

## Completion Gate

`WAYKIN_MPOC_VALID` requires all of the following to be observed:

```text
BUILD_SUCCEEDS
TESTS_PASS
DEMO_MODE_LAUNCHES
COMPANION_CREATION_PERSISTS
COMPANION_WALK_COMPLETES
ORC_PURSUIT_COMPLETES
FUTURE_SELF_COMPLETES
DAY_VARIANT_RUNS
NIGHT_VARIANT_RUNS
SESSION_SUMMARY_APPEARS
MEMORY_IS_CREATED
MEMORY_PERSISTS
RECOMMENDATION_IS_EXPLAINED
LOCATION_DENIAL_DOES_NOT_BREAK_APP
NO_EXTERNAL_CREDENTIAL_REQUIRED
```

Allowed terminal states:

- `WAYKIN_MPOC_VALID`
- `WAYKIN_MPOC_PARTIAL`
- `WAYKIN_MPOC_BLOCKED`
