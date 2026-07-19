import Foundation

@MainActor
enum CompanionPresentationState: String, CaseIterable, Sendable {
    case idle
    case follow
    case investigate
    case alert
    case celebrate

    static let deterministicOrder: [Self] = [
        .idle,
        .follow,
        .investigate,
        .alert,
        .celebrate,
    ]
}

@MainActor
struct CompanionStateTransition: Equatable, Sendable {
    enum Outcome: String, Equatable, Sendable {
        case applied
        case normalizedUnknownToIdle
        case celebrationInProgress
        case celebrationCompleted
        case invalidElapsedNormalizedToIdle
        case unchanged
    }

    let previousState: CompanionPresentationState
    let requestedState: CompanionPresentationState
    let resolvedState: CompanionPresentationState
    let outcome: Outcome
}

@MainActor
struct CompanionStateReducer {
    static let celebrationDuration: TimeInterval = 1.5

    static func state(for behavior: String) -> CompanionPresentationState {
        normalizedState(for: behavior).state
    }

    static func transition(
        current: CompanionPresentationState,
        behavior: String,
        elapsed: TimeInterval
    ) -> CompanionStateTransition {
        let normalization = normalizedState(for: behavior)
        let transition = transition(
            current: current,
            requested: normalization.state,
            elapsed: elapsed
        )

        if normalization.wasUnknown {
            return CompanionStateTransition(
                previousState: current,
                requestedState: .idle,
                resolvedState: transition.resolvedState,
                outcome: .normalizedUnknownToIdle
            )
        }
        return transition
    }

    static func transition(
        current: CompanionPresentationState,
        requested: CompanionPresentationState,
        elapsed: TimeInterval
    ) -> CompanionStateTransition {
        guard elapsed.isFinite, elapsed >= 0 else {
            return CompanionStateTransition(
                previousState: current,
                requestedState: requested,
                resolvedState: .idle,
                outcome: .invalidElapsedNormalizedToIdle
            )
        }

        if current == .celebrate, requested == .celebrate {
            let completed = elapsed >= celebrationDuration
            return CompanionStateTransition(
                previousState: current,
                requestedState: requested,
                resolvedState: completed ? .idle : .celebrate,
                outcome: completed ? .celebrationCompleted : .celebrationInProgress
            )
        }

        if current == requested {
            return CompanionStateTransition(
                previousState: current,
                requestedState: requested,
                resolvedState: current,
                outcome: .unchanged
            )
        }

        return CompanionStateTransition(
            previousState: current,
            requestedState: requested,
            resolvedState: requested,
            outcome: .applied
        )
    }

    private static func normalizedState(
        for behavior: String
    ) -> (state: CompanionPresentationState, wasUnknown: Bool) {
        switch behavior.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "idle": (.idle, false)
        case "follow", "drawnear", "approach": (.follow, false)
        case "investigate", "observe", "curious": (.investigate, false)
        case "alert", "warn", "threat": (.alert, false)
        case "celebrate", "bondmoment", "success": (.celebrate, false)
        default: (.idle, true)
        }
    }

    static func resolvedState(
        current: CompanionPresentationState,
        requested: CompanionPresentationState,
        elapsed: TimeInterval
    ) -> CompanionPresentationState {
        transition(current: current, requested: requested, elapsed: elapsed).resolvedState
    }
}
