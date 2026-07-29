# AR Session IA Conflicts

```yaml
document_id: WAYKIN-AR-SESSION-IA-CONFLICTS-001
version: 1.0
date: 2026-07-29
status: SUPPORTING_AUDIT
authority: SUPPORTING
maturity: NEAR_TERM
evidence_class: CODE_AND_DOC_AUDIT
tip_audited: 850fe7b
parent_map: docs/design/AR_PRODUCT_REDESIGN_MAP.md
parent_plan: docs/plans/AR_APP_REDESIGN_PLAN.md
related:
  - docs/design/WAYKIN_UIUX_SPEC.md
  - docs/design/AR_MVP_FREEZE.md
  - docs/design/REAL_WALK_TO_AR_MAPPING.md
  - App/WaykinApp.swift (ActiveSessionView)
  - WAYKIN_SPEC.md
  - docs/SOLO_MVP_SCOPE.md
```

## 1. Purpose

Register **information-architecture conflicts** for the Active Session when product direction is **AR-designed** (no longer audio-first) while shipped UI and UIUX still treat **2D presence as session root** and **AR as optional full-screen cover**.

This document does **not** change binding product law or implement UX. It feeds Phase 0 (law) and Phase 2 (session UX) in [`../plans/AR_APP_REDESIGN_PLAN.md`](../plans/AR_APP_REDESIGN_PLAN.md).

## 2. Current session IA (specified + shipped)

```text
Home
  └─ Begin Walk / Demo
       ↓ push
Active Session (PRIMARY SURFACE = 2D)
  ├─ State chip + relation chip
  ├─ CompanionPresenceView     ← Lira stills (main stage)
  ├─ Pause | End | AR          ← AR is a control, not the stage
  ├─ GPS chip (live)
  └─ CompactSessionMap → full map cover
       ↓ optional fullScreenCover
  AR Companion (SECONDARY IMMERSION)
       chrome: status · continuity · ✕ · Pause/End mirrored
       ↓ dismiss ✕
  back to 2D session
       ↓ End
Session Summary
```

| Layer | Role today | Code / doc |
| ----- | ---------- | ---------- |
| **2D presence** | Default session home; a11y spine | `CompanionPresenceView` in `ActiveSessionView` |
| **AR** | Opt-in cover (`showsARCompanion`) | `CanonicalARSessionView` fullScreenCover |
| **Map** | Compact inline + peer fullScreenCover | `showsFullMap` / `SessionMapFullView` |
| **Audio** | Not a screen; UIUX B1 still “primary channel” | `AppAudioCuePlayer` + Core cues |

**UIUX stance (B4):** “The shipped session screen is fundamentally right” — consolidation, not redesign; AR entry position + cover safety only.

## 3. Conflict register

### C1 — Product genus vs session tree

| Severity | High |
| -------- | ---- |
| Type | Law vs IA |

| Source | Says |
| ------ | ---- |
| Binding law (`SOLO_MVP_SCOPE`, `WAYKIN_SPEC`) | Audio-first product |
| UIUX B1 | “Audio is the primary channel; the screen confirms” |
| UIUX B2 + shipped | Screen-first session; AR optional |
| Operator + redesign map | AR-designed; AR primary session surface |

**Conflict:** Three competing “primaries” (audio / 2D screen / AR) without one ordered channel stack.

**Resolution direction:** Phase 0 law + UIUX B1 rewrite: AR primary **designed** surface when capable; audio required **support**; 2D fallback/HUD.

---

### C2 — “Presence OR AR, never both animating” vs AR-default

| Severity | High |
| -------- | ---- |
| Type | Principle vs redesign |

UIUX B1.3: Lira never duplicated — **presence surface OR AR, never both animating at once**.

| Today | AR-default target |
| ----- | ----------------- |
| 2D animates; AR off | AR animates; 2D may still update under cover |
| Rule holds if user attention is exclusive | Under-cover 2D animation semantics undefined |

**Resolution options (pick one in Phase 2 issue):**

1. **Exclusive stages** — while AR open, 2D figure is static/non-animating snapshot.  
2. **AR owns Lira** — under AR, 2D shows HUD only (no figure).  
3. **Relax B1.3** — multi-surface Lira (weakens “one truth”; not preferred).

**Recommended:** option **2** for AR-primary; option **1** as minimal change.

---

### C3 — Session root is 2D; AR is a leaf cover

| Severity | High |
| -------- | ---- |
| Type | Structure vs AR app |

```text
Target (redesign map)          Shipped
─────────────────────          ───────
AR canvas = session root       2D presence = root
2D = fallback / HUD            AR = optional cover
Map = overlay/tertiary         Map = peer cover
```

