import SwiftUI
import UIKit

/// Echo climate design tokens for App presentation (Phase 4 step 1).
///
/// Source: Waykin-Design `WK_TOKENS_v0.2` (direction lock: Echo brand + Lira product name).
/// Night is **not** an invert of day. Color alone must never communicate hunter/caution/pause.
///
/// Scope: App layer only. Does not own gameplay truth (`WaykinCore`).
enum WKTokens {
    static let version = "0.2"
    static let assetID = "WK_TOKENS_v0.2"
    static let companionProductName = "Lira"

    // MARK: - Day (cool mist)

    enum Day {
        static let background = Color(wkHex: 0xE4E8EC)
        static let backgroundWarm = Color(wkHex: 0xF2EDE6)
        static let surface = Color(wkHex: 0xF7F5F2)
        static let surfaceSecondary = Color(wkHex: 0xEBEEF1)
        static let textPrimary = Color(wkHex: 0x141820)
        static let textSecondary = Color(wkHex: 0x4A535E)
        static let textTertiary = Color(wkHex: 0x8A929C)
        static let bond = Color(wkHex: 0xD4A45A)
        static let bondText = Color(wkHex: 0x8A6428)
        static let guide = Color(wkHex: 0x3F8F8A)
        static let guideText = Color(wkHex: 0x2F6F6B)
        static let rival = Color(wkHex: 0xD17A4A)
        static let hunter = Color(wkHex: 0x5C4E7A)
        static let hunterFilament = Color(wkHex: 0x7B8C9E)
        static let sanctuary = Color(wkHex: 0xA8C4B5)
        static let sanctuaryText = Color(wkHex: 0x5F7F72)
        static let caution = Color(wkHex: 0xE0B040)
        static let pause = Color(wkHex: 0x5C6570)
        static let safetyPause = Color(wkHex: 0x5F7F72)
        static let focus = Color(wkHex: 0x3F8F8A)
        static let disabledOpacity = 0.35
    }

    // MARK: - Night (indigo-earth)

    enum Night {
        static let background = Color(wkHex: 0x12151C)
        static let backgroundWarm = Color(wkHex: 0x1A1614)
        static let surface = Color(wkHex: 0x1E2430)
        static let surfaceSecondary = Color(wkHex: 0x181C26)
        static let textPrimary = Color(wkHex: 0xE6EAF0)
        static let textSecondary = Color(wkHex: 0x9AA3B0)
        static let textTertiary = Color(wkHex: 0x7A8494)
        static let bond = Color(wkHex: 0xB8894A)
        static let bondText = Color(wkHex: 0xB8894A)
        static let guide = Color(wkHex: 0x4A9E98)
        static let guideText = Color(wkHex: 0x4A9E98)
        static let rival = Color(wkHex: 0xC46B3A)
        static let hunter = Color(wkHex: 0x6A5A8A)
        static let hunterFilament = Color(wkHex: 0x8A97A8)
        static let sanctuary = Color(wkHex: 0x5F7F72)
        static let sanctuaryText = Color(wkHex: 0xA8C4B5)
        static let caution = Color(wkHex: 0xE0B040)
        static let pause = Color(wkHex: 0x9AA3B0)
        static let safetyPause = Color(wkHex: 0x6F8F82)
        static let focus = Color(wkHex: 0x4A9E98)
        static let disabledOpacity = 0.32
    }

    // MARK: - Spacing / radius (pt) — CANDIDATE_v0.2

    enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let screenMarginX: CGFloat = 24
        static let minTouch: CGFloat = 48
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let capsule: CGFloat = 999
        static let iconContainer: CGFloat = 12
    }

    // MARK: - Type scale
    //
    // Display/title use bundled WaykinDisplay (brand pairing).
    // Body/caption/numeric stay system so Dynamic Type + outdoor glance stay legible.

    enum TypeScale {
        /// Session state display — design 36pt; floor ~28pt outdoor glance.
        static let displayMin: CGFloat = 28
        /// Brand display face for large titles / ceremonial screens.
        static let display: Font = WaykinTypography.display(size: 36, relativeTo: .largeTitle)
        /// Brand display face for screen titles (Home, Session Select, Summary).
        static let title: Font = WaykinTypography.display(size: 24, relativeTo: .title2)
        /// Readable body — system, Dynamic Type.
        static let body: Font = .system(size: 16, weight: .regular, design: .default)
        static let caption: Font = .system(size: 12, weight: .medium, design: .default)
        static let numeric: Font = .system(size: 20, weight: .medium, design: .default).monospacedDigit()
        /// Outdoor glance state word when display face is too soft at distance.
        static let sessionState: Font = .system(size: displayMin, weight: .semibold, design: .default)
    }

    // MARK: - Lira material palette (named tokens — no mid-render RGB improvisation)

    /// Cosmetic Lira fills shared by session canvas, glyphs, and procedural AR factory.
    enum LiraMaterial {
        static let dawnBody = Color(wkHex: 0xE8D9C4)
        static let dawnBodySecondary = Color(wkHex: 0xC9B899)
        static let dawnRivalWarm = Color(wkHex: 0xE0C7AD)
        static let veilBody = Color(wkHex: 0x2A2E38)
        static let veilBodySecondary = Color(wkHex: 0x3A404F)
        static let veilBond = Color(wkHex: 0xC98A7A)
        static let veilCast = Color(wkHex: 0x6B598A)
        static let ruptureBody = Color(wkHex: 0x4A4558)
        static let ruptureBodySecondary = Color(wkHex: 0x5C4F7A)
        static let ruptureFringe = Color(wkHex: 0x8A97A8)

        enum Hex {
            static let dawnBody = "E8D9C4"
            static let dawnBodySecondary = "C9B899"
            static let dawnRivalWarm = "E0C7AD"
            static let veilBody = "2A2E38"
            static let veilBodySecondary = "3A404F"
            static let veilBond = "C98A7A"
            static let veilCast = "6B598A"
            static let ruptureBody = "4A4558"
            static let ruptureBodySecondary = "5C4F7A"
            static let ruptureFringe = "8A97A8"
            static let guide = "3F8F8A"
            static let bond = "D4A45A"
            static let hunter = "5C4E7A"
            static let hunterFilament = "7B8C9E"
            static let rival = "D17A4A"
            static let caution = "E0B040"
            static let sanctuary = "A8C4B5"
            static let paperLight = "F7F5F2"
        }
    }

    // MARK: - Motion (seconds)

    enum Motion {
        static let fast: TimeInterval = 0.12
        static let standard: TimeInterval = 0.22
        static let slow: TimeInterval = 0.36
        static let manifestation: TimeInterval = 0.70
        static let sanctuary: TimeInterval = 0.80
        static let bond: TimeInterval = 0.50
        static let reducedCrossfadeMax: TimeInterval = 0.12
    }

    // MARK: - Semantic hex (tests / documentation)

    enum Hex {
        static let dayBackground = "E4E8EC"
        static let nightBackground = "12151C"
        static let dayGuide = "3F8F8A"
        static let dayBond = "D4A45A"
        static let dayHunter = "5C4E7A"
        static let dayTextPrimary = "141820"
        static let nightTextPrimary = "E6EAF0"
        static let daySafetyPause = "5F7F72"
        static let nightSafetyPause = "6F8F82"
    }
}

/// Resolved theme for the current appearance.
struct WKTheme: Equatable {
    let colorScheme: ColorScheme

    var isNight: Bool { colorScheme == .dark }

