# Waykin Brand Guide

## Brand Foundation

**Core theme:** Outdoor movement + living companion + soft spatial computing + mythic discovery + modern engineering.

**Emotional tone:** Movement, Bond, Discovery, Adaptation, Presence, Memory, and day/night transformation.

## Palette

| Token | Hex | Intended use |
|---|---|---|
| Midnight | `#0B1020` | Foundations and deep background |
| Deep Forest | `#14372F` | Ground, landscape, and natural depth |
| Trail Teal | `#43C7B8` | Movement, semantic signal, and Lira glow |
| Sunrise Gold | `#F4B860` | Companionship, memory, and warmth |
| Mist White | `#F5F7F3` | Clarity and primary text |
| Stone | `#89938D` | Secondary information |
| Twilight Violet | `#7168A6` | Night and liminal states |
| Threat Ember | `#C7613A` | Bounded pursuit pressure |

## Typography

Visual assets should use a clean geometric sans-serif with slightly rounded forms, strong titles, and high legibility. Repository documentation remains standard Markdown and system typography.

## Companion Direction

Lira should read as an original, species-neutral, friendly but mysterious luminous presence. The design must not imitate a dog, Pokémon, or recognizable franchise creature.

## Asset Classes

- **CONCEPT VISUAL** — Hero art, companion walk scenes, movement-to-memory scenes, and social previews.
- **ENGINEERING DIAGRAM** — Architecture, runtime, validation, evidence, and collaboration flows.
- **BRAND ASSET** — Wordmark, symbol, lockup, and app-icon concepts.
- **REAL** — Captured simulator or physical-device output. None is implied by a concept asset.

## Current Repository Assets

| Path | Class | Purpose | Product claims |
|---|---|---|---|
| `docs/assets/waykin-hero.svg` | CONCEPT VISUAL | README hero and product-direction artwork | None |
| `docs/assets/runtime-architecture.svg` | ENGINEERING DIAGRAM | Semantic runtime and platform-adapter boundary | Must remain aligned with `ARCHITECTURE.md` |
| `docs/assets/contributor-flow.svg` | ENGINEERING DIAGRAM | Issue-scoped delivery workflow | Must remain aligned with `CONTRIBUTING.md` |

### Hero Details

| Field | Value |
|---|---|
| Format | Accessible SVG |
| Canvas | `2400 × 900` |
| Subject | Walker, mountain valley, dawn light, and luminous companion |
| Source | Generated specifically for the Waykin repository and refined into a repository-native vector asset |

The hero includes an accessible title and description and is designed to remain legible on GitHub in both light and dark interfaces.

## Provenance

Visual concepts are project-owned placeholders generated specifically for Waykin using available creative tools. No external stock imagery or third-party licensed artwork is incorporated.

Generated art must be reviewed for:

- Originality and franchise separation
- Product-scope accuracy
- Accessibility text
- Light/dark README readability
- Correct classification as concept, engineering, brand, or real evidence

## Accessibility

- Every SVG must include a meaningful `<title>` and `<desc>`.
- README and documentation embeddings must include useful alt text.
- Do not place essential instructions only inside an image.
- Preserve sufficient contrast between text, paths, nodes, and backgrounds.
- Keep diagrams understandable from surrounding prose when images do not load.

## Labeling Rule

Every README visual must disclose its evidence class. Concept visuals and engineering diagrams are not proof of implemented application functionality, validation status, or physical-device behavior.

## Replacement Plan

Replace or supplement concept visuals with real simulator screenshots and physical-device captures after those surfaces are validated. Preserve earlier concept assets as historical design-direction references where useful.

## Usage

- Optimize assets for repository rendering and review performance.
- Prefer SVG for diagrams and brand-forward artwork when practical.
- Keep semantic text in surrounding Markdown rather than embedding essential documentation in an image.
- Keep engineering diagrams synchronized with their canonical source documents.
- Do not use an artwork-derived claim to update the capability matrix or validation status.