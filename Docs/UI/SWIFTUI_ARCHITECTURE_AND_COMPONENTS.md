# Waykin SwiftUI Architecture and Component Standard

Status: **CANONICAL IMPLEMENTATION GUIDANCE**  
Applies to: SwiftUI presentation code, reusable components, view state, previews, accessibility semantics, and UI integration boundaries.

---

## 1. Architectural objectives

Waykin UI architecture must:

- preserve one authoritative application/domain state;
- make valid and invalid screen states explicit;
- isolate high-frequency runtime updates from unrelated views;
- keep visual styling reusable and semantic;
- make accessibility behavior part of each component contract;
- support deterministic previews and UI tests;
- allow companion, map, audio, HealthKit, AR, and glasses adapters to degrade independently;
- remain maintainable by one developer.

The architecture should minimize files and abstractions that do not reduce ambiguity. Reuse should follow observed repetition or a stable semantic pattern, not speculative framework-building.

---

## 2. Layer boundaries

```text
Domain/Core
  Movement, world state, events, companion runtime, audio cue intent,
  progress, memory, persistence contracts
        ↓
Application Model
  Orchestration, lifecycle, route state, permissions, adapters,
  presentation snapshots
        ↓
Presentation Model
  Small immutable values formatted for one screen/component
        ↓
SwiftUI Views
  Layout, native controls, animation, accessibility, user action dispatch
```

### 2.1 Dependency rule

Dependencies point downward. Views may dispatch intents upward but must not own or reproduce domain rules.

A view must not:

- calculate bond progression;
- infer runtime behavior from unrelated booleans;
- decide whether a movement sample is accepted;
- derive unsupported product claims;
- directly coordinate HealthKit, location, audio, persistence, or AR adapters;
- mutate multiple subsystems in one button closure without routing through an application action.

---

## 3. Canonical state ownership

### 3.1 Application state

The app-level observable model owns:

- navigation path;
- session lifecycle;
- canonical presentation snapshots;
- permission and adapter state;
- selected appearance/cosmetic preferences;
- durable loading status;
- application actions.

### 3.2 View-local state

A view may own only ephemeral presentation state such as:

- whether a confirmation dialog is visible;
- current focus target;
- local disclosure expansion;
- temporary animation phase;
- sheet-local draft input not yet committed.

Do not store canonical session, permission, navigation, companion, or persistence state in `@State` merely to make rendering convenient.

### 3.3 State modeling

Prefer enums with associated values over several interacting flags.

Recommended:

```swift
enum SessionPresentationState: Equatable {
    case preparing
    case requestingPermission(PermissionKind)
    case active(ActiveSessionPresentation)
    case paused(ActiveSessionPresentation)
    case ending
    case completed(SessionSummaryPresentation)
    case failed(SessionFailurePresentation)
}
```

Avoid:

```swift
var isLoading: Bool
var isActive: Bool
var isPaused: Bool
var isEnding: Bool
var hasFailed: Bool
```

When booleans are unavoidable, impossible combinations must be asserted and covered by tests.

---

## 4. Presentation snapshots

Complex or high-frequency domain state should be compressed into immutable, screen-specific presentation snapshots.

Example:

```swift
struct ActiveSessionPresentation: Equatable, Sendable {
    let lifecycleLabel: String
    let companionStatement: String
    let elapsed: Duration
    let primaryMetric: Measurement<UnitLength>?
    let signalState: SignalPresentation
    let pathState: PathPresentation
    let isPaused: Bool
    let canEnd: Bool
}
```

Properties should retain semantic values where formatting depends on locale or environment. Avoid storing every value as a preformatted string unless deterministic snapshots specifically require it.

A presentation snapshot should:

- contain only values needed by the consuming surface;
- have stable `Equatable` behavior;
- avoid framework objects with hidden identity;
- avoid direct service references;
- define fallback behavior for absent optional adapters.

---

## 5. View composition

### 5.1 Screen structure

Each screen should be assembled from semantic sections:

```swift
struct ActiveSessionView: View {
    var body: some View {
        ZStack {
            backgroundContent
            foregroundHierarchy
        }
        .safeAreaInset(edge: .bottom) {
            sessionControls
        }
    }
}
```

Prefer extracted computed views or small component types when they represent a semantic unit. Avoid extraction that only renames two modifiers and obscures reading order.

### 5.2 Recommended screen decomposition

```text
HomeView
├── CompanionHeader
├── PrimarySessionAction
├── RecommendationCard
└── HomeSecondaryActions

ActiveSessionView
├── SessionEnvironmentLayer (map/art)
├── CompanionPresenceView
├── SessionStateHeader
├── PrimaryMetricView
├── DegradedStateBanner
└── ActiveSessionControls

SessionSummaryView
├── CompletionHeader
├── PrimaryOutcome
├── BondChangeView
├── MeaningfulEventList
└── SummaryActions
```

### 5.3 Maximum responsibility

A component should have one primary semantic responsibility. A screen may coordinate children, but reusable components should not independently navigate, persist, start services, and render presentation.

---

## 6. Design tokens

