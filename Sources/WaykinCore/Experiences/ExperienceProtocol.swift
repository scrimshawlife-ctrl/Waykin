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
    public let bondLevel: Int
    public let eventSeed: UInt64

    public init(timeOfDay: String, activity: ActivityType, bondLevel: Int = 0, eventSeed: UInt64 = 42) {
        self.timeOfDay = timeOfDay
        self.activity = activity
        self.bondLevel = bondLevel
        self.eventSeed = eventSeed
    }
}

public struct ExperienceUpdate: Codable {
    public var state: ExperienceSessionState
    public var companionCommands: [CompanionCommand]
    public var audioCues: [String]
    public var semanticAudioCues: [AudioCue]
    public var narrativeEvents: [String]
    public var rewardEvents: [String]

    public init(
        state: ExperienceSessionState,
        companionCommands: [CompanionCommand],
        audioCues: [String],
        semanticAudioCues: [AudioCue] = [],
        narrativeEvents: [String],
        rewardEvents: [String]
    ) {
        self.state = state
        self.companionCommands = companionCommands
        self.audioCues = audioCues
        self.semanticAudioCues = semanticAudioCues
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
