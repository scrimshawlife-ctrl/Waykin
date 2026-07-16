import Foundation

public protocol WaykinExperience {
    var definition: ExperienceDefinition { get }

    func start(context: ExperienceContext) -> ExperienceSessionState
    func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate
    func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult
}

public struct ExperienceContext: Codable {
    public let timeOfDay: String
    public let activity: ActivityType

    public init(timeOfDay: String, activity: ActivityType) {
        self.timeOfDay = timeOfDay
        self.activity = activity
    }
}

public struct ExperienceUpdate: Codable {
    public var state: ExperienceSessionState
    public var companionCommands: [CompanionCommand]
    public var audioCues: [String]
    public var narrativeEvents: [String]
    public var rewardEvents: [String]

    public init(state: ExperienceSessionState, companionCommands: [CompanionCommand], audioCues: [String], narrativeEvents: [String], rewardEvents: [String]) {
        self.state = state
        self.companionCommands = companionCommands
        self.audioCues = audioCues
        self.narrativeEvents = narrativeEvents
        self.rewardEvents = rewardEvents
    }
}

public enum CompanionCommand: Codable {
    case setBehavior(String)
    case setRelativeDistance(Double)
    case showMessage(String)
    case setThreatLevel(Double)
}
