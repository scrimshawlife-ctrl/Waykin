import Foundation

struct ARDiagnosticEvent: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case sessionStarted
        case sessionStopped
        case trackingChanged
        case placementAttempted
        case placementSucceeded
        case placementFailed
        case entityCreated
        case entityReplaced
        case entityRemoved
        case companionStateChanged
        case sessionCleared
        case runtimeError
    }

    let sequence: Int
    let kind: Kind
    let detail: String
}

struct ARValidationReceipt: Codable, Equatable, Sendable {
    let sessionStarted: Bool
    let trackingNormalReached: Bool
    let companionPlaced: Bool
    let companionStateTransitions: [String]
    let replacementCount: Int
    let placementFailureCount: Int
    let cleanupSucceeded: Bool
    let events: [ARDiagnosticEvent]
}

@MainActor
final class ARDiagnosticRecorder {
    private(set) var events: [ARDiagnosticEvent] = []

    func record(_ kind: ARDiagnosticEvent.Kind, detail: String = "") {
        events.append(ARDiagnosticEvent(sequence: events.count, kind: kind, detail: detail))
    }

    func reset() {
        events.removeAll(keepingCapacity: true)
    }

    func receipt() -> ARValidationReceipt {
        ARValidationReceipt(
            sessionStarted: events.contains { $0.kind == .sessionStarted },
            trackingNormalReached: events.contains { $0.kind == .trackingChanged && $0.detail == "normal" },
            companionPlaced: events.contains { $0.kind == .entityCreated && $0.detail == "companion" },
            companionStateTransitions: events
                .filter { $0.kind == .companionStateChanged }
                .map(\.detail),
            replacementCount: events.filter { $0.kind == .entityReplaced }.count,
            placementFailureCount: events.filter { $0.kind == .placementFailed }.count,
            cleanupSucceeded: events.last?.kind == .sessionCleared,
            events: events
        )
    }
}
