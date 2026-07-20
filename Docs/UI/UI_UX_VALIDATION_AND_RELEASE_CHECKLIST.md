# Waykin UI/UX Validation and Release Checklist

Status: **REQUIRED REVIEW PROTOCOL**  
Use for: every material UI change and every release candidate affecting iPhone presentation or interaction.

---

## 1. Evidence classification

Use these labels in review receipts:

- **OBSERVED** — directly measured, inspected, recorded, or seen on the tested build/device.
- **INFERRED** — conclusion supported by observed evidence but not directly measured.
- **NOT_COMPUTABLE** — evidence is unavailable or the environment cannot validate the claim.

Do not label simulator behavior as physical-device evidence. Do not treat a passing automated test as proof of outdoor readability, ergonomic reach, audible clarity, or real sensor behavior.

---

## 2. Required change record

```yaml
ui_change:
  title:
  pull_request:
  base_sha:
  head_sha:
  deployment_target:
  xcode_version:
  swift_version:
  affected_screens: []
  affected_states: []
  affected_accessibility_features: []
  new_components: []
  modified_components: []
  product_claims_changed: false
  physical_device_required: false
```

A review is invalid if the tested SHA is not recorded.

---

## 3. Design review gate

### Purpose and hierarchy

- [ ] The screen has one explicit primary user goal.
- [ ] One primary action is visually dominant.
- [ ] Secondary actions do not compete with the primary action.
- [ ] Essential state is visible without scrolling where required.
- [ ] Information is ordered by user importance, not data availability.
- [ ] Decorative companion content does not obscure operational state.
- [ ] Empty, loading, degraded, error, success, and recovery states are defined.

### Platform fit

- [ ] Uses system navigation behavior where appropriate.
- [ ] Uses native controls before custom controls.
- [ ] Respects safe areas and system overlays.
- [ ] Status bar visibility is intentional.
- [ ] Sheets, alerts, confirmation dialogs, menus, and toolbars match platform semantics.
- [ ] No custom gesture replaces a standard critical interaction.
- [ ] No full-width control conflicts with iPhone margins or hardware curvature.

### Content

- [ ] Action labels are specific verbs.
- [ ] Destination labels are clear nouns.
- [ ] Operational copy is literal.
- [ ] Narrative copy does not hide system consequence.
- [ ] Error copy explains what happened, impact, and next action.
- [ ] No raw implementation errors or identifiers are user-visible.
- [ ] Claims are supported by actual runtime capability.

---

## 4. Layout test matrix

Test every materially affected screen in at least the following contexts.

| Context | Required | Result |
|---|---:|---|
| Smallest supported iPhone portrait | Yes | |
| Large iPhone portrait | Yes | |
| Supported landscape orientation | Yes | |
| Display Zoom | Yes | |
| Default Dynamic Type | Yes | |
| Largest accessibility Dynamic Type | Yes | |
| Light appearance | Yes | |
| Dark appearance | Yes | |
| Increase Contrast | Yes | |
| Reduce Transparency | If materials used | |
| Right-to-left layout | Yes | |
| Long/pseudo-localized strings | Yes | |
| Keyboard presented | If text entry exists | |
| Offline/unavailable adapter | If relevant | |

Acceptance:

- [ ] No clipped primary text.
- [ ] No inaccessible controls.
- [ ] No overlap with safe areas, Dynamic Island, home indicator, keyboard, sheet detents, or navigation controls.
- [ ] Reading order remains coherent after adaptive reflow.
- [ ] Controls retain at least 44 × 44 point interactive regions.
- [ ] The primary action remains discoverable at accessibility sizes.
- [ ] Long content scrolls intentionally rather than clipping.

---

## 5. Accessibility audit

### VoiceOver

- [ ] Screen title or first meaningful element establishes context.
- [ ] Reading order follows task order.
- [ ] Controls have concise labels.
- [ ] Values expose current state.
- [ ] Hints describe consequence only when necessary.
- [ ] Headings are identified.
- [ ] Decorative elements are hidden.
- [ ] Composite elements are grouped intentionally.
- [ ] Custom controls expose correct traits and actions.
- [ ] Focus does not jump unpredictably after state updates.
- [ ] Alerts, sheets, and confirmations move focus appropriately.
- [ ] Dismissal returns focus to a sensible source control.
- [ ] High-frequency updates do not repeatedly interrupt speech.

### Voice Control and Switch Control

