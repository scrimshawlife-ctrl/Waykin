import Foundation

public enum CompanionBehaviorState: String, Codable {
    case idle, follow, lead, celebrate, observe, drawNear, rest
}

public struct CompanionRuntime {
    public var state: CompanionBehaviorState = .follow
    public var relativeDistance: Double = 2.5

    public init() {}

    public mutating func apply(command: CompanionCommand) {
        switch command {
        case .setBehavior(let b):
            self.state = CompanionBehaviorState(rawValue: b) ?? .follow
        case .setRelativeDistance(let d):
            self.relativeDistance = d
        case .showMessage, .setThreatLevel:
            break
        }
    }

    public mutating func apply(event: WorldEvent?) {
        guard let event else { return }

        switch event.kind {
        case .companionDrawsNear, .bondMoment:
            state = .drawNear
            relativeDistance = 1.2
        case .companionMovesAhead, .pursuitFades:
            state = .lead
            relativeDistance = 4.0
        case .companionObserves, .familiarPlaceStirs, .quietInterval, .distantPresence:
            state = .observe
            relativeDistance = 2.5
        case .pursuitBegins, .pursuitIntensifies:
            state = .follow
            relativeDistance = 1.8
        }
    }
}
