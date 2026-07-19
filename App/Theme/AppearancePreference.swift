import SwiftUI

/// User appearance force for Echo day/night themes.
enum AppearancePreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case day
    case night

    var id: String { rawValue }
    static let storageKey = "waykin.appearance.preference"
    static let `default`: AppearancePreference = .system

    var displayName: String {
        switch self {
        case .system: "Auto"
        case .day: "Day"
        case .night: "Night"
        }
    }

    /// Maps to SwiftUI preferredColorScheme (nil = follow system).
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .day: .light
        case .night: .dark
        }
    }
}
