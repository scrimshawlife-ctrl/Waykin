import Foundation

public enum CompanionBehaviorState: String, Codable {
    case idle, follow, lead, celebrate, observe, rest
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
}
