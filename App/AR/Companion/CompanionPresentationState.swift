import Foundation

@MainActor
enum CompanionPresentationState: String, CaseIterable, Sendable {
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
        case "follow", "drawnear", "approach": .follow
        case "investigate", "observe", "curious": .investigate
        case "alert", "warn", "threat": .alert
        case "celebrate", "bond", "success": .celebrate
        default: .idle
        }
    }

    static func resolvedState(
        current: CompanionPresentationState,
        requested: CompanionPresentationState,
        elapsedSeconds: TimeInterval
    ) -> CompanionPresentationState {
        guard requested == .celebrate else { return requested }
        return elapsedSeconds >= 1.6 ? .idle : .celebrate
    }
}