- [ ] Visible control labels are unique enough to target.
- [ ] Every critical action is reachable without custom touch gestures.
- [ ] Focus order is predictable.
- [ ] No essential action requires precise dragging.
- [ ] Repeated activation is safely handled.

### Visual accommodations

- [ ] Meaning is not communicated by color alone.
- [ ] Text/background contrast is sufficient in all appearances.
- [ ] Increase Contrast produces a usable hierarchy.
- [ ] Differentiate Without Color preserves state distinctions.
- [ ] Bold Text does not break layout.
- [ ] Button Shapes do not create ambiguity.
- [ ] Brightness and outdoor contrast are physically reviewed for active-session changes.

### Motion and sensory alternatives

- [ ] Reduce Motion removes or substitutes large/repetitive motion.
- [ ] No flashing or rapid pulsing is introduced.
- [ ] Audio cues have visual and semantic equivalents.
- [ ] Visual warnings have spoken/semantic equivalents.
- [ ] Haptics are not the only indication of a change.
- [ ] Animation stopping behavior is correct during pause/background.

### Accessibility tooling

- [ ] Xcode Accessibility Inspector audit completed.
- [ ] Manual VoiceOver traversal completed.
- [ ] Accessibility Nutrition Label implications reviewed for release changes.
- [ ] Known inclusion debt is recorded as an issue, not silently accepted.

---

## 6. State and interaction validation

For each screen, enumerate all valid states and actions.

```yaml
screen_state:
  screen:
  state:
  visible_content: []
  allowed_actions: []
  prohibited_actions: []
  transition_on_success:
  transition_on_failure:
  recovery:
```

Required checks:

- [ ] Canonical state is the single source of truth.
- [ ] Impossible state combinations are prevented or tested.
- [ ] Taps receive immediate feedback.
- [ ] Duplicate submissions are prevented.
- [ ] Loading indicators reflect real work.
- [ ] Disabled actions have an understandable reason.
- [ ] Reversible actions do not use unnecessary confirmation.
- [ ] Destructive actions name the consequence.
- [ ] Cancellation leaves the model and UI consistent.
- [ ] Background/foreground transitions preserve or safely recover state.
- [ ] Interruptions do not duplicate screens, overlays, tasks, audio, or entities.

---

## 7. Active-session field validation

Required for changes affecting active-session controls, map, location state, companion presence, audio/visual signaling, AR, glasses glance output, or movement-readable presentation.

### Device record

```yaml
physical_test:
  build_sha:
  build_configuration:
  device_model:
  os_version:
  appearance:
  brightness:
  text_size:
  accessibility_settings: []
  environment:
  activity:
  duration:
  weather_or_lighting:
  headphones_or_speaker:
```

### Protocol

- [ ] Start from a clean launch.
- [ ] Begin a real session through the production flow.
- [ ] Confirm the opening state is understandable.
- [ ] Confirm primary controls are usable one-handed.
- [ ] Confirm labels remain legible while moving.
- [ ] Confirm state is understandable in outdoor brightness.
- [ ] Confirm audio state has visible equivalent.
- [ ] Pause and verify all paused indicators agree.
- [ ] Resume and verify controls and state recover once.
- [ ] Trigger or observe degraded location/signal behavior where feasible.
- [ ] Background and reopen the app.
- [ ] Confirm no duplicate companion, map overlay, task, route, or session control appears.
- [ ] End through confirmation.
- [ ] Confirm summary matches saved session state.
- [ ] Reopen and confirm memory/history persistence where applicable.

### Field acceptance

- [ ] Current lifecycle is identifiable in one brief glance.
- [ ] Pause/Resume is unmistakable.
- [ ] End cannot be activated accidentally without recovery/confirmation.
- [ ] Companion state is distinguishable without relying only on color.
- [ ] Important text is readable at normal outdoor brightness.
- [ ] Controls remain responsive during sensor and map updates.
- [ ] No unsupported safety or tracking claim is displayed.

---

## 8. Automated test requirements

### Unit tests

Use unit tests for:

- presentation snapshot derivation;
- state/action availability;
- formatting and fallback logic;
- permission/degraded/error mapping;
- localization-safe value construction;
- Reduce Motion or accessibility policy decisions where modeled;
- prevention of impossible state combinations.

### UI tests

High-value UI automation should cover:

1. launch to Home;
2. primary session start path;
3. permission rationale and denial recovery where deterministic;
4. active state visibility;
5. Pause → Resume;
6. End → cancel;
7. End → confirm → Summary;
8. Summary → Home/Memory;
9. settings presentation and dismissal;
10. persistence/relaunch path;
11. blocking error recovery;
12. largest Dynamic Type smoke path when feasible.