    var background: Color { isNight ? WKTokens.Night.background : WKTokens.Day.background }
    var backgroundWarm: Color { isNight ? WKTokens.Night.backgroundWarm : WKTokens.Day.backgroundWarm }
    var surface: Color { isNight ? WKTokens.Night.surface : WKTokens.Day.surface }
    var textPrimary: Color { isNight ? WKTokens.Night.textPrimary : WKTokens.Day.textPrimary }
    var textSecondary: Color { isNight ? WKTokens.Night.textSecondary : WKTokens.Day.textSecondary }
    var textTertiary: Color { isNight ? WKTokens.Night.textTertiary : WKTokens.Day.textTertiary }
    var bond: Color { isNight ? WKTokens.Night.bond : WKTokens.Day.bond }
    var bondText: Color { isNight ? WKTokens.Night.bondText : WKTokens.Day.bondText }
    var guide: Color { isNight ? WKTokens.Night.guide : WKTokens.Day.guide }
    var guideText: Color { isNight ? WKTokens.Night.guideText : WKTokens.Day.guideText }
    var rival: Color { isNight ? WKTokens.Night.rival : WKTokens.Day.rival }
    var hunter: Color { isNight ? WKTokens.Night.hunter : WKTokens.Day.hunter }
    var hunterFilament: Color { isNight ? WKTokens.Night.hunterFilament : WKTokens.Day.hunterFilament }
    var sanctuary: Color { isNight ? WKTokens.Night.sanctuary : WKTokens.Day.sanctuary }
    var sanctuaryText: Color { isNight ? WKTokens.Night.sanctuaryText : WKTokens.Day.sanctuaryText }
    var caution: Color { isNight ? WKTokens.Night.caution : WKTokens.Day.caution }
    var pause: Color { isNight ? WKTokens.Night.pause : WKTokens.Day.pause }
    var safetyPause: Color { isNight ? WKTokens.Night.safetyPause : WKTokens.Day.safetyPause }
    var focus: Color { isNight ? WKTokens.Night.focus : WKTokens.Day.focus }
    var surfaceSecondary: Color {
        isNight ? WKTokens.Night.surfaceSecondary : WKTokens.Day.surfaceSecondary
    }
    var disabledOpacity: Double {
        isNight ? WKTokens.Night.disabledOpacity : WKTokens.Day.disabledOpacity
    }

    /// Active-session field: mist/indigo foundation with hunter pressure wash (never color-alone for meaning).
    /// Blends named tokens — no free RGB improvisation.
    func sessionBackground(pressure: Double) -> Color {
        let p = min(1, max(0, pressure))
        let base = background
        let wash = hunter.opacity(0.08 + p * 0.28)
        return base.mix(with: wash, amount: 0.35 + p * 0.45)
    }

    static func resolve(_ colorScheme: ColorScheme) -> WKTheme {
        WKTheme(colorScheme: colorScheme)
    }
}

// MARK: - Color helpers

extension Color {
    /// sRGB hex initializer for design tokens (`0xRRGGBB`).
    init(wkHex: UInt32, opacity: Double = 1) {
        let r = Double((wkHex >> 16) & 0xFF) / 255
        let g = Double((wkHex >> 8) & 0xFF) / 255
        let b = Double(wkHex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// Presentation blend of two solid colors (amount clamped 0…1).
    func mix(with other: Color, amount: Double) -> Color {
        let t = min(1, max(0, amount))
        #if canImport(UIKit)
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            .sRGB,
            red: Double(ar + (br - ar) * t),
            green: Double(ag + (bg - ag) * t),
            blue: Double(ab + (bb - ab) * t),
            opacity: Double(aa + (ba - aa) * t)
        )
        #else
        return t < 0.5 ? self : other
        #endif
    }

    /// UIKit bridge for RealityKit materials / indicators.
    var wkUIColor: UIColor { UIColor(self) }
}

extension UIColor {
    /// sRGB hex for AR / UIKit paths that cannot take SwiftUI `Color`.
    convenience init(wkHex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((wkHex >> 16) & 0xFF) / 255
        let g = CGFloat((wkHex >> 8) & 0xFF) / 255
        let b = CGFloat(wkHex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - Environment

private struct WKThemeKey: EnvironmentKey {
    static let defaultValue = WKTheme(colorScheme: .light)
}

extension EnvironmentValues {
    var wkTheme: WKTheme {
        get { self[WKThemeKey.self] }
        set { self[WKThemeKey.self] = newValue }
    }
}

/// Injects Echo `WKTheme` from the system color scheme.
struct WKThemeInjector: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.wkTheme, WKTheme.resolve(colorScheme))
    }
}

extension View {
    func wkThemed() -> some View {
        modifier(WKThemeInjector())
    }
}
