import Foundation

public enum CompanionBehaviorState: String, Codable, Sendable {
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
            self.relativeDistance = d.isFinite && d > 0 ? d : relativeDistance
        case .showMessage, .setThreatLevel:
            break
        }
    }

    public mutating func apply(event: WorldEvent?) {
        guard let event else { return }
        let resolved = CompanionPresentationMatrix.resolve(eventKind: event.kind)
        state = resolved.behavior
        relativeDistance = resolved.relativeDistance
    }
}
