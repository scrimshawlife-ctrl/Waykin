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
        case stateChanged
        case sessionCleared
        case runtimeError
    }

    let sequence: Int
    let kind: Kind
    let detail: String
}

struct ARValidationReceipt: Codable, Equatable, Sendable {
    let sessionStarted: Bool
    let placementSuccessCount: Int
    let placementFailureCount: Int
    let replacementCount: Int
    let companionStateTransitions: [String]
    let cleanupSucceeded: Bool
    let events: [ARDiagnosticEvent]
}

@MainActor
final class ARDiagnosticRecorder {
    private(set) var events: [ARDiagnosticEvent] = []

    func record(_ kind: ARDiagnosticEvent.Kind, detail: String = "") {
        events.append(.init(sequence: events.count, kind: kind, detail: detail))
    }

    func makeReceipt() -> ARValidationReceipt {
        ARValidationReceipt(
            sessionStarted: events.contains { $0.kind == .sessionStarted },
            placementSuccessCount: events.filter { $0.kind == .placementSucceeded }.count,
            placementFailureCount: events.filter { $0.kind == .placementFailed }.count,
            replacementCount: events.filter { $0.kind == .entityReplaced }.count,
            companionStateTransitions: events.filter { $0.kind == .stateChanged }.map(\.detail),
            cleanupSucceeded: events.last?.kind == .sessionCleared || events.last?.kind == .sessionStopped,
            events: events
        )
    }

    func reset() {
        events.removeAll(keepingCapacity: true)
    }
}
