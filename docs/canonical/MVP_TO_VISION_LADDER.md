# Waykin MVP → Vision Ladder

```yaml
document_id: WAYKIN-MVP-TO-VISION-LADDER-001
version: 1.0
date: 2026-07-29
status: SUPPORTING
authority: SUPPORTING
maturity: NEAR_TERM
north_star: docs/design/PRODUCT_VISION_NORTH_STAR.md
does_not_override: [docs/SOLO_MVP_SCOPE.md, WAYKIN_SPEC.md]
```

## 1. Purpose

Translate the [north star](../design/PRODUCT_VISION_NORTH_STAR.md) into a **gated ladder** so the team can build toward:

- AR companion on **walks → runs → rides** (+ fitness depth)  
- then **worldbuilding**  
- then **user-designed companions & experiences**  

…without breaking the current architecture or shipping excluded scope early.

**Lower rungs do not unlock upper rungs by aspiration alone.** Each gate needs evidence + explicit promotion.

## 2. Ladder overview

```text
R0  Binding MVP (today)
R1  AR-designed walk identity + session
R2  Outdoor AR walk proof
R3  Fitness depth (still walk-primary)
R4  Multi-activity framework (run, then ride)
R5  First-party worldbuilding content systems
R6  Experience pack runtime (first-party packs)
R7  User-designed experiences
R8  User-designed companions (+ marketplace only if ever ratified)
```

```text
R0 ──▶ R1 ──▶ R2 ──▶ R3 ──▶ R4 ──▶ R5 ──▶ R6 ──▶ R7 ──▶ R8
 walk   AR     outdoor fitness multi  world  packs  UGC    UGC
 law    law    AR      depth   activity build first  exp.   companions
        UX     PASS                  party
```

## 3. Rung detail

### R0 — Binding MVP (current law)

| Field | Content |
| ----- | ------- |
| **Product** | Solo adaptive **walk**; one companion **Lira**; Bond; bounded pursuit; semantic audio; local memory |
| **AR** | Presentation adapter; optional cover; MVP frozen for feature creep |
| **Fitness** | Soft HealthKit reads only |
| **Creator / multi-companion / multi-activity** | Excluded or deferred |
| **Authority** | `SOLO_MVP_SCOPE`, `WAYKIN_SPEC`, capability matrix |
| **Exit** | N/A — baseline |

### R1 — AR-designed walk (near-term redesign)

| Field | Content |
| ----- | ------- |
| **Product** | Same walk MVP; identity = **AR-designed** (not audio-first); AR primary session surface when capable |
| **Work** | Phase 0 law + Phase 2 session IA ([`AR_APP_REDESIGN_PLAN`](../plans/AR_APP_REDESIGN_PLAN.md), [`AR_SESSION_IA_CONFLICTS`](../design/AR_SESSION_IA_CONFLICTS.md)) |
| **Must not** | Multi-activity, multi-companion, creator, AR gameplay authority |
| **Exit gate** | Binding docs + UIUX amended; skills/agents aligned; isolation + tests green |

### R2 — Outdoor AR walk proof

| Field | Content |
| ----- | ------- |
| **Work** | #41 outdoor re-walk; continuity, thermal, battery, safety; honest receipts |
| **Exit gate** | Outdoor AR evidence policy satisfied for claims you want to make; no PASS invented from sim |
| **Unlocks** | Credible AR marketing; confidence for multi-activity planning |

### R3 — Fitness depth (walk still primary)

| Field | Content |
| ----- | ------- |
| **Work** | Harden HK lifecycle evidence; optional workout write; Watch **only** via promoted issues; effort as soft context |
| **Must not** | Medical claims; effort selecting events/Bond coercively |
| **Exit gate** | Device evidence for each promoted fitness surface; capability matrix rows flipped with issues |

### R4 — Multi-activity framework (run, then ride)

| Field | Content |
| ----- | ------- |
| **Work** | Activity profiles on shared movement engine; integrity thresholds per mode; AR/HUD safety for speed contexts; copy and onboarding |
| **Order** | **Run** before **ride** unless product reorders with ADR |
| **Must not** | Separate app forks; activity-specific gameplay authorities that bypass Core |
| **Exit gate per activity** | Integrity + outdoor sessions + return-intent signal; spec lists activity as authorized |

### R5 — First-party worldbuilding systems

| Field | Content |
| ----- | ------- |
| **Work** | Content/lore systems, arcs, place-linked memories, seasonal pressure — **still** deterministic-capable core; presentation via existing channels |
| **Must not** | AI-owned gameplay state; unbounded generative world as required loop |
| **Exit gate** | Content pipeline + validation; no scope leak into multiplayer/marketplace |

