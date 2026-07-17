import Foundation

struct ARDiagnosticEvent: Codable, Equatable {
    enum Kind: String, Codable {
        case sessionStarted
        case trackingActive
        case placementAttempted
        case placementSucceeded
        case placementFailed
        case entityCreated
        case entityReplaced
        case entityRemoved
        case stateChanged
        case sessionCleared
        case error
    }

    let sequence: Int
    let kind: Kind
    let detail: String
}

struct ARValidationReceipt: Codable, Equatable {
    let eventCount: Int
    let placementSuccessCount: Int
    let placementFailureCount: Int
    let replacementCount: Int
    let stateTransitions: [String]
    let cleanupSucceeded: Bool
}

@MainActor
final class ARDiagnosticRecorder {
    private(set) var events: [ARDiagnosticEvent] = []

    func record(_ kind: ARDiagnosticEvent.Kind, detail: String = "") {
        events.append(ARDiagnosticEvent(sequence: events.count, kind: kind, detail: detail))
    }

    func receipt(registryCount: Int) -> ARValidationReceipt {
        ARValidationReceipt(
            eventCount: events.count,
            placementSuccessCount: events.filter { $0.kind == .placementSucceeded }.count,
            placementFailureCount: events.filter { $0.kind == .placementFailed }.count,
            replacementCount: events.filter { $0.kind == .entityReplaced }.count,
            stateTransitions: events.filter { $0.kind == .stateChanged }.map(\.detail),
            cleanupSucceeded: registryCount == 0 && events.contains { $0.kind == .sessionCleared }
        )
    }

    func reset() {
        events.removeAll(keepingCapacity: true)
    }
}
