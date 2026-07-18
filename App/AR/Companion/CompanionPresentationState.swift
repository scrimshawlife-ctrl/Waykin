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
        case "celebrate", "bondmoment", "success": .celebrate
        default: .idle
        }
    }

    static func resolvedState(
        current: CompanionPresentationState,
        requested: CompanionPresentationState,
        elapsed: TimeInterval
    ) -> CompanionPresentationState {
        guard elapsed.isFinite, elapsed >= 0 else { return .idle }
        if current == .celebrate, elapsed >= 1.5 { return .idle }
        return requested
    }
}
