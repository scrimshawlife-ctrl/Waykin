import SwiftUI

/// Cosmetic skins for Lira — materials only, same rig/poses/anchors.
/// Dawn default; Veil / Rupture optional. No marketplace unlock economy.
/// Colors resolve only through `WKTokens.LiraMaterial` / `WKTheme` (no free RGB).
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
        case .dawn: WKTokens.LiraMaterial.dawnBody
        case .veil: WKTokens.LiraMaterial.veilBody
        case .rupture: WKTokens.LiraMaterial.ruptureBody
        }
    }

    func bodySecondary(theme: WKTheme) -> Color {
        switch self {
        case .dawn: WKTokens.LiraMaterial.dawnBodySecondary
        case .veil: WKTokens.LiraMaterial.veilBodySecondary
        case .rupture: WKTokens.LiraMaterial.ruptureBodySecondary
        }
    }

    func fringe(theme: WKTheme) -> Color {
        switch self {
        case .dawn: theme.guide
        case .veil: theme.hunterFilament
        case .rupture: WKTokens.LiraMaterial.ruptureFringe
        }
    }

    func hunterCast(theme: WKTheme) -> Color {
        switch self {
        case .dawn: theme.hunter
        case .veil: WKTokens.LiraMaterial.veilCast
        case .rupture: theme.hunter
        }
    }

    func bondCore(theme: WKTheme) -> Color {
        switch self {
        case .dawn: theme.bond
        case .veil: WKTokens.LiraMaterial.veilBond
        case .rupture: theme.bond
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
                : WKTokens.LiraMaterial.dawnRivalWarm.opacity(self == .dawn ? 1 : 0.85)
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
            return self == .veil ? WKTokens.LiraMaterial.veilCast : theme.hunterFilament
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
