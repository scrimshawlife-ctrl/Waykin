import CoreGraphics
import WaykinCore

/// Session-mid production poses for Lira (Living Familiar / Echo).
/// Maps runtime presentation → art pose per LIRA_PRODUCTION_ART_PIPELINE.
enum LiraSessionPose: String, CaseIterable, Equatable, Sendable {
    case dormant
    case manifesting
    case guide
    case rival
    case hunter
    case sanctuary
    case bond

    /// Resolve pose from presence presentation (priority: opening → pursuit → event → behavior).
    static func resolve(from presentation: CompanionPresencePresentation) -> LiraSessionPose {
        if presentation.isOpening { return .manifesting }

        switch presentation.pursuitState {
        case .approaching, .close:
            return .hunter
        case .noticed:
            return presentation.behavior == .celebrate ? .bond : .rival
        case .fading:
            return .sanctuary
        case .inactive:
            break
        }

        if presentation.eventKind == .bondMoment { return .bond }
        if presentation.eventKind == .quietInterval { return .dormant }

        // Path integrity lean (presentation only; not a new gameplay loop).
        if presentation.pathRelation == .offPath || presentation.pathIntegrityPressure >= 0.7 {
            return .hunter
        }
        if presentation.pathRelation == .strained || presentation.pathIntegrityPressure >= 0.4 {
            return .rival
        }

        switch presentation.behavior {
        case .rest:
            return .sanctuary
        case .celebrate, .drawNear:
            return .bond
        case .lead:
            return .guide
        case .observe, .idle:
            return presentation.isPaused ? .dormant : .guide
        case .follow:
            return .guide
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .dormant: "Lira is quiet and compact"
        case .manifesting: "Lira is forming presence"
        case .guide: "Lira guides ahead"
        case .rival: "Lira matches cadence"
        case .hunter: "Lira pressure behind with echo"
        case .sanctuary: "Lira settles in sanctuary"
        case .bond: "Lira shares a bond moment"
        }
    }

    /// Whether hunter delayed-echo silhouette should draw.
    var showsEchoSilhouette: Bool { self == .hunter }

    /// Body vertical crouch amount (0 open → 1 low stalk).
    var crouch: CGFloat {
        switch self {
        case .hunter: 0.85
        case .rival: 0.45
        case .dormant: 0.7
        case .sanctuary: 0.35
        case .manifesting: 0.2
        case .bond: 0.15
        case .guide: 0
        }
    }

    /// Filament extension (1 full stream).
    var filamentLength: CGFloat {
        switch self {
        case .hunter: 1.15
        case .guide: 1.0
        case .rival: 0.9
        case .bond: 0.75
        case .sanctuary: 0.55
        case .dormant: 0.4
        case .manifesting: 0.65
        }
    }
}
