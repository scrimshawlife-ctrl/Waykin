import Foundation

/// Ambient one-line presence phrases — the quiet narration shown when the
/// companion isn't speaking full dialogue. Voice and state mapping adapted
/// from the first Waykin implementation's CompanionPresenceView.
public enum PresenceNarrator {
    /// Current-moment phrase from the continuous channels.
    public static func phrase(companionName name: String,
                              behavior: CompanionBehavior,
                              threat: Double? = nil,
                              ghostGapMeters: Double? = nil,
                              isMoving: Bool = true) -> String {
        if let threat {
            switch threat {
            case 0.65...: return "The pressure is close."
            case 0.35..<0.65: return "Something is keeping pace."
            case 0.05..<0.35: return "The path has changed."
            default: break
            }
        }

        if let gap = ghostGapMeters {
            switch gap {
            case ..<0: return "\(name) shares the moment."
            case ..<15: return "The shimmer is almost in reach."
            default: return "A brighter you keeps ahead."
            }
        }

        switch behavior {
        case .idle: return isMoving ? "\(name) stays close." : "\(name) rests beside you."
        case .walk, .follow: return "\(name) stays close."
        case .run: return "\(name) races along."
        case .celebrate: return "\(name) shares the moment."
        case .alert: return "\(name) is watching the path."
        }
    }

    /// End-of-session closing line.
    public static func closingPhrase(companionName name: String,
                                     outcome: ExperienceOutcome) -> String {
        outcome.succeeded ? "\(name) stayed with you." : "The path remembers."
    }

    /// 0…1 visual tension for the presence indicator.
    public static func pressureIntensity(threat: Double?) -> Double {
        min(1, max(0, threat ?? 0))
    }
}
