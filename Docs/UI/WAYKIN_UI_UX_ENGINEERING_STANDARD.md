# Waykin iPhone UI/UX Engineering Standard

Status: **CANONICAL**  
Audience: product engineering, design, QA, accessibility review, and coding agents.  
Applies to: iPhone UI implemented with SwiftUI, including Home, Active Session, Summary, Memory, Settings, permissions, errors, and companion presentation.

---

## 1. Product interaction model

Waykin is an **audio-first adaptive movement experience**. The screen is a supporting surface, not the primary experience during movement.

The UI must support three operating modes:

| Mode | User context | UI objective |
|---|---|---|
| Preparation | Stationary, planning a session | Explain, configure, request permission, and begin with confidence |
| Active movement | Walking/running/biking; intermittent attention | Communicate only essential state at a glance and make critical controls unmistakable |
| Reflection | Stationary after completion | Summarize progress, meaning, memory, and next action without overwhelming detail |

### 1.1 Core principles

1. **Glance before gaze.** The active experience must be understandable within approximately one brief glance.
2. **Audio plus visual, never audio only.** Any meaningful audio state must have a visible and accessible equivalent.
3. **State truth over spectacle.** Animation, companion expression, and copy must reflect actual runtime state.
4. **One primary action per state.** Secondary actions must not compete with the action most likely required next.
5. **Safe interruption.** The user must be able to pause, resume, end, recover, and understand permission or signal failures without ambiguity.
6. **Platform-native first.** Prefer SwiftUI controls, NavigationStack, sheets, alerts, menus, system typography, SF Symbols, safe areas, semantic colors, and system gestures.
7. **Progressive disclosure.** Show essential information first; place diagnostics, history, and configuration behind deliberate navigation.
8. **Outdoor readability.** Contrast, type size, spacing, and control geometry must remain effective in bright light and motion.
9. **Calm hierarchy.** Avoid simultaneous competing cards, badges, animations, gradients, alerts, and metrics.
10. **Accessibility is structural.** Accessibility behavior is part of component design and acceptance, not a post-build annotation pass.

---

## 2. Information architecture

### 2.1 Canonical top-level structure

The app should preserve a shallow hierarchy:

```text
Home
├── Start / Resume Session
├── Experience recommendation or session setup
├── Companion status
├── Memory history
└── Settings

Active Session
├── Companion/state presentation
├── Essential movement status
├── Pause / Resume
└── End Session

Session Summary
├── Completion state
├── Primary result
├── Companion/bond change
├── Meaningful events
└── Return Home / View Memory
```

Avoid adding top-level tabs unless multiple persistent destinations become equally frequent and independent. Waykin’s current core flow is sequential; a `NavigationStack` is generally more coherent than a tab bar.

### 2.2 Navigation requirements

- Use value-based `NavigationStack` routing for app-level destinations.
- A visible or system-provided back path must exist unless leaving would corrupt or abandon an active operation.
- During an active session, accidental swipe-back or navigation dismissal may be disabled, but an explicit Pause/End path must remain available.
- Settings should normally be presented as a sheet from Home, not as a competing root destination.
- Full-screen covers are reserved for truly immersive or interruption-sensitive experiences.
- Do not nest independent `NavigationStack` instances without a documented reason.
- Restore navigation only when destination state is valid and durable.

### 2.3 Deep-link and restoration behavior

A route is restorable only when all required model identifiers and persisted data remain available. Missing summary or memory state must resolve to a humane recovery screen, not a bare debug string.

Required recovery structure:

- concise title;
- explanation of what could not be loaded;
- primary action returning to a valid destination;
- optional retry only when retry can change the result;
- diagnostic logging outside the user-facing copy.

---

## 3. Screen contracts

## 3.1 Home

Purpose: orient the user, show the companion’s current presence, and provide the clearest next action.

Required hierarchy:

1. Companion identity/presence.
2. Primary session action: Start, Resume, or Continue Setup.
3. Recommendation or short context.
4. Secondary access to memory and settings.

