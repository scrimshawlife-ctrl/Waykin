# UI Change Validation Receipt

```yaml
document_id: WAYKIN-UI-CHANGE-RECEIPT-001
version: 1.0
status: CURRENT
authority: SUPPORTING
use_when: Material iPhone UI/presentation changes and UI release candidates
depends_on:
  - docs/design/UI_ENGINEERING_PRACTICE.md
  - docs/design/WAYKIN_UIUX_SPEC.md
  - docs/FIELD_TEST_PROTOCOL.md
  - docs/design/OUTDOOR_QA_CHECKLIST.md
```

**Supporting checklist.** Does not replace outdoor QA, field-test protocol, or binding scope docs. Use evidence labels: `OBSERVED` / `INFERRED` / `NOT_COMPUTABLE`.

Simulator PASS ≠ outdoor or physical-device PASS.

---

## 1. When this is required

Required for PRs that materially change:

- Home, Active Session, Summary, Memory, Settings, permissions, or error recovery UI
- Companion presence presentation, AR chrome, map overlays on session screens
- Navigation modality (push / sheet / cover)
- Accessibility semantics of critical controls
- Design tokens or global chrome that affect walk surfaces

**Not required** for pure Core logic with no presentation change, docs-only non-UI work, or typo/copy fixes that do not alter hierarchy or claims.

For outdoor AR/companion readability claims, also complete [`OUTDOOR_QA_CHECKLIST.md`](OUTDOOR_QA_CHECKLIST.md) / issue #41 path—not this receipt alone.

---

## 2. Change record (fill in PR)

```yaml
ui_change:
  title:
  pull_request:
  base_sha:
  head_sha:
  affected_screens: []
  affected_states: []
  new_or_modified_components: []
  product_claims_changed: false
  physical_device_required: false   # true if active-session, sensors, AR, audio path, outdoor claim
  outdoor_required: false           # true only if claiming outdoor readability / AR field quality
```

A review is incomplete if the tested SHA is missing.

---

## 3. Design / product gate (quick)

- [ ] One primary user goal per affected screen
- [ ] One visually dominant primary action (Home: real Begin Walk; Demo secondary if present)
- [ ] Essential session state visible without scrolling where product law requires it
- [ ] Companion/decorative content does not obscure operational state
- [ ] Empty / loading / degraded / error / success paths defined when reachable
- [ ] Matches [`WAYKIN_UIUX_SPEC.md`](WAYKIN_UIUX_SPEC.md) modality rule (push / sheet / cover)
- [ ] No new activity type beyond walking

---

## 4. Layout / appearance smoke

At least on **one** small and **one** large iPhone simulator (or device):

| Context | Required for material UI | Result |
|---|---:|---|
| Portrait, default Dynamic Type | Yes | |
| Largest accessibility Dynamic Type (primary path) | Yes | |
| Light appearance | Yes | |
| Dark appearance | Yes | |
| Increase Contrast (if custom materials) | If used | |
| Reduce Motion | Yes if animation touched | |

Landscape, Display Zoom, RTL, and pseudo-localization: required only when those axes are affected or for release candidates.

---

## 5. Accessibility smoke

- [ ] Critical controls have adequate hit targets and labels
- [ ] State is not color-only
- [ ] VoiceOver order matches product hierarchy on changed screens (or note gap)
- [ ] No essential control is gesture-only
- [ ] Reduce Motion: continuous decoration stops; state still readable

Physical VoiceOver on-device: required for release candidates that change active-session controls; otherwise `NOT_COMPUTABLE` if not run.

---

## 6. State / honesty

- [ ] Presentation derived from canonical state (no drift)
- [ ] Demo vs real walk remains distinguishable
- [ ] Disabled adapters do not look “active”
- [ ] Pause/End remain available during active session and AR cover when those surfaces change
- [ ] Errors explain impact and next step without raw diagnostics

---

## 7. Automated

- [ ] `make validate` (or CI equivalent) on head SHA
- [ ] Unit tests for new/changed presentation snapshot derivation
- [ ] UI smoke updated if navigation or primary CTAs changed

---

## 8. Physical device (when `physical_device_required`)

Record device model + OS. Minimum:

- [ ] Start → active → pause → resume → end (or the subset changed)
- [ ] Background / reopen recovery if lifecycle touched
- [ ] One-handed reach for primary controls if control chrome moved
- [ ] Audio + visible equivalent if audio presentation changed

Outdoor brightness / AR field quality: only if `outdoor_required`; then use outdoor checklist and mark evidence class honestly.

---

## 9. PR comment template

```markdown
## UI/UX validation receipt

### Scope
- Screens:
- States:
- Components:
- Tested SHA:

### Automated
- validate/CI:
- Unit:
- UI:

### Simulator
- Devices:
- Dynamic Type:
- Light/Dark / contrast / Reduce Motion:

### Physical device (or NOT_COMPUTABLE)
- Device/OS:
- Scenario:
- Findings:

### Evidence
- OBSERVED:
- INFERRED:
- NOT_COMPUTABLE:

### Residual risks
-
```

---

## 10. Release candidate extras

In addition to the above, a UI release candidate should have:

- [ ] No open P0/P1 usability or a11y defects on the walk loop
- [ ] Core-flow UI automation green on the candidate SHA
- [ ] Active-session changes: physical-device evidence recorded
- [ ] Known limitations explicit (do not convert `NOT_COMPUTABLE` into PASS)
- [ ] Screenshots or captures match actual behavior when claims are visual

---

## 11. Relationship to other protocols

| Protocol | Use for |
|---|---|
| This receipt | Material UI PR / UI RC process |
| [`FIELD_TEST_PROTOCOL.md`](../FIELD_TEST_PROTOCOL.md) | Broader field evidence gates |
| [`OUTDOOR_QA_CHECKLIST.md`](OUTDOOR_QA_CHECKLIST.md) | Outdoor device UI/AR checks |
| [`SIMULATOR_PREFLIGHT.md`](SIMULATOR_PREFLIGHT.md) | Sim-only preflight before outdoor |
| [`UI_ENGINEERING_PRACTICE.md`](UI_ENGINEERING_PRACTICE.md) | How to implement presentation |
