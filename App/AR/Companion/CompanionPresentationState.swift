import Foundation

@MainActor
enum CompanionPresentationState: String, CaseIterable, Equatable {
    case idle
    case follow
    case investigate
    case alert
    case celebrate
}

@MainActor
struct CompanionStateReducer {
    static func state(for behavior: String) -> CompanionPresentationState {
        switch behavior.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "follow", "following", "drawsnear", "draws_near":
            return .follow
        case "investigate", "investigating", "observes", "observe":
            return .investigate
        case "alert", "warning", "warn", "threat":
            return .alert
        case "celebrate", "celebrating", "bondmoment", "bond_moment":
            return .celebrate
        default:
            return .idle
        }
    }

    static func resolvedState(
        current: CompanionPresentationState,
        requested: CompanionPresentationState,
        elapsedSeconds: TimeInterval
    ) -> CompanionPresentationState {
        guard elapsedSeconds.isFinite, elapsedSeconds >= 0 else { return .idle }
        if current == .celebrate, elapsedSeconds >= 1.4 {
            return .idle
        }
        return requested
    }
}