Create or preserve a central theme layer with semantic tokens.

Recommended categories:

```swift
enum WaykinSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

enum WaykinRadius {
    static let control: CGFloat = 12
    static let card: CGFloat = 20
    static let prominent: CGFloat = 28
}
```

Use semantic color names rather than literal appearance names:

```text
backgroundPrimary
backgroundElevated
contentPrimary
contentSecondary
accentCompanion
stateSuccess
stateWarning
stateCritical
routePlanned
routeObserved
```

Rules:

- Tokens must support light, dark, and increased-contrast variants.
- Avoid exposing raw RGB values throughout views.
- Do not create a token for every observed number.
- New tokens require use in at least one stable semantic role.
- Component APIs accept semantic role or style, not arbitrary styling closures, unless extensibility is proven necessary.

---

## 7. Component contracts

Every reusable component must define:

- required inputs;
- optional/fallback inputs;
- user actions;
- supported states;
- Dynamic Type behavior;
- accessibility representation;
- Reduce Motion behavior if animated;
- loading/error/empty behavior when relevant;
- preview coverage.

## 7.1 Primary action button

Use native `Button` with a Waykin `ButtonStyle` or system prominent style.

Contract:

- visible text label;
- minimum 44-point hit region, larger on active screens;
- loading state prevents duplicate action;
- disabled reason is visually or contextually understandable;
- no destructive styling;
- no layout shift when spinner appears;
- VoiceOver label describes action, not appearance.

## 7.2 Destructive action

- Use `.destructive` role when supported.
- Keep visually secondary until confirmation.
- Confirmation text names the exact consequence.
- Avoid custom red surfaces that resemble the primary action.

## 7.3 Status banner

A banner is for persistent, actionable, or materially degraded state.

Inputs:

- severity;
- title;
- optional detail;
- optional action;
- accessibility announcement policy.

The banner must not auto-dismiss when it contains required information.

## 7.4 Companion presence

The companion component may render art, model, animation, and symbolic state, but its public contract should be a bounded presentation value.

It must:

- render a static fallback;
- tolerate missing 3D/AR assets;
- preserve accessible summary text;
- respect Reduce Motion;
- avoid capturing session orchestration;
- avoid using cosmetic skin selection to imply functionality;
- expose no duplicate accessibility children for decorative anatomy or particles.

## 7.5 Metric display

- Use semantic unit formatting.
- Use monospaced digits for continuously changing numeric values where beneficial.
- Provide a concise accessibility value.
- Avoid updating VoiceOver every second.
- Do not show precision unsupported by source accuracy.

## 7.6 Map container

- Encapsulate camera, annotation, trace, and overlay presentation.
- Receive immutable route/trace values or a bounded map model.
- Expose recenter as an explicit action.
- Keep controls outside map gesture conflict zones.
- Avoid using the map as the sole representation of route or signal state.
- Define empty and unavailable states.

---

## 8. Environment and dependency injection

Use SwiftUI environment for truly cross-cutting presentation dependencies such as:

- app model or action dispatcher;
- theme/skin presentation;
- feature availability presentation;
- locale and accessibility environment supplied by SwiftUI.

Do not hide arbitrary services in the environment merely to avoid initializer parameters.

Views intended for reuse and preview should accept explicit presentation values and action closures where possible.

Example:

```swift
struct SessionControls: View {
    let state: ControlState
    let onPrimary: () -> Void
    let onEnd: () -> Void
}
```

This is preferable to having the component discover and mutate the entire app model.

---

## 9. Navigation architecture

- Define routes as stable, Hashable values.
- Route values contain identifiers or small immutable parameters, not service objects.
- App-level navigation mutation occurs through named application actions.
- Child components request navigation through actions rather than modifying `NavigationPath` directly.
- Sheets have explicit item/state models.
- Dismissal must reconcile application state.
- A missing persisted destination resolves through a recovery route.

Recommended action surface:

```swift
enum AppAction {
    case startSession(ExperienceID)
    case pauseSession
    case resumeSession
    case requestEndSession
    case confirmEndSession
    case openMemoryHistory
    case openSettings
    case dismissSettings
}
```

Not every action must use one global enum, but naming and routing should preserve a single orchestration boundary.

---

## 10. Accessibility implementation

### 10.1 Native semantics first

Prefer `Button`, `Toggle`, `Picker`, `NavigationLink`, `List`, `Form`, `ProgressView`, and semantic text styles.

Use explicit modifiers when defaults are insufficient:

```swift
.accessibilityLabel("Pause session")
.accessibilityHint("Stops movement tracking until you resume")
.accessibilityValue("Active for 12 minutes")
.accessibilityAddTraits(.isHeader)
.accessibilityElement(children: .combine)
```

Hints explain result, not action name.

### 10.2 Reading order

Visual overlays often create an incorrect accessibility tree. Verify active-session order explicitly. Use sort priority sparingly and prefer source-order alignment.

### 10.3 Custom actions

Use custom accessibility actions when a visually compact component contains meaningful secondary actions, but never hide the only route to a critical function inside a custom action.

### 10.4 Announcements

Announce only meaningful asynchronous changes:

