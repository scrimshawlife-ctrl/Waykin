# Session / AR menu UX audit (#126)

```yaml
document_id: WAYKIN-SESSION-MENU-UX-126
version: 1.0
status: IMPLEMENTED_SIM
evidence_ceiling: SIMULATOR_AND_CODE
outdoor: NOT_COMPUTABLE_UNTIL_REWALK
parent: "#41 PARTIAL"
```

## Flow map (outdoor-relevant)

| Step | Surface | Before | Severity |
| ---- | ------- | ------ | -------- |
| 1 | Home | Demo **Begin Walk** was primary; real walk was plain link below Memory | **Blocking** product priority (A2-2) |
| 2 | Home | Permission / live state buried in status text | **Friction** (#126-5) |
| 3 | Session | AR entry below map, far from Pause/End | **Friction** |
| 4 | Session → AR | `.sheet` swipe-dismissible, covers session chrome | **Blocking** walk ergonomics (A2-3) |
| 5 | AR | Close only; no Pause/End without dismissing AR | **Friction** (esp. #125 re-entry) |
| 6 | Home empty | No first-memory invitation | **Polish** |

## Decisions (bounded, no new product systems)

1. **Home CTA inversion** — Real walk = primary “Begin Walk” (≥56 pt, prominent). Demo = secondary “Demo Walk”; `waykin.beginWalk` remains on demo for UI-test continuity.
2. **Inline real-walk button states** — Allow Location… / Walk in Progress / Try Walk Again on the CTA itself.
3. **AR beside Pause/End** — One control row for one-handed reach.
4. **AR full-screen cover** — `interactiveDismissDisabled`; explicit ✕.
5. **Mirrored Pause/End in AR chrome** — walk always controllable in immersion.

## Explicit non-goals

- Full design-system redesign, map v2, Core changes, outdoor claims.

## Validation

- Package + App unit tests; simulator smoke (UITests) still use `waykin.beginWalk` → Demo Walk.
- Outdoor re-feel of menus: **tomorrow** device walk under #41.
