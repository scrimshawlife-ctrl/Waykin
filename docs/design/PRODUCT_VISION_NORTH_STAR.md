# Waykin Product Vision — North Star

```yaml
document_id: WAYKIN-PRODUCT-VISION-NORTH-STAR-001
version: 1.0
date: 2026-07-29
status: FUTURE_REFERENCE
authority: REFERENCE_ONLY
maturity: FUTURE
evidence_class: OPERATOR_INTENT
does_not_authorize: implementation
parent_ladder: docs/canonical/MVP_TO_VISION_LADDER.md
related:
  - docs/design/AR_PRODUCT_REDESIGN_MAP.md
  - docs/plans/AR_APP_REDESIGN_PLAN.md
  - WAYKIN_SPEC.md
  - docs/SOLO_MVP_SCOPE.md
  - docs/canonical/CURRENT_CAPABILITY_MATRIX.md
  - ROADMAP.md
```

## 1. Purpose

State the **long-term product idea** for Waykin so planning, AR redesign, and fitness/worldbuilding work share one north star.

**This document does not authorize implementation.**  
Binding law remains `docs/SOLO_MVP_SCOPE.md` and `WAYKIN_SPEC.md` until explicitly promoted. See [`../canonical/MVP_TO_VISION_LADDER.md`](../canonical/MVP_TO_VISION_LADDER.md) for the gated path from MVP → this vision.

## 2. North-star statement

> **Waykin is an AR companion platform for real-world movement.**  
> A persistent companion accompanies you on **walks, runs, rides, and other fitness activities** — present in AR when you look up, supportive when you don’t. Over time the world around that companion deepens (**worldbuilding**), and people can **design their own companions and experiences**.

### One-liner variants

| Context | Line |
| ------- | ---- |
| Consumer | Your AR companion for every mile. |
| Product | AR companion + fitness movement + eventual worldbuilding and creator experiences. |
| Engineering | Movement-authoritative sessions; AR-primary presentation; extensible activity, companion, and experience seams. |

## 3. Vision pillars

| Pillar | Intent |
| ------ | ------ |
| **1. AR companion presence** | The companion is the emotional and visual center — designed for AR first, with audio/HUD/map as supporting channels. |
| **2. Real movement** | The product is lived outdoors (and on real routes), not a couch game. Movement is gameplay authority. |
| **3. Multi-activity fitness** | Walk is the proven beachhead; **run, ride, and further activities** expand once integrity, safety, and return-intent are proven per mode. |
| **4. Relationship (Bond)** | Long-term progression is relationship with the companion, not a generic XP treadmill. |
| **5. Worldbuilding** | The companion’s world deepens: lore, places, rituals, pursuit/pressure mythos, memory — still presentation- and content-bounded, not open MMO sim by default. |
| **6. Creator eventual** | Users (and partners) eventually **design companions and experiences** through governed tools/packs — after first-party loop and platform seams are stable. |

## 4. Experience shape (eventual)

```text
User moves (walk / run / ride / …)
        ↓
Movement integrity + activity profile
        ↓
World + events + companion runtime + Bond
        ↓
Presentation
  ★ AR companion in the world (when capable)
  · Audio / haptics support
  · HUD / glance / Watch (when shipped)
  · Map / path (semantic, not nav-cert)
        ↓
Session memory → long-arc relationship + world state
        ↓
(Later) Experience packs · user-designed companions · deeper world arcs
```

## 5. Activity model (eventual)

| Activity | Role in vision | MVP status (binding today) |
| -------- | -------------- | -------------------------- |
| **Walk** | Beachhead; prove loop + AR outdoor | **Only authorized launch activity** |
| **Run** | High-intensity companion pacing | Deferred until walk proven |
| **Ride** (bike / similar) | Speed/distance context; safety-first UI | Deferred |
| Other (hike, etc.) | Only after multi-activity framework exists | Deferred |

