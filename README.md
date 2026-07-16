# Waykin

Waykin is a movement-driven experience platform where persistent companions, rivals, hunters, guides, and environmental entities react to how a person moves through the physical world.

## Current objective

`WAYKIN_MPOC`

The immediate goal is to prove this loop:

```text
Choose movement
→ Choose experience
→ Move or simulate movement
→ Experience reacts
→ Companion state changes
→ Session completes
→ Memory is created
→ Companion remembers
→ A context-aware experience is recommended
```

## Minimum proof of concept

The first implementation targets iPhone and must provide:

- Walking and running sessions
- Deterministic Demo Mode
- A shared Movement Engine
- A modular Experience Engine
- Companion Walk
- Orc Pursuit
- Future Self
- Day and night variants
- Local persistence
- Session summaries and memories
- Map and audio presentation
- Lightweight phone AR only if it does not destabilize the build
- Automated tests and reproducible validation

## Repository documents

- [`IDEA.md`](IDEA.md): canonical product definition and active decisions
- [`AGENTS.md`](AGENTS.md): operating contract for Hermes, Grok Build, Codex, and other agents
- [`PRODUCT_SCOPE.md`](PRODUCT_SCOPE.md): MPOC boundaries and completion gate
- [`ARCHITECTURE.md`](ARCHITECTURE.md): target system boundaries
- [`DEMO_SCRIPT.md`](DEMO_SCRIPT.md): deterministic five-minute proof flow
- [`ROADMAP.md`](ROADMAP.md): staged implementation sequence

## Build status

`NOT_COMPUTABLE` — no executable Xcode project has been generated or validated yet.

## Provenance labels

Engineering reports must distinguish:

- `OBSERVED`: directly verified in repository, build output, tests, or runtime behavior
- `INFERRED`: strongly supported conclusion
- `SPECULATIVE`: future opportunity not implemented
- `NOT_COMPUTABLE`: insufficient evidence or unperformed validation