### R6 — Experience pack runtime (first-party)

| Field | Content |
| ----- | ------- |
| **Work** | Promote deferred Experience Pack seam: pack format, load, offline fallback, validation |
| **Content** | First-party packs only |
| **Exit gate** | Runtime + at least one first-party pack shippable; security/safety review |

### R7 — User-designed experiences

| Field | Content |
| ----- | ------- |
| **Work** | Creator tools or structured authoring; moderation; rate limits; safety |
| **Depends on** | R6 stable |
| **Exit gate** | Policy + technical gates; binding docs promote creator experiences |

### R8 — User-designed companions (+ optional marketplace)

| Field | Content |
| ----- | ------- |
| **Work** | Companion identity model versioning; user-defined look/behavior **bounds**; AR presentation of third-party companions; optional marketplace |
| **Depends on** | R1–R2 quality bar for “a companion in AR”; R6–R7 governance lessons |
| **Must not** | Unbounded behavior that violates safety or movement authority |
| **Exit gate** | Explicit legal/product/security ratification; multi-companion ban lifted in binding scope |

## 4. Mapping north-star pillars → earliest rung

| North-star pillar | Earliest rung |
| ----------------- | ------------- |
| AR companion presence | R1 (design), R2 (proof) |
| Real movement | R0+ |
| Multi-activity fitness | R4 (framework); R3 (fitness depth on walk) |
| Bond relationship | R0+ (deepen ongoing) |
| Worldbuilding | R5 |
| Creator companions & experiences | R7–R8 (packs R6) |

## 5. What each horizon may claim

| Horizon | OK to say | Not OK |
| ------- | --------- | ------ |
| R0–R1 | AR companion for walking (with honest capability limits) | Multi-sport app; make your own companion |
| R2+ | Outdoor AR walk claims per receipt | Universal outdoor AR quality |
| R3+ | Fitness-connected walk companion | Medical/clinical |
| R4+ | Run/ride companion (per shipped modes) | “All sports” without list |
| R5+ | Deeper world / story of Lira’s world | User-generated world as default |
| R6+ | Official experience packs | App Store “UGC platform” |
| R7–R8 | Design experiences / companions | Unmoderated marketplace |

## 6. Architecture seams to keep open (without implementing early)

| Seam | Already / planned | Serves rungs |
| ---- | ----------------- | ------------ |
| `ARWorldCommand` + matrix | Shipped | R1–R8 presentation |
| Movement engine + integrity | Shipped | R0–R4 |
| Activity enrichment (HK) | Soft reads shipped | R3–R4 |
| Watch / wearable contracts | Reference | R3–R4 |
| Experience pack (deferred) | Seam only | R6–R7 |
| Companion identity persistence | Lira singleton | R8 needs versioning |

**Do not** invent parallel runtimes per activity or per creator pack that bypass Core.

## 7. Relationship to binding exclusions

Until a rung is promoted, these remain **out of force for implementation** even though they appear in the north star:

- Run / cycle / hike / climb expansion  
- Multi-companion  
- Marketplace / creator SDK  
- Downloadable experience packs (runtime deferred)  
- Multiplayer  
- Generalized AI world director  

## 8. Suggested promotion checklist (any rung)

- [ ] Outdoor / device evidence named and attached  
- [ ] Capability matrix row updates  
- [ ] `WAYKIN_SPEC` / `SOLO_MVP_SCOPE` diff (if product law changes)  
- [ ] ADR if boundaries change  
- [ ] UIUX / agent context updated  
- [ ] Explicit non-goals restated so agents don’t overbuild  

## 9. Related

| Doc | Role |
| --- | ---- |
| [`../design/PRODUCT_VISION_NORTH_STAR.md`](../design/PRODUCT_VISION_NORTH_STAR.md) | Destination |
| [`../design/AR_PRODUCT_REDESIGN_MAP.md`](../design/AR_PRODUCT_REDESIGN_MAP.md) | R1 architecture map |
| [`../plans/AR_APP_REDESIGN_PLAN.md`](../plans/AR_APP_REDESIGN_PLAN.md) | R1 execution |
| [`CURRENT_CAPABILITY_MATRIX.md`](CURRENT_CAPABILITY_MATRIX.md) | What is shipped vs deferred |
| [`../../ROADMAP.md`](../../ROADMAP.md) | Evidence-gated engineering roadmap |

---

*Ladder v1.0 — supporting. Does not override binding MVP law.*
