# Waykin Brand Guide

## Brand Foundation

**Core theme:** Outdoor movement + living companion (Lira) + soft spectral presence + mythic discovery + modern engineering.

**Emotional tone:** Movement, Bond, Discovery, Adaptation, Presence, Memory, and day/night transformation.

**Visual climate (locked):** **Echo** — cool mist day, indigo-earth night, guide teal, bond gold, hunter violet.
**Product companion name:** **Lira** (Living Familiar structural family under Echo materials).

**Token source:** App presentation uses `WK_TOKENS_v0.2` (`App/Theme/WKTokens.swift`). Night is **not** an invert of day.

## Palette (Echo climate)

| Token | Day hex | Night hex | Intended use |
|---|---|---|---|
| Foundation | `#E4E8EC` cool mist | `#12151C` indigo-earth | App backgrounds |
| Surface | `#F7F5F2` | `#1E2430` | Cards / sheets |
| Ink / text | `#141820` | `#E6EAF0` | Primary text |
| Secondary text | `#4A535E` | `#9AA3B0` | Supporting copy |
| Guide teal | `#3F8F8A` | `#4A9E98` | Trail invitation, primary actions |
| Bond gold | `#D4A45A` | `#B8894A` | Relationship, chest mark, bond UI |
| Rival copper | `#D17A4A` | `#C46B3A` | Cadence / challenge accents |
| Hunter violet | `#5C4E7A` | `#6A5A8A` | Pressure presence (never color alone) |
| Sanctuary moss | `#A8C4B5` / `#5F7F72` | `#5F7F72` | Safety / resolve |
| Caution amber | `#E0B040` | `#E0B040` | Route uncertainty + icon + text |

### Retired as primary UI tokens

The previous concept palette (Midnight `#0B1020`, Deep Forest `#14372F`, Trail Teal `#43C7B8`, Sunrise Gold `#F4B860`, Mist White `#F5F7F3`) remains historical for older concept art. **Do not** use it for new App chrome.

## Typography

Prefer a clean geometric sans-serif (DM Sans / Source Sans 3 / system). Strong titles, high outdoor legibility. Repository documentation remains standard Markdown and system typography.

## Companion Direction

**Lira** should read as an original, species-neutral, friendly but slightly uncanny luminous presence (Living Familiar). The design must not imitate a dog, Pokémon, or recognizable franchise creature.

Identity anchors (visual production):

1. Tapered non-canid head
2. Amber chest bond mark
3. Trailing filament / plume

Hunter language: distortion, delayed echo, asymmetry — not gore.

## Asset Classes

- **CONCEPT VISUAL** — Hero art, companion walk scenes, movement-to-memory scenes, and social previews.
- **ENGINEERING DIAGRAM** — Architecture, runtime, validation, evidence, and collaboration flows.
- **BRAND ASSET** — Wordmark, Bond Filament symbol, lockup, and app-icon concepts.
- **REAL** — Captured simulator or physical-device output. None is implied by a concept asset.
- **PRODUCTION CANDIDATE** — Tokens and marks imported into App presentation; not proof of outdoor QA.

## Icon and raster authority (#150)

| Layer | Authority | Notes |
| ----- | --------- | ----- |
| **SVG masters** | `docs/assets/brand/production/*.svg` | Design source for app icon + bond filament mark |
| **Reference rasters** | `docs/assets/brand/production/appicon-rasters/` | Review/export reference; not compiled by Xcode |
| **Build truth** | `App/Resources/Assets.xcassets` (AppIcon + imagesets) | What the binary ships |
| **In-app icons** | `App/Theme/WKIcons.swift` | SF Symbol / vector presentation tokens |

Do not edit only one side. Pipeline: SVG → reference rasters (optional) → xcassets import → App. Concept PNGs under `docs/assets/brand/` without a production path are **not** build authority.

## Current Repository Assets

| Path | Class | Purpose | Product claims |
|---|---|---|---|
| `docs/assets/waykin-hero.svg` | CONCEPT VISUAL | README hero and product-direction artwork | None |
| `docs/assets/runtime-architecture.svg` | ENGINEERING DIAGRAM | Semantic runtime and platform-adapter boundary | Must remain aligned with `ARCHITECTURE.md` |
| `docs/assets/contributor-flow.svg` | ENGINEERING DIAGRAM | Issue-scoped delivery workflow | Must remain aligned with `CONTRIBUTING.md` |
| `App/Theme/WKTokens.swift` | PRODUCTION CANDIDATE | Echo day/night theme for App UI | Presentation only |
| `docs/assets/brand/*` | BRAND / CONCEPT | Historical and interim lockups | Replace with Bond Filament production mark over time |

## Provenance

Visual concepts are project-owned placeholders generated specifically for Waykin. Echo tokens originate from the isolated Waykin-Design package (CANDIDATE_v0.2) under a direction lock accepting Echo + Lira.

Generated art must be reviewed for:

- Originality and franchise separation
- Product-scope accuracy
- Accessibility text
- Light/dark README readability
- Correct classification as concept, engineering, brand, real, or production candidate

## Accessibility

- Every SVG must include a meaningful `<title>` and `<desc>`.
- README and documentation embeddings must include useful alt text.
- Do not place essential instructions only inside an image.
- Preserve sufficient contrast between text, paths, nodes, and backgrounds.
- **Never use color alone** for hunter, caution, pause, or tracking-loss states (pair with icon/shape/text).
- Outdoor device contrast remains **NOT_COMPUTABLE** until a physical walk validates tokens.

## Labeling Rule

Every README visual must disclose its evidence class. Concept visuals and engineering diagrams are not proof of implemented application functionality, validation status, or physical-device behavior.

## Replacement Plan

1. Tokens in App (this guide + `WKTokens`) — **started**
2. Bond Filament production mark + app icon sizes
3. Core icon set
4. Lira production rig art
5. Replace concept hero with real simulator/device captures after validation

## Usage

- Optimize assets for repository rendering and review performance.
- Prefer SVG for diagrams and brand-forward artwork when practical.
- Keep semantic text in surrounding Markdown rather than embedding essential documentation in an image.
- Keep engineering diagrams synchronized with their canonical source documents.
- Do not use an artwork-derived claim to update the capability matrix or validation status.