**Rule:** New activities are **profiles** on shared movement + companion + AR seams — not separate apps — and each requires integrity thresholds, outdoor evidence, and safety copy.

## 6. Fitness model (eventual)

| Layer | Vision | Today |
| ----- | ------ | ----- |
| Session metrics | Distance, duration, effort context | Distance/time + soft HK reads |
| HealthKit | Optional enrichment + later workout write | Read enrichment implemented; write deferred |
| Watch | Glance + workout session mirror | Deferred (reference only) |
| Live effort (e.g. HR) | Soft context; must not coerce pressure | Deferred |
| Coaching/medical | **Out of vision** as claims | Never claim medical device |

Fitness **serves the companion relationship and movement honesty** — it is not a pure metrics dashboard product.

## 7. Companion & worldbuilding (eventual)

| Horizon | Companion | World |
| ------- | --------- | ----- |
| **MVP** | One first-party companion (**Lira**) | Deterministic events, Bond, bounded pursuit, session memories |
| **Near** | Deeper Lira presentation (AR-primary, art, continuity) | Richer first-party mythos **as content**, not new gameplay authorities |
| **Mid** | Cosmetics / variants still first-party governed | Places, arcs, seasonal world pressure (still offline-capable core) |
| **Eventual** | **User-designed companions** (identity, look, behavior bounds) | **User/partner-designed experiences** (packs), with safety and anti-slop gates |

**Non-negotiables even at north star:**

- Presentation (including AR) does not own movement truth.  
- Safety, pause, stop beat dramatic pressure.  
- Offline-capable core loop remains; network features are additive.  
- Creator systems cannot ship as unbounded gameplay mutation without governance.

## 8. Creator / platform eventual (explicitly late)

| Capability | Earliest conceptual gate |
| ---------- | ------------------------ |
| Experience pack **runtime seam** | After walk AR loop proven; pack format + offline fallback |
| First-party pack content | After runtime + validation |
| User-designed **experiences** | After moderation, safety, and economic policy (if any) |
| User-designed **companions** | After single-companion AR quality + identity model versioning |
| Marketplace | Only with legal, safety, and anti-abuse design — not MVP |

Binding docs today **exclude** marketplace, creator SDK, multi-companion, and downloadable packs. This section is **foresight only**.

## 9. What the north star is *not*

- AR glasses-required day-one product  
- Multiplayer social MMO  
- Medical / clinical fitness claims  
- Generative AI as required core loop  
- Navigation-certified turn-by-turn authority  
- Unlimited user content without gates  

## 10. Relationship to AR redesign docs

| Doc | Role vs north star |
| ---- | ------------------ |
| This file | Long-term **why** and destination |
| [`MVP_TO_VISION_LADDER.md`](../canonical/MVP_TO_VISION_LADDER.md) | **Gates** from now → destination |
| [`AR_PRODUCT_REDESIGN_MAP.md`](AR_PRODUCT_REDESIGN_MAP.md) | Near-term **AR-designed walk MVP** architecture envelope |
| [`AR_APP_REDESIGN_PLAN.md`](../plans/AR_APP_REDESIGN_PLAN.md) | Near-term execution phases for AR walk identity/UX |
| [`AR_SESSION_IA_CONFLICTS.md`](AR_SESSION_IA_CONFLICTS.md) | Session IA conflicts for AR-primary walk |

Near-term redesign is **chapter one** of this north star (AR companion on **walks**), not the whole book.

## 11. Promotion rule

To move any north-star item into binding scope:

1. Ladder gate for that rung is green (evidence + product decision).  
2. Update `SOLO_MVP_SCOPE` / `WAYKIN_SPEC` / capability matrix.  
3. ADR when boundaries (activity model, companion roster, creator, placement) change.  
4. No silent implementation from this file alone.

---

*North star v1.0 — REFERENCE_ONLY. Operator intent captured 2026-07-29.*
