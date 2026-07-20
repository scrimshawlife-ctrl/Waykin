import SwiftUI

/// First-run onboarding: intro → permissions honesty → safety brief (CANDIDATE_v0.2 Stage 6).
struct OnboardingFlowView: View {
    @Environment(WaykinAppModel.self) private var appModel
    @Environment(\.wkTheme) private var theme
    @State private var step: Step = .intro

    enum Step: Int, CaseIterable {
        case intro
        case permissions
        case safety
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                progress
                    .padding(.top, WKTokens.Space.md)
                TabView(selection: $step) {
                    introPanel.tag(Step.intro)
                    permissionsPanel.tag(Step.permissions)
                    safetyPanel.tag(Step.safety)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: WKTokens.Motion.standard), value: step)
            }
        }
        .interactiveDismissDisabled()
        .accessibilityIdentifier("waykin.onboarding.root")
    }

    private var progress: some View {
        HStack(spacing: WKTokens.Space.xs) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? theme.guide : theme.textTertiary.opacity(0.35))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, WKTokens.Space.screenMarginX)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(step.rawValue + 1) of \(Step.allCases.count)")
    }

    private var introPanel: some View {
        VStack(spacing: WKTokens.Space.xl) {
            Spacer(minLength: 0)
            WKBondFilamentMark(size: 72)
            Text("Waykin")
                .font(WKTokens.TypeScale.title)
                .foregroundStyle(theme.textPrimary)
            VStack(spacing: WKTokens.Space.md) {
                introLine("A companion bound to your movement.")
                introLine("Listen more than look.")
                introLine("You can stop anytime.")
            }
            .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            primaryButton("Continue") {
                step = .permissions
            }
            .accessibilityIdentifier("waykin.onboarding.intro.continue")
        }
        .padding(WKTokens.Space.screenMarginX)
        .accessibilityIdentifier("waykin.onboarding.intro")
    }

    private var permissionsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WKTokens.Space.lg) {
                Text("What we ask for")
                    .font(WKTokens.TypeScale.title)
                    .foregroundStyle(theme.textPrimary)
                    .accessibilityIdentifier("waykin.onboarding.permissions")

                Text("Calm, non-coercive. Deny anything and Demo Mode still works.")
                    .font(.callout)
                    .foregroundStyle(theme.textSecondary)

                permissionRow(
                    icon: .location,
                    title: "Location",
                    body: "During a real walk only — distance, pace, and path progress. Not for ads."
                )
                permissionRow(
                    icon: .companion,
                    title: "Camera",
                    body: "Only if you open AR, to place Lira in the world. Frames are not a photo library."
                )
                permissionRow(
                    icon: .motion,
                    title: "Health (optional)",
                    body: "Soft activity enrichment. Demo Mode never requires Health."
                )

                Text("System dialogs appear when you start a walk or AR — not all at once here.")
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)

                primaryButton("Continue") {
                    step = .safety
                }
                .accessibilityIdentifier("waykin.onboarding.permissions.continue")

                Button("Not now — use Demo Mode") {
                    // Still require safety acknowledgment before full home.
                    step = .safety
                }
                .frame(maxWidth: .infinity, minHeight: WKTokens.Space.minTouch)
                .foregroundStyle(theme.guideText)
                .accessibilityIdentifier("waykin.onboarding.permissions.notNow")
            }
            .padding(WKTokens.Space.screenMarginX)
        }
    }

    private var safetyPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WKTokens.Space.lg) {
                HStack {
                    WKIconView(icon: .sanctuary, size: 28)
                        .foregroundStyle(theme.sanctuaryText)
                    Text("Safety")
                        .font(WKTokens.TypeScale.title)
                        .foregroundStyle(theme.textPrimary)
                }
                .accessibilityIdentifier("waykin.onboarding.safety")

                Text("Protective contract before movement.")
                    .font(.callout)
                    .foregroundStyle(theme.textSecondary)

                ForEach(LegalContent.safetyBullets, id: \.self) { line in
                    HStack(alignment: .top, spacing: WKTokens.Space.sm) {
                        Text("•")
                            .foregroundStyle(theme.sanctuaryText)
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Full text: Settings → Legal → Safety.")
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)

                primaryButton("I understand") {
                    appModel.completeOnboarding()
                }
                .accessibilityIdentifier("waykin.onboarding.safety.acknowledge")
            }
            .padding(WKTokens.Space.screenMarginX)
        }
        .background(theme.sanctuary.opacity(0.12).ignoresSafeArea())
    }

    private func introLine(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.medium))
            .foregroundStyle(theme.textPrimary)
    }

    private func permissionRow(icon: WKIcon, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: WKTokens.Space.md) {
            WKIconView(icon: icon, size: 24)
                .foregroundStyle(theme.guide)
                .frame(width: 40, height: 40)
                .background(theme.guide.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: WKTokens.Radius.iconContainer, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(WKTokens.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WKTokens.Radius.medium, style: .continuous))
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .tint(theme.guide)
    }
}

