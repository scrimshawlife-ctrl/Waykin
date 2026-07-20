import SwiftUI
import WaykinCore

/// Semantic chrome binding for CANDIDATE_v0.2 HO-004 (color + icon + text).
/// Presentation only — does not invent gameplay states.
enum WKSessionChromeState: String, CaseIterable, Sendable {
    case dormant
    case manifesting
    case guide
    case rival
    case hunter
    case sanctuary
    case bondUpdate
    case pause
    case safetyPause
    case caution
    case trackingLoss

    /// Short uppercase chip (≤12 chars per design).
    var chipLabel: String {
        switch self {
        case .dormant: "DORMANT"
        case .manifesting: "ARRIVING"
        case .guide: "GUIDE"
        case .rival: "RIVAL"
        case .hunter: "HUNTER"
        case .sanctuary: "SANCTUARY"
        case .bondUpdate: "BOND"
        case .pause: "PAUSED"
        case .safetyPause: "SAFETY"
        case .caution: "CAUTION"
        case .trackingLoss: "SIGNAL"
        }
    }

    var icon: WKIcon {
        switch self {
        case .dormant: .dormant
        case .manifesting: .companion
        case .guide: .guide
        case .rival: .rival
        case .hunter: .hunter
        case .sanctuary: .sanctuary
        case .bondUpdate: .bond
        case .pause: .pause
        case .safetyPause: .safetyPause
        case .caution: .caution
        case .trackingLoss: .trackingLoss
        }
    }

    func color(in theme: WKTheme) -> Color {
        switch self {
        case .dormant: theme.textTertiary
        case .manifesting, .bondUpdate: theme.bond
        case .guide: theme.guide
        case .rival: theme.rival
        case .hunter: theme.hunter
        case .sanctuary: theme.sanctuary
        case .pause: theme.pause
        case .safetyPause: theme.safetyPause
        case .caution, .trackingLoss: theme.caution
        }
    }

    /// Map companion presentation → chrome state (path/GPS may override).
    static func resolve(
        behavior: CompanionBehaviorState,
        pursuit: PursuitState,
        isPaused: Bool,
        isOpening: Bool,
        pathRelation: PathRelation,
        gpsProblem: Bool
    ) -> WKSessionChromeState {
        if isPaused { return .pause }
        if gpsProblem { return .trackingLoss }
        if isOpening { return .manifesting }
        switch pathRelation {
        case .offPath, .strained: return .caution
        case .establishing, .onPath, .recovered: break
        }
        switch pursuit {
        case .close, .approaching: return .hunter
        case .noticed: return .rival
        case .fading: return .guide
        case .inactive: break
        }
        switch behavior {
        case .lead: return .guide
        case .celebrate: return .bondUpdate
        case .rest: return .sanctuary
        case .observe: return .guide
        case .drawNear, .follow, .idle: return .guide
        }
    }
}

/// Orbital bond ring (relationship viz — not an XP bar).
struct WKBondOrbitalRing: View {
    var bondLevel: Int
    var size: CGFloat = 56
    @Environment(\.wkTheme) private var theme

    /// Soft fill 0…1 from bond level (presentation only).
    private var progress: CGFloat {
        let level = max(0, min(10, bondLevel))
        return 0.18 + CGFloat(level) / 10.0 * 0.72
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.textTertiary.opacity(0.25), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    theme.bond,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            WKBondFilamentMark(size: size * 0.55)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bond")
        .accessibilityValue("Level \(bondLevel)")
    }
}

/// State chip: icon + uppercase label + semantic wash.
struct WKStateChip: View {
    let state: WKSessionChromeState
    @Environment(\.wkTheme) private var theme

    var body: some View {
        HStack(spacing: WKTokens.Space.xs) {
            WKIconView(icon: state.icon, size: 16)
            Text(state.chipLabel)
                .font(.caption.weight(.semibold))
                .tracking(0.6)
        }
        .foregroundStyle(state.color(in: theme))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(state.color(in: theme).opacity(0.14))
        .clipShape(Capsule(style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session state")
        .accessibilityValue(state.chipLabel)
        .accessibilityIdentifier("waykin.session.stateChip.\(state.rawValue)")
    }
}