UI tests must use stable accessibility identifiers rather than localized labels.

### Screenshot or snapshot evidence

Use deterministic screenshot/snapshot comparison for stable components when the project supports it. Do not treat snapshots as a substitute for semantic accessibility tests or physical-device review.

Capture representative states:

- Home ready;
- Home permission-blocked;
- Active moving;
- Active paused;
- Active degraded signal;
- End confirmation;
- Summary complete;
- Summary partial data;
- Memory empty/populated;
- Settings.

---

## 9. Performance and power validation

Required for active-session, map, companion animation, AR, or frequent state-update changes.

- [ ] SwiftUI update behavior profiled.
- [ ] CPU sampled on a physical device.
- [ ] Memory remains bounded over a representative session.
- [ ] Route traces, overlays, events, and rendered entities remain capped.
- [ ] No main-thread stalls from formatting, persistence, asset loading, map processing, HealthKit, or location work.
- [ ] Animation remains smooth enough for intended use.
- [ ] Thermal state recorded for extended field tests.
- [ ] Battery/power observation recorded for bounded test duration.
- [ ] Background tasks stop or suspend according to lifecycle.

Where a numerical threshold is not yet established, record measured baseline and regression delta rather than inventing acceptance numbers.

---

## 10. Privacy and claim audit

- [ ] UI displays only necessary location/health/session data.
- [ ] Demo data is visibly distinguishable from real session data when ambiguity is possible.
- [ ] Screenshots and logs contain no unintended precise route or health information.
- [ ] Telemetry excludes sensitive payloads.
- [ ] Permission rationale matches actual behavior.
- [ ] Disabled adapters do not appear active.
- [ ] Cosmetic companion skins do not imply functionality or unlock state.
- [ ] AR/glasses/HealthKit availability is represented truthfully.
- [ ] No medical, safety, performance, or hardware compatibility claim exceeds validation evidence.

---

## 11. Regression matrix

At minimum, review these flows after a material shared-component, navigation, theme, or app-model change:

| Flow | Automated | Simulator manual | Physical device |
|---|---:|---:|---:|
| Clean launch/Home | Yes | Yes | Smoke |
| Start demo session | Yes | Yes | Optional |
| Start real session | Partial | Partial | Yes |
| Pause/Resume | Yes | Yes | Yes |
| End/Cancel/Confirm | Yes | Yes | Yes |
| Summary | Yes | Yes | Yes |
| Memory persistence | Yes | Yes | Smoke |
| Settings | Yes | Yes | Smoke |
| Permission denied | Yes where injectable | Yes | As needed |
| Weak/unavailable signal | Injectable | Yes | Yes where feasible |
| Background/reopen | Yes | Yes | Yes |
| Audio interruption | Injectable | Partial | Yes |
| Dynamic Type maximum | Smoke | Yes | Smoke |
| VoiceOver | Limited automation | Yes | Yes for release |
| Dark/increased contrast | Snapshot/manual | Yes | Smoke |

---

## 12. Pull request evidence template

```markdown
## UI/UX validation receipt

### Scope
- Screens:
- States:
- Components:
- Tested SHA:

### Automated
- Build:
- Unit tests:
- UI tests:
- Accessibility audit:

### Simulator
- Devices/orientations:
- Dynamic Type:
- Appearance/contrast:
- Localization/RTL:

### Physical device
- Device/OS:
- Scenario:
- Duration:
- Outdoor readability:
- One-handed control:
- Audio/visual redundancy:
- Background/recovery:

### Findings
- OBSERVED:
- INFERRED:
- NOT_COMPUTABLE:

### Remaining risks
-
```

---

## 13. Release gate

A UI/UX release candidate is accepted only when:

- [ ] All P0/P1 usability and accessibility defects are resolved.
- [ ] Core flow UI automation passes on the exact candidate SHA.
- [ ] Active-session changes have physical-device evidence.
- [ ] Accessibility audit and manual VoiceOver path pass.
- [ ] Largest Dynamic Type is usable.
- [ ] Light, dark, increased contrast, and Reduce Motion behavior pass.
- [ ] No product capability is overstated.
- [ ] State recovery passes after backgrounding and interruption.
- [ ] Performance shows no material regression against baseline.
- [ ] Documentation and screenshots match actual behavior.
- [ ] Known residual limitations are explicit and non-blocking.

Any untested required row is **NOT_COMPUTABLE**, not PASS.