Full-screen cover is correct for **safety** (#126: no accidental dismiss, Pause/End mirrored) but encodes **“AR is immersion on top of the real session,”** not **“AR is the session.”**

**Resolution direction:** Keep cover/chrome safety; invert **default entry** and mental model so AR is home when capability allows; 2D is fallback stage (Phase 2).

---

### C4 — Dual fullScreenCover: AR vs Map

| Severity | Medium |
| -------- | ------ |
| Type | Competing immersion |

`ActiveSessionView` holds independent:

- `showsARCompanion` → AR cover  
- `showsFullMap` → map cover  

| Issue | Detail |
| ----- | ------ |
| Peer immersions | Both can own the full screen |
| No mutual exclusion | Stacking / priority undefined in IA |
| Thumb competition | Compact map + AR + Pause/End |

**Resolution direction:** Under AR stage, map is **peek/sheet** (or HUD chip), not a peer cover. Full map remains available on 2D fallback stage.

---

### C5 — A11y traversal vs AR-primary

| Severity | Medium–High |
| -------- | ----------- |
| Type | Contract collision |

UIUX B10 order:

```text
identity → presence → phrase → metrics → status → controls → map
```

AR is **outside** this spine; AR chrome is separate.

| Conflict | Effect |
| -------- | ------ |
| A11y law is 2D-shaped | Outdoor VO path assumes presence surface |
| AR-primary walk | Needs AR order: tracking · Lira · phrase · Pause/End · exit stage |
| Reduce Motion | 2D stills vs AR skeletal motion = different channels |

**NOT_COMPUTABLE:** physical VoiceOver + outdoor AR until receipts exist.

**Resolution direction:** Document dual spines (2D stage / AR stage) in UIUX; do not claim single traversal for both.

---

### C6 — ✕ returns to 2D “home base”

| Severity | Medium |
| -------- | ------ |
| Type | Mental model |

#126: AR cover, `interactiveDismissDisabled`, Pause/End mirrored — **keep**.

Still:

- ✕ means “leave immersion → 2D session”  
- Outdoor PARTIAL: menu/entry awkward (`REAL_WALK_TO_AR_MAPPING`, outdoor receipt)

**Conflict:** AR-primary users should not need 2D as emotional home. ✕ should mean “switch stage,” not “abandon the real product.”

**Resolution direction:** Copy + optional “prefer 2D this walk” control; End remains end-of-walk only.

---

### C7 — Pocket-first vs eyes-up AR

| Severity | High |
| -------- | ---- |
| Type | Principle collision |

| UIUX B1 Pocket-first | AR session |
| -------------------- | ---------- |
| Glances, one hand, phone not product | Camera up, longer visual attention |
| Audio primary while walking | Visual primary when AR open |

**Resolution direction:** **Mode-aware IA**, not one tree for all moments:

| Mode | Primary channel | Stage |
| ---- | --------------- | ----- |
| Pocket / eyes-down | Audio + glance/HUD | 2D or compact HUD |
| Eyes-up | AR canvas | AR stage |
| Capability fail | Audio + 2D | 2D fallback |

---

### C8 — Multi-channel attention on one tick

| Severity | Medium |
| -------- | ------ |
| Type | Cognitive load |

One tick can drive 2D still, AR entity, audio, path chip, map, pressure ring. Matrix keeps **semantic** unity; IA lacks **attention priority**.

**Example:** path `offPath` + pursuit `close` + AR open → what first?

**Resolution direction:** Document AR-stage attention order, e.g.:

1. Safety controls always reachable  
2. Threat / discovery entity  
3. Continuity / tracking chrome  
4. Path / Bond HUD  
5. Audio reinforcement  

---

### C9 — Capability fallback missing from session IA

| Severity | High |
| -------- | ---- |
| Type | AR app gap |

| State | Shipped | Gap |
| ----- | ------- | --- |
| AR never opened | Full 2D product | OK as fallback |
| Camera denied / unsupported | Button may still offer AR | Need disabled+reason / auto 2D |
| Tracking limited | Continuity only if already in AR | Need degraded AR policy |
| Default-open AR (Phase 2) | Not implemented | Need first-class branch in B2 |

UIUX B2 has **no fallback branch**. Redesign map defines one; promote into UIUX in Phase 0/2.

---

### C10 — Glasses glance + AR + 2D

| Severity | Low–Med |
| -------- | ------- |
| Type | Future pile-up |

Glance adapter publishes from `activePresencePresentation` when enabled, independent of AR cover.

**Conflict with B1.3** if flag-on + AR-default (three Lira surfaces).

**Resolution direction:** When AR stage active, glance mirrors AR/HUD phrase only; no second animated companion narrative.

---

### C11 — Document authority deadlock

| Severity | High |
| -------- | ---- |
| Type | Process |

| Doc class | Session stance |
| ---------- | -------------- |
| BINDING scope/spec | Audio-first |
| DESIGN_REFERENCE UIUX | 2D root; AR cover; “don’t redesign session” |
| SUPPORTING redesign map + this file | AR root when capable |
| AR MVP freeze | No silent `App/AR/**` feature expansion |

Agents and PRs will follow UIUX/binding until Phase 0 + UIUX B1–B4 amendment.

## 4. Conflict graph

```text
                    ┌──────────────┐
                    │ Product law  │ audio-first
                    └──────┬───────┘
                           │ C1
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌─────────┐  ┌──────────┐  ┌──────────┐
        │ UIUX B1 │  │ Shipped  │  │ Redesign │
        │ pocket+ │  │ 2D root  │  │ AR root  │
        │ audio   │  │ AR leaf  │  │          │
        └────┬────┘  └────┬─────┘  └────┬─────┘
             │ C7         │ C3          │
             └────────────┼─────────────┘
                          ▼
                   Session reality
             ┌────────────┼────────────┐
             ▼            ▼            ▼
          Presence      AR cover     Map cover
             │            │            │
             └──── C2 ────┴──── C4 ────┘
                   exclusive Lira?
                          │
                    C5 a11y spine (2D-only)
                    C9 no fallback branch
                    C11 authority deadlock
```

## 5. Non-conflicts (preserve)

| Stable | Why |
| ------ | --- |
| Push = walk lifecycle | Correct |
| Settings = sheet | Correct |
| AR non-accidental dismiss + mirrored Pause/End | Safety law (#126) — keep even if AR-default |
| One companion ID + B7 crosswalk / matrix | Semantic unity |
| Map not navigation-grade | Scope |
| `ARWorldCommand` only when handler attached | Architecture |
| Presentation ≠ gameplay | Binding |

## 6. Target session IA (conflict-resolving sketch)

Proposal for Phase 0/2 docs — **not shipped**:

```text
Active Walk
  │
  ├─ IF ar_capability ∈ {available, active}
  │     STAGE = AR canvas (session root chrome)
  │       HUD: phrase · path · bond · continuity
  │       Controls: Pause · End · (Map peek) · (Switch to 2D)
  │       Lira: AR only (2D figure suppressed)     ← C2
  │
  ├─ ELSE
  │     STAGE = 2D presence (today’s root)
  │       Controls: Pause · End · AR (disabled+reason) · Map
  │
  └─ Audio: always policy-on (supporting), not a stage

Map: sheet/peek under current stage — not peer cover to AR   ← C4
Modes: pocket (audio+HUD) vs eyes-up (AR) explicit           ← C7
```

## 7. Resolution priority

| Order | Conflict | Action | Phase |
| ----: | -------- | ------ | ----- |
| 1 | C1, C11 | Binding law + UIUX B1/B2 amendment | 0 |
| 2 | C3, C9 | Session IA: default stage + fallback branch | 0 docs / 2 code |
| 3 | C2 | Exclusive Lira under AR (prefer HUD-only 2D) | 2 issue |
| 4 | C4 | Map modality under AR | 2 issue |
| 5 | C5 | Dual a11y spines | 2 docs + impl |
| 6 | C6 | Exit copy / stage switch | 2 |
| 7 | C7 | Mode policy pocket vs eyes-up | 0–2 |
| 8 | C8 | Attention priority table | 0 docs |
| 9 | C10 | Glance policy when AR open | later / flag-on |

## 8. Implementation constraints

- Do **not** break Core isolation or turn AR into gameplay authority.  
- Phase 2 requires a **scoped freeze exception issue** for session-default AR UX.  
- Keep Demo completable without camera.  
- Outdoor AR PASS still gated on #41 — IA changes must not invent quality claims.

## 9. Claim labels

| Label | Claim |
| ----- | ----- |
| OBSERVED | 2D session root; AR/map independent covers; B1.3 exclusive Lira; B4 anti-redesign; #126 safety chrome |
| INFERRED | AR-default without IA rewrite will fight UIUX and a11y spine |
| SPECULATIVE | Mode-aware IA improves outdoor completion without raising gameplay scope |
| NOT_COMPUTABLE | Outdoor VO+AR; default-AR completion rate |

## 10. Related

| Doc | Role |
| --- | ---- |
| [`AR_PRODUCT_REDESIGN_MAP.md`](AR_PRODUCT_REDESIGN_MAP.md) | Master redesign map |
| [`../plans/AR_APP_REDESIGN_PLAN.md`](../plans/AR_APP_REDESIGN_PLAN.md) | Phases |
| [`AR_SYSTEM_INVENTORY.md`](AR_SYSTEM_INVENTORY.md) | Files |
| [`WAYKIN_UIUX_SPEC.md`](WAYKIN_UIUX_SPEC.md) | Current session IA law (design reference) |
| [`AR_MVP_FREEZE.md`](AR_MVP_FREEZE.md) | Feature freeze |
| [`REAL_WALK_TO_AR_MAPPING.md`](REAL_WALK_TO_AR_MAPPING.md) | Command + entry gaps |

---

*End of AR session IA conflicts v1.0*
