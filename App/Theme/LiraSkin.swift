import SwiftUI

/// Cosmetic skins for Lira — materials only, same rig/poses/anchors.
/// Dawn default; Veil / Rupture optional. No marketplace unlock economy.
enum LiraSkin: String, CaseIterable, Identifiable, Codable, Sendable {
    case dawn
    case veil
    case rupture

    var id: String { rawValue }

    static let `default`: LiraSkin = .dawn
    static let storageKey = "waykin.lira.skin"

    var displayName: String {
        switch self {
        case .dawn: "Dawn"
        case .veil: "Veil"
        case .rupture: "Rupture"
        }
    }

    var unlockLine: String {
        switch self {
        case .dawn: "Soft invitation. The path begins warm."
        case .veil: "Half-seen. Moves with intuition."
        case .rupture: "Fracture held together by bond."
        }
    }

    var emotionalRole: String {
        switch self {
        case .dawn: "Discovery · invitation"
        case .veil: "Mystery · liminality"
        case .rupture: "Pressure · transformation"
        }
    }

    /// Base body fill (guide / neutral poses). Pose may override temperature.
    func bodyBase(theme: WKTheme) -> Color {
        switch self {
        case .dawn:
            return Color(red: 0.91, green: 0.85, blue: 0.77) // #E8D9C4-ish cream
        case .veil:
            return Color(red: 0.16, green: 0.18, blue: 0.22) // #2A2E38
        case .rupture:
            return Color(red: 0.29, green: 0.27, blue: 0.35) // #4A4558
        }
    }

    func bodySecondary(theme: WKTheme) -> Color {
        switch self {
        case .dawn:
            return Color(red: 0.79, green: 0.72, blue: 0.60)
        case .veil:
            return Color(red: 0.23, green: 0.25, blue: 0.31) // mask
        case .rupture:
            return Color(red: 0.36, green: 0.31, blue: 0.48) // plate violet
        }
    }

    func fringe(theme: WKTheme) -> Color {
        switch self {
        case .dawn: return theme.guide
        case .veil: return theme.hunterFilament
        case .rupture: return Color(red: 0.54, green: 0.59, blue: 0.66) // fracture
        }
    }

    func hunterCast(theme: WKTheme) -> Color {
        switch self {
        case .dawn: return theme.hunter
        case .veil: return Color(red: 0.42, green: 0.35, blue: 0.54)
        case .rupture: return theme.hunter
        }
    }

    func bondCore(theme: WKTheme) -> Color {
        switch self {
        case .dawn: return theme.bond
        case .veil: return Color(red: 0.79, green: 0.54, blue: 0.48) // rose-gold soft
        case .rupture: return theme.bond
        }
    }

    /// Pose-aware body using skin base + pose stress.
    func bodyFill(pose: LiraSessionPose, theme: WKTheme) -> Color {
        let base = bodyBase(theme: theme)
        switch pose {
        case .hunter:
            return hunterCast(theme: theme).opacity(self == .dawn ? 0.92 : 0.95)
        case .rival:
            return self == .veil
                ? bodySecondary(theme: theme)
                : Color(red: 0.88, green: 0.78, blue: 0.68).opacity(self == .dawn ? 1 : 0.85)
        case .sanctuary:
            return self == .dawn
                ? theme.sanctuary.opacity(0.9)
                : base.opacity(0.95)
        case .bond:
            return self == .veil ? bodySecondary(theme: theme) : base
        case .dormant:
            return base.opacity(0.85)
        case .manifesting:
            return base.opacity(0.8)
        case .guide:
            return base
        }
    }

    func filamentFill(pose: LiraSessionPose, theme: WKTheme) -> Color {
        switch pose {
        case .hunter:
            return self == .veil ? Color(red: 0.42, green: 0.35, blue: 0.54) : theme.hunterFilament
        case .rival:
            return theme.rival.opacity(0.85)
        case .bond:
            return bondCore(theme: theme).opacity(0.8)
        case .sanctuary:
            return theme.sanctuaryText.opacity(0.85)
        default:
            return fringe(theme: theme)
        }
    }
}

// MARK: - Environment

private struct LiraSkinKey: EnvironmentKey {
    static let defaultValue: LiraSkin = .dawn
}

extension EnvironmentValues {
    var liraSkin: LiraSkin {
        get { self[LiraSkinKey.self] }
        set { self[LiraSkinKey.self] = newValue }
    }
}

extension View {
    func liraSkin(_ skin: LiraSkin) -> some View {
        environment(\.liraSkin, skin)
    }
}
