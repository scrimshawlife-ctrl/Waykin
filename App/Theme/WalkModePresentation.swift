import SwiftUI
import WaykinCore

/// MVP walk **presentation** modes (CANDIDATE_v0.2 Session Selection).
/// Maps to existing companion walk / demo — does not invent Race/Hunt gameplay engines.
enum WalkMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case trail
    case race
    case hunt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trail: "Trail"
        case .race: "Race"
        case .hunt: "Hunt"
        }
    }

    /// One-line emotional copy (component library mode card).
    var emotionalLine: String {
        switch self {
        case .trail: "Walk with Lira. Quiet path, shared pace."
        case .race: "Match her energy. Stay close when she pulls ahead."
        case .hunt: "Controlled pressure. She keeps the path honest."
        }
    }

    /// Hunt requires protective footnote.
    var protectiveFootnote: String? {
        switch self {
        case .hunt:
            return "Pressure is intentional and bounded. Pause or end anytime — never a failure."
        case .trail, .race:
            return nil
        }
    }

    var icon: WKIcon {
        switch self {
        case .trail: .trail
        case .race: .race
        case .hunt: .hunt
        }
    }

    func accent(in theme: WKTheme) -> Color {
        switch self {
        case .trail: theme.guide
        case .race: theme.rival
        case .hunt: theme.hunter
        }
    }

    var prepHeadline: String {
        switch self {
        case .trail: "Ready for the path"
        case .race: "Ready to keep pace"
        case .hunt: "Ready for pressure"
        }
    }

    var prepBody: String {
        switch self {
        case .trail:
            return "Location powers the live walk. Audio leads; chrome stays sparse."
        case .race:
            return "Same live walk, sharper presence language. End anytime."
        case .hunt:
            return "Same live walk with pursuit-aware framing. Safety pause is always available."
        }
    }

    /// Demo scenario still only calmDayWalk — presentation label differs.
    var demoScenario: DemoScenarioID { .calmDayWalk }
}