Rules:

- The start/resume action must be visible without scrolling on supported iPhone sizes at default text size.
- A recommendation must not visually outrank the action it supports.
- Do not present more than one high-emphasis call to action.
- Companion cosmetics may add character but must not reduce text contrast or control discoverability.
- Permission status should appear only when actionable or blocking.
- Diagnostics and developer modes must be absent from production presentation unless explicitly enabled.

## 3.2 Session setup and permissions

Permissions must be requested in context, immediately before the related capability is needed.

Before the system prompt:

- state what capability is requested;
- explain the direct user benefit;
- explain what still works if denied;
- avoid coercive language;
- provide a user-initiated Continue action.

After denial:

- keep the app usable when possible;
- explain degraded behavior truthfully;
- provide Open Settings only when the user needs to change a system decision;
- never repeatedly trigger a system prompt that cannot reappear.

Health, location, motion, notifications, microphone, or camera permissions must each have distinct rationale copy and independent state handling.

## 3.3 Active Session

Purpose: maintain confidence with minimal visual demand.

### Required visible state

The active screen must communicate:

- session lifecycle: opening, active, paused, ending, completed, or failed;
- companion behavior/state;
- essential movement progress appropriate to the product;
- location/signal condition when it affects session validity;
- clear Pause/Resume and End controls.

### Glance hierarchy

1. **Current companion/session state** in plain language.
2. **Primary metric** such as elapsed time or progress.
3. **Signal or path exception**, only when material.
4. **Primary control** such as Pause/Resume.
5. **Secondary destructive control** such as End.

### Active-session restrictions

- No dense scrolling feed.
- No small floating controls placed close to screen edges.
- No essential interaction that depends on a custom gesture.
- No state communicated only through color, animation, haptics, or audio.
- No transient message that disappears before VoiceOver or slower readers can access it.
- No map detail that competes with safety-critical controls.
- No confirmation dialog for reversible Pause/Resume.
- Ending a session requires a confirmation when accidental activation would lose meaningful progress.

### Control geometry

- Interactive hit regions should be at least 44 × 44 points; primary active-session controls should generally exceed this minimum.
- Separate Pause/Resume and End spatially and semantically.
- Do not place destructive controls immediately adjacent to the highest-frequency action without adequate spacing or confirmation.
- Prefer labeled controls over icon-only controls during movement.
- Preserve one-handed reach by keeping frequent controls in the lower-middle safe region when this does not conflict with system navigation.

### Map use

A map is supporting context, not the primary control surface.

- Keep overlays sparse.
- Distinguish planned route, accepted trace, current position, and companion/world markers by more than color alone.
- Ensure route line contrast against light, dark, satellite, and high-contrast contexts.
- Avoid automatic camera movement that causes disorientation.
- Provide a recenter action when the user can manually move the camera.
- Map failure must not obscure session controls.

## 3.4 Pause state

Pause must be unmistakable.

- Change the primary control label to Resume.
- Present a persistent paused state label.
- Stop or visually suspend movement-dependent animations.
- Do not imply movement progress continues when the underlying engine is paused.
- Explain any subsystem that continues, such as elapsed wall time, only if relevant and truthful.

## 3.5 Error and degraded-state presentation

Errors are categorized by actionability:

| Category | Presentation | Example |
|---|---|---|
| Blocking and actionable | Inline state or alert with primary recovery action | Location authorization required |
| Blocking and not immediately recoverable | Dedicated recovery screen | Persistent storage cannot load |
| Nonblocking degradation | Compact persistent status | GPS accuracy reduced |
| Transient and self-recovering | Brief status with accessible announcement | Reconnecting to signal |
| Developer diagnostic | Logs/receipt only | Internal rejected sample reason |

Error copy must include:

1. what happened;
2. what it means for the current experience;
3. what the user can do next.

Do not expose raw errors, enum names, stack traces, identifiers, or implementation terminology.

## 3.6 Session Summary

Purpose: close the loop and reinforce progress.

