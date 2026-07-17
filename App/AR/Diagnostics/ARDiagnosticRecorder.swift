import Foundation

enum ARDiagnosticKind: String, Codable, Sendable {
    case sessionStarted
    case trackingNormal
    case placementAttempted
    case placementSucceeded
    case placementDeferred
    case entityCreated
    case entityReplaced
    case stateChanged
    case entityRemoved
    case sessionCleared
    case error
}

struct ARDiagnosticEvent: Codable, Equatable, Sendable {
    let sequence: Int
    let kind: ARDiagnosticKind
    let detail: String
}

@MainActor
final class ARDiagnosticRecorder {
    private(set) var events: [ARDiagnosticEvent] = []

    func record(_ kind: ARDiagnosticKind, detail: String = "") {
        events.append(ARDiagnosticEvent(sequence: events.count, kind: kind, detail: detail))
    }

    func clear() {
        events.removeAll(keepingCapacity: true)
    }

    var summary: ARValidationReceipt {
        ARValidationReceipt(
            sessionStarted: events.contains { $0.kind == .sessionStarted },
            trackingNormalReached: events.contains { $0.kind == .trackingNormal },
            companionPlaced: events.contains { $0.kind == .entityCreated && $0.detail == "companion" },
            replacementCount: events.filter { $0.kind == .entityReplaced }.count,
            placementFailureCount: events.filter { $0.kind == .placementDeferred }.count,
            cleanupSucceeded: events.last?.kind == .sessionCleared,
            stateTransitions: events.filter { $0.kind == .stateChanged }.map(\.detail)
        )
    }
}

struct ARValidationReceipt: Codable, Equatable, Sendable {
    let sessionStarted: Bool
    let trackingNormalReached: Bool
    let companionPlaced: Bool
    let replacementCount: Int
    let placementFailureCount: Int
    let cleanupSucceeded: Bool
    let stateTransitions: [String]
}