- session paused/resumed;
- location becomes unavailable or recovers;
- route/path state materially changes;
- session completes or fails.

Do not announce timers, coordinates, every movement sample, decorative companion motion, or rapid event streams.

### 10.5 Dynamic Type

- Use text styles.
- Allow vertical growth.
- Replace horizontal arrangements with vertical alternatives at accessibility sizes using `ViewThatFits`, environment checks, or adaptive layout.
- Never clip primary action labels.
- Test at the largest accessibility category.

---

## 11. Animation architecture

Animation should be driven by semantic state transitions, not incidental view recomputation.

Recommended:

```swift
.animation(reduceMotion ? nil : .snappy, value: presentation.behavior)
```

Rules:

- Scope animation to the exact value that should animate.
- Avoid global `.animation` modifiers high in the tree.
- Keep continuous animations isolated and pausable.
- Stop animation when app is inactive, session is paused, or Reduce Motion is enabled where appropriate.
- Do not animate high-rate location changes directly without smoothing/throttling.
- Verify animation does not create duplicate RealityKit/AR entities.

---

## 12. Concurrency and main-actor discipline

- UI-observable mutation occurs on the main actor.
- Long-running work must be cancellable.
- Start/stop tasks according to session and scene lifecycle.
- Store task identity or generation tokens when stale results could overwrite current state.
- Do not launch unstructured tasks from `body`.
- Use `.task(id:)` only when the dependency and cancellation semantics are understood.
- Never block the main actor with persistence, asset decoding, route processing, HealthKit queries, or heavy geometry work.

---

## 13. Rendering and update performance

- Split high-frequency state into the smallest consuming subtree.
- Use immutable `Equatable` presentation snapshots.
- Avoid passing the full app model through every component.
- Keep `body` pure and inexpensive.
- Precompute formatted values when profiling proves formatting is significant.
- Cap traces, events, and overlays.
- Use lazy containers for long histories.
- Preserve stable IDs.
- Avoid rebuilding 3D/AR resources on every SwiftUI update.
- Instrument with SwiftUI and Time Profiler on physical hardware.

---

## 14. Preview standard

Each reusable component and screen must include deterministic previews covering applicable states.

Minimum screen preview set:

- default light;
- dark;
- largest accessibility Dynamic Type;
- compact iPhone;
- long localized strings or pseudo-localized content;
- empty;
- degraded/error;
- Reduce Motion where animation matters.

Preview fixtures must:

- use fixed dates and identifiers;
- avoid network, location, HealthKit, audio, AR, and persistence dependencies;
- be stored in a bounded preview fixture namespace;
- not mutate production stores.

Recommended preview names:

```text
Home — Ready
Home — Permission Required
Active — Moving
Active — Paused
Active — Weak Signal
Summary — Complete
Summary — Partial Data
Memory — Empty
Memory — Populated
```

---

## 15. UI automation seams

Production UI must expose stable accessibility identifiers for automation on:

- primary start/resume action;
- active lifecycle state;
- companion state statement;
- primary metric;
- Pause/Resume;
- End;
- end confirmation;
- summary root and primary result;
- memory navigation and list;
- settings presentation and critical controls;
- blocking permission/error recovery actions.

Identifier rules:

- semantic and stable;
- no user data;
- no array index unless identity is inherently positional;
- no reliance on localized visible text;
- do not use identifiers as user-facing accessibility labels.

Example namespace:

```text
home.primarySessionAction
session.lifecycle
session.primaryMetric
session.pauseResume
session.end
session.endConfirmation
summary.root
memory.list
settings.root
```

---

## 16. Logging and analytics boundary

UI logging may record:

- screen/state transition category;
- action category;
- success/failure/degraded outcome;
- feature availability category;
- performance timing;
- accessibility test receipt metadata.

It should not record precise location, HealthKit values, route geometry, user-entered text, or companion memory content unless a separate privacy-reviewed requirement exists.

UI event names must reflect semantic actions, not fragile implementation details.

---

## 17. File organization

Prefer feature-oriented organization while preserving a small-project footprint:

```text
App/
├── Application/
├── Navigation/
├── Theme/
├── Features/
│   ├── Home/
│   ├── Session/
│   ├── Summary/
│   ├── Memory/
│   └── Settings/
├── Components/
├── AR/
└── PreviewSupport/
```

Do not reorganize solely to match this tree. Apply it incrementally when files become difficult to navigate or merge. A large existing file should be decomposed by semantic responsibility, with tests passing after each extraction.

---

## 18. Change protocol

For any material UI change:

1. Define the affected screen/state contract.
2. Identify canonical source state and action boundary.
3. Add/update presentation snapshot.
4. Implement native semantic structure first.
5. Add visual styling through tokens/components.
6. Add accessibility semantics and accommodations.
7. Add deterministic previews.
8. Add unit/UI tests.
9. Run the validation matrix.
10. Capture physical-device evidence when active movement, map, audio, AR, sensor, brightness, or one-handed ergonomics are affected.

A PR must not introduce a new reusable component without documenting its semantic purpose and state behavior in code or this standard.