Required order:

1. Completion status.
2. One primary outcome.
3. Bond/progression change.
4. A small number of meaningful events or insights.
5. Primary next action.

Rules:

- Distinguish observed facts from interpretive or narrative copy.
- Avoid celebratory claims unsupported by measured data.
- Use plain units and locale-aware formatting.
- Do not overwhelm the summary with every recorded event.
- Ensure the summary remains useful when optional HealthKit, GPS, audio, or route data is unavailable.

## 3.7 Memory History

- Use a standard list or collection with predictable navigation.
- Each row needs a meaningful accessibility label and value.
- Dates, durations, and distances must use locale-aware formatters.
- Empty state must explain what creates a memory and offer a clear route back to starting a session.
- Deletion, if introduced, must be recoverable or confirmed based on consequence.

## 3.8 Settings

- Group settings by user goal, not engineering subsystem.
- Use native `Form`, `Section`, `Picker`, `Toggle`, and navigation patterns unless a custom treatment has a measurable benefit.
- Changes should apply immediately when reversible and understandable.
- Destructive reset actions belong in a separate section with confirmation.
- Cosmetic settings must not affect functional state or unlock claims.
- Include explanatory footers only when a setting’s consequence is not obvious.

---

## 4. Visual system

## 4.1 Typography

- Use semantic text styles such as `.largeTitle`, `.title`, `.headline`, `.body`, `.callout`, `.caption`, and their platform equivalents.
- Support Dynamic Type, including accessibility categories.
- Do not encode critical hierarchy using fixed font sizes.
- Avoid truncation for state, error, permission, and primary-action labels.
- Use `minimumScaleFactor` sparingly; wrapping is preferable for meaningful copy.
- Use monospaced digits selectively for timers and changing metrics to reduce layout jitter.
- Keep line lengths readable; do not stretch body copy across the full width of large devices.

## 4.2 Color

- Use semantic colors and asset-catalog variants for light, dark, increased contrast, and future display contexts.
- Text/background combinations must meet accepted contrast requirements.
- Color may reinforce state but never be the sole state channel.
- Avoid placing text directly over visually complex companion art without a controlled contrast layer.
- Treat red as destructive/error emphasis, not general brand decoration.
- Distinguish path relation, signal quality, and companion state through labels, shapes, icons, or patterns in addition to color.

## 4.3 Materials and iOS 26 visual language

Use system materials and the current Apple design system as a structural layer rather than decorating every surface.

- Allow system navigation, toolbars, controls, and sheets to adopt the platform’s current appearance.
- Avoid manually reproducing system glass effects.
- Use custom glass/material effects only for a bounded, tested purpose.
- Keep content visually distinct from controls layered above it.
- Avoid stacking multiple translucent surfaces that reduce contrast or create unclear hierarchy.
- Provide fallbacks for earlier deployment targets if adopting newer APIs.

## 4.4 Spacing and layout

- Respect safe areas for controls and readable content.
- Full-bleed art or map content may extend under system areas, but controls may not become obstructed.
- Use a consistent spacing scale rather than arbitrary per-screen values.
- Group related elements with proximity before adding borders or cards.
- Avoid card-on-card nesting.
- Prefer adaptive stacks, grids, `ViewThatFits`, and layout priorities over device-model checks.
- Test compact widths, landscape, Display Zoom, and all supported Dynamic Type sizes.

Recommended token scale:

```text
2, 4, 8, 12, 16, 20, 24, 32, 40, 48
```

Components may use a subset, but new one-off spacing values require a documented reason.

## 4.5 Icons

- Prefer SF Symbols for functional icons.
- Choose symbols whose semantics remain clear independent of Waykin lore.
- Pair unfamiliar symbols with text.
- Use symbol variants and rendering modes consistently.
- Set accessibility labels for meaningful icon-only controls; hide decorative symbols from accessibility.
- Do not use custom icons merely to differentiate the brand when a standard symbol better communicates the action.

## 4.6 Motion and haptics

