import Foundation

public enum CompanionPresentationState: String, CaseIterable, Equatable, Sendable {
    case idle
    case follow
    case investigate
    case alert
    case celebrate
}

public struct CompanionPresentationTransition: Equatable, Sendable {
    public let state: CompanionPresentationState
    public let elapsedInState: TimeInterval

    public init(state: CompanionPresentationState, elapsedInState: TimeInterval = 0) {
        self.state = state
        self.elapsedInState = max(0, elapsedInState.isFinite ? elapsedInState : 0)
    }
}

public enum CompanionStateReducer {
    public static func state(for behavior: String) -> CompanionPresentationState {
        switch behavior.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "follow", "drawneear", "drawsnear", "approach":
            return .follow
        case "investigate", "observe", "observes", "curious":
            return .investigate
        case "alert", "warn", "guard":
            return .alert
        case "celebrate", "bond", "bondmoment":
            return .celebrate
        default:
            return .idle
        }
    }

    public static func reduce(
        current: CompanionPresentationTransition,
        behavior: String,
        deltaTime: TimeInterval,
        celebrationDuration: TimeInterval = 1.4
    ) -> CompanionPresentationTransition {
        let requested = state(for: behavior)
        let safeDelta = max(0, deltaTime.isFinite ? deltaTime : 0)
        if current.state == .celebrate,
           current.elapsedInState + safeDelta >= max(0.1, celebrationDuration),
           requested == .celebrate {
            return CompanionPresentationTransition(state: .idle)
        }
        if requested != current.state {
            return CompanionPresentationTransition(state: requested)
        }
        return CompanionPresentationTransition(
            state: current.state,
            elapsedInState: current.elapsedInState + safeDelta
        )
    }
}