// MARK: - Legal screens (Settings)

enum LegalDocument: String, CaseIterable, Identifiable {
    case privacy
    case terms
    case safety
    case notices

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: "Privacy"
        case .terms: "Terms of Use"
        case .safety: "Safety"
        case .notices: "Notices"
        }
    }

    var bodyText: String {
        switch self {
        case .privacy: LegalContent.privacy
        case .terms: LegalContent.terms
        case .safety: LegalContent.safety
        case .notices: LegalContent.notices
        }
    }
}

enum LegalContent {
    static let safetyBullets: [String] = [
        "Stay aware of traffic, terrain, weather, and other people.",
        "Use a safe volume — leave room to hear the world.",
        "Pause or end anytime. Stopping is never a failure.",
        "Hunt pressure is controlled fiction — not real danger.",
        "AR is optional. Skip it when the world is busy.",
        "Do not use while driving or operating machinery.",
        "Health readings (if enabled) are not medical care."
    ]

    static let privacy = """
    Waykin Privacy (summary)

    We do not sell personal data. MVP walks work without a cloud account.

    Location — only during a real walk you start, for distance and path progress. Field receipts are privacy-filtered and must not archive precise GPS dumps.

    Camera — only for AR while you open AR. Not a social photo product.

    Health — optional soft enrichment. Demo Mode never requires Health.

    Local data — bond, memories, appearance, and lab receipts stay on device unless you add future services.

    Full notice: docs/legal/PRIVACY.md in the project repository.
    """

    static let terms = """
    Waykin Terms (summary)

    Software is Apache 2.0 licensed (see Notices). This is an experiential walking app, not medical advice and not certified turn-by-turn navigation.

    You are responsible for outdoor safety. You may stop anytime.

    Do not use Waykin to harm others or while driving. Platform frameworks (Apple) remain under their terms.

    Full terms: docs/legal/TERMS.md in the project repository.
    """

    static let safety = """
    Waykin Safety Brief

    \(safetyBullets.map { "• \($0)" }.joined(separator: "\n"))

    If something feels wrong in the real world, pause the app and handle that first.

    Full brief: docs/legal/SAFETY.md in the project repository.
    """

    static let notices = """
    Notices

    Waykin source is licensed under Apache License 2.0 (LICENSE file).

    Apple frameworks (SwiftUI, CoreLocation, MapKit, ARKit, RealityKit, HealthKit, AVFoundation) are subject to Apple’s agreements.

    Current UI uses system fonts unless a font license is added beside bundled font files.

    Full notices: docs/legal/NOTICES.md in the project repository.
    """
}

struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.wkTheme) private var theme

    var body: some View {
        ScrollView {
            Text(document.bodyText)
                .font(.body)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WKTokens.Space.screenMarginX)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("waykin.legal.\(document.rawValue)")
    }
}

struct LegalListView: View {
    @Environment(\.wkTheme) private var theme

    var body: some View {
        List(LegalDocument.allCases) { doc in
            NavigationLink(doc.title) {
                LegalDocumentView(document: doc)
            }
            .accessibilityIdentifier("waykin.legal.link.\(doc.rawValue)")
        }
        .navigationTitle("Legal")
        .accessibilityIdentifier("waykin.legal.list")
    }
}