Motion must explain change, preserve continuity, or add bounded emotional expression.

- Respect Reduce Motion.
- Replace large movement, parallax, zoom, repeated pulsing, and spatial transitions with fades or static changes when Reduce Motion is enabled.
- Avoid continuous decorative animation during active movement.
- Companion animation must not obscure controls or imply false state.
- Haptics reinforce, but do not replace, visible and audible feedback.
- Use success, warning, impact, or selection feedback according to semantic meaning.
- Do not generate frequent haptics from high-rate sensor updates.

---

## 5. Accessibility contract

Every production screen must support:

- VoiceOver;
- Voice Control;
- Switch Control-compatible standard actions;
- Dynamic Type through accessibility sizes;
- Increase Contrast;
- Reduce Transparency;
- Differentiate Without Color;
- Reduce Motion;
- Bold Text;
- Button Shapes where applicable;
- light and dark appearance;
- portrait and supported landscape behavior;
- content-size and localization expansion.

### 5.1 Semantic structure

- Use native controls whenever possible.
- Accessibility reading order must follow task order.
- Group visual composites only when the combined element is more understandable than its children.
- Expose label, value, hint, traits, and actions intentionally.
- Do not repeat the visible label in the hint.
- Use headings for meaningful screen sections.
- Use live-region or announcement behavior sparingly for important asynchronous state changes.
- Avoid announcing every sensor update, timer tick, map coordinate, or animation frame.

### 5.2 Active-session accessibility

The active session must expose a compact semantic sequence:

1. current lifecycle and companion state;
2. primary metric;
3. meaningful warning or signal condition;
4. Pause/Resume;
5. End.

Map detail and decorative companion subviews should not flood the accessibility tree.

### 5.3 Multiple-sense communication

- Audio event → visible state/caption and accessible semantic update.
- Visual warning → spoken label and optional haptic.
- Haptic-only change → visible/spoken equivalent.
- Color state → label/icon/shape equivalent.

### 5.4 Assistive Access

Waykin should remain usable inside the system’s default Assistive Access presentation. A dedicated Assistive Access scene is optional until supported as a product requirement, but architecture must not prevent one.

A future dedicated scene should reduce the experience to:

- Start/Resume;
- current state;
- Pause/Resume;
- End;
- one clear completion screen.

---

## 6. Content design

### 6.1 Voice

Waykin copy may be atmospheric, but operational copy must remain literal.

Use two channels:

| Channel | Function | Example style |
|---|---|---|
| Operational | State, permission, error, action | “Location signal is weak. Waykin is keeping the session active.” |
| Companion/narrative | Character and emotional resonance | “Lira stays close.” |

Never use narrative language where the user needs to understand system consequence.

### 6.2 Labels

- Use verbs for actions: Start Walk, Pause, Resume, End Session, Open Settings.
- Use nouns for destinations: Memories, Settings, Session Summary.
- Avoid vague actions such as Continue when a more specific label is possible.
- Keep button labels stable across appearances and states unless the action itself changes.

### 6.3 Status messages

Status copy should be short, present-tense, and outcome-oriented.

Bad: “The app was unable to acquire sufficient CLLocationManager updates.”  
Good: “Location signal is unavailable. Move to an open area or end the session.”

### 6.4 Localization

- All user-facing strings must be localizable.
- Avoid concatenating translated fragments.
- Use formatters for date, time, duration, distance, energy, and numbers.
- Test pseudo-localization, long German-like expansion, and right-to-left layout.
- Avoid embedding text inside image assets.

---

## 7. Input, feedback, and state transitions

### 7.1 Input rules

- Every action must provide immediate acknowledgment.
- Disable actions only when the reason is evident; otherwise explain the unavailable state.
- Prevent duplicate submissions and repeated session-start requests.
- Maintain stable control placement when state changes.
- Use progress indicators for operations whose duration is perceptible and uncertain.
- Do not show indefinite progress when the app is actually awaiting user permission or external action.

### 7.2 State machine integrity

