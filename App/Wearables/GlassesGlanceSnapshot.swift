import Foundation

/// Privacy-safe glance payload for a 2D glasses HUD.
///
/// Built read-only from `CompanionPresencePresentation`. Never includes
/// coordinates, health samples, or new gameplay truth.
struct GlassesGlanceSnapshot: Equatable, Sendable {
    let companionName: String
    let presencePhrase: String
    let pathPressureStatus: String
    let elapsedText: String
    let distanceText: String
    let isPaused: Bool
    let isOpening: Bool
    /// Cue-adjacent only (sound active / quiet) — not a new audio bus.
    let audioActive: Bool

    /// Compact multi-line HUD body for mock / Meta 2D text surfaces.
    var hudLines: [String] {
        var lines = [
            presencePhrase,
            pathPressureStatus,
            "\(elapsedText) · \(distanceText)"
        ]
        if isPaused {
            lines.append("Paused")
        }
        if audioActive {
            lines.append("Sound active")
        }
        return lines
    }

    static func from(_ presentation: CompanionPresencePresentation) -> GlassesGlanceSnapshot {
        GlassesGlanceSnapshot(
            companionName: presentation.companionName,
            presencePhrase: presentation.phrase,
            pathPressureStatus: presentation.pressureLabel,
            elapsedText: presentation.elapsedText,
            distanceText: presentation.distanceText,
            isPaused: presentation.isPaused,
            isOpening: presentation.isOpening,
            audioActive: presentation.audioCueKind != nil
        )
    }
}

enum GlassesGlanceConnectionState: String, Equatable, Sendable {
    case disabled
    case idle
    case connecting
    case connected
    case unavailable
}
