# Waykin iPhone UI/UX Engineering Documentation

Status: **CANONICAL ENGINEERING GUIDANCE**  
Scope: Waykin iPhone application UI, interaction design, accessibility, implementation, testability, and release validation.  
Baseline: `main` at `128ddc28e9d3b6d59b4f8723d5d036f5a4d9011e` when this documentation set was created.

## Purpose

This documentation defines how Waykin should look, behave, adapt, communicate state, and be validated on iPhone. It translates current Apple platform guidance into product-specific engineering constraints for an outdoor, audio-first movement experience.

Waykin is not a conventional dashboard app. During active use, the user may be walking, running, biking, wearing headphones, viewing the phone in bright light, operating it one-handed, or relying primarily on sound. The interface must therefore minimize visual demand while preserving safety, confidence, state awareness, recoverability, and accessibility.

## Canonical documents

1. [`WAYKIN_UI_UX_ENGINEERING_STANDARD.md`](./WAYKIN_UI_UX_ENGINEERING_STANDARD.md)  
   Product principles, information architecture, navigation, state communication, interaction rules, visual system, accessibility, content design, performance, privacy, and implementation requirements.

2. [`SWIFTUI_ARCHITECTURE_AND_COMPONENTS.md`](./SWIFTUI_ARCHITECTURE_AND_COMPONENTS.md)  
   SwiftUI architecture, component boundaries, state ownership, design tokens, reusable controls, dependency rules, previews, instrumentation, and implementation patterns.

3. [`UI_UX_VALIDATION_AND_RELEASE_CHECKLIST.md`](./UI_UX_VALIDATION_AND_RELEASE_CHECKLIST.md)  
   Definition of done, test matrix, accessibility audit, device protocol, automated checks, review evidence, regression gates, and release acceptance criteria.

## Authority and precedence

When requirements conflict, apply this order:

1. User safety and operating-context clarity.
2. Accessibility and system accommodation.
3. Correct representation of runtime state.
4. Recoverability and prevention of destructive mistakes.
5. Apple platform conventions.
6. Waykin product identity and visual expression.
7. Decorative polish.

A visual treatment must never override semantic correctness, legibility, accessibility, touch ergonomics, safe-area compliance, or truthful state presentation.

## Source basis

This standard is grounded primarily in Apple’s official Human Interface Guidelines and SwiftUI documentation:

- Apple Human Interface Guidelines: <https://developer.apple.com/design/human-interface-guidelines/>
- Design principles: <https://developer.apple.com/design/human-interface-guidelines/design-principles>
- Layout: <https://developer.apple.com/design/human-interface-guidelines/layout>
- Accessibility: <https://developer.apple.com/design/human-interface-guidelines/accessibility>
- SwiftUI accessibility fundamentals: <https://developer.apple.com/documentation/swiftui/accessibility-fundamentals>
- Accessible navigation: <https://developer.apple.com/documentation/swiftui/accessible-navigation>
- WWDC25, Build a SwiftUI app with the new design: <https://developer.apple.com/videos/play/wwdc2025/323/>
- WWDC25, Principles of inclusive app design: <https://developer.apple.com/videos/play/wwdc2025/316/>
- WWDC25, Customize your app for Assistive Access: <https://developer.apple.com/videos/play/wwdc2025/238/>
- WWDC25, Record, replay, and review: UI automation with Xcode: <https://developer.apple.com/videos/wwdc2025/>

## Maintenance rule

Any pull request that materially changes navigation, active-session interaction, controls, visual hierarchy, accessibility behavior, presentation state, or UI architecture must update the relevant document or explicitly state why the existing contract remains sufficient.