UI state must be derived from canonical application/domain state, not duplicated into loosely synchronized booleans.

Each screen should define:

- valid states;
- visible content per state;
- allowed actions per state;
- transition trigger;
- failure transition;
- recovery transition.

Impossible combinations must be prevented by type design or asserted in tests. Example: a session must not simultaneously present both Pause and Resume as primary actions.

### 7.3 Destructive actions

Confirmation is required when an action is difficult to recover from or discards meaningful progress.

Confirmation copy should name the consequence:

- Title: “End this session?”
- Message: “Your completed distance and events will be saved up to this point.”
- Destructive action: “End Session”
- Cancel action: “Keep Moving”

Avoid generic “Are you sure?” dialogs.

---

## 8. Performance and responsiveness

The UI must remain responsive under active location, HealthKit, audio, map, RealityKit, and animation work.

- Perform expensive computation and I/O outside rendering paths.
- Keep observable state granular enough to avoid full-screen invalidation on high-rate updates.
- Throttle presentation updates that do not need sensor frequency.
- Use stable identity in lists and dynamic content.
- Avoid type erasure and deeply nested conditional view trees when they obscure performance.
- Profile SwiftUI updates, CPU, memory, power, and animation hitching on physical devices.
- Avoid unbounded route traces, event arrays, overlays, or retained view models.
- Degrade decorative effects before degrading controls, text, or state accuracy.

Target expectations:

- Tap acknowledgment appears immediately.
- Scrolling and common transitions remain visually smooth.
- Active-session controls remain responsive during signal changes.
- Background/foreground transitions do not duplicate views, overlays, companion entities, or navigation destinations.

---

## 9. Privacy and trust

- Display only data needed for the current task.
- Do not expose precise location, HealthKit values, receipts, or internal identifiers unnecessarily.
- Avoid screenshots or previews containing real user routes unless explicitly designed and protected.
- Clearly distinguish demo/simulated data from physical-session data.
- Do not imply medical, safety, performance, or hardware capabilities that have not been validated.
- Permission copy must match actual data use.
- UI telemetry must avoid sensitive payloads when event names and state categories suffice.

---

## 10. Engineering definition of done

A UI change is complete only when:

1. It conforms to the screen and state contracts in this document.
2. It uses canonical state and does not introduce presentation drift.
3. It supports accessibility settings and semantic navigation.
4. It behaves at smallest and largest supported layouts and Dynamic Type sizes.
5. It supports light/dark and increased-contrast contexts.
6. It provides loading, empty, error, degraded, and success behavior where applicable.
7. It is covered by unit, snapshot/preview, and/or UI automation appropriate to risk.
8. It is exercised on a physical iPhone for active-session or sensor-dependent changes.
9. It adds no unsupported product claim.
10. It updates this documentation when introducing a new pattern.

---

## 11. Prohibited patterns

Unless explicitly approved and documented, do not introduce:

- fixed-size text for primary content;
- icon-only critical controls;
- color-only state communication;
- custom back gestures;
- hidden essential controls revealed only by gesture;
- auto-advancing critical content;
- non-dismissible blocking overlays without recovery;
- nested scroll views on core screens;
- arbitrary per-screen design tokens;
- runtime state duplicated across multiple view-local flags;
- decorative animation that continues under Reduce Motion;
- unbounded map overlays or event feeds;
- user-facing raw diagnostic strings;
- forced dark mode as a substitute for adaptive design;
- full-width edge-to-edge buttons that ignore safe margins;
- claims that AR, glasses, HealthKit, or companion behavior are active when the corresponding adapter is unavailable or disabled.

---

## 12. Decision rubric

When choosing between two UI implementations, prefer the one that:

1. reduces time to understand current state;
2. reduces interaction count;
3. uses a system convention;
4. remains usable without sight, color perception, precise touch, or audio;
5. degrades gracefully when data is unavailable;
6. is easier to test deterministically;
7. produces less rendering and state complexity;
8. preserves Waykin’s emotional identity without obscuring function.
