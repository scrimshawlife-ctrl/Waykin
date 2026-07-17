import Foundation

/// What the companion's body should be doing right now. The AR layer maps
/// these to animations; the simulator prints them.
public enum CompanionBehavior: String, Codable, Equatable {
    case idle, walk, run, follow, celebrate, alert
}

public enum AudioCue: String, Codable, Equatable {
    case ambient, heartbeatSlow, heartbeatFast, chime, victory, ghostWhoosh
}

/// Everything an experience can ask the presentation layer to do.
/// Experiences never touch UI, AR, or audio APIs directly.
public enum ExperienceEvent: Equatable {
    case dialogue(String)
    case companionBehavior(CompanionBehavior)
    case audio(AudioCue)
    /// 0.0 (safe) … 1.0 (caught). Drives Orc Pursuit UI tension.
    case threatLevel(Double)
    /// Meters the Future Self ghost is ahead (negative = you passed it).
    case ghostDistance(Double)
    case milestone(String)
}

public enum Difficulty: String, Codable, CaseIterable {
    case relaxed, moderate, challenging
}

/// Static context available to an experience for the whole session.
public struct ExperienceContext {
    public var companion: Companion
    public var locationName: String
    public var timeOfDay: TimeOfDay
    public var weather: Weather

    public init(companion: Companion, locationName: String,
                timeOfDay: TimeOfDay = .afternoon, weather: Weather = .clear) {
        self.companion = companion
        self.locationName = locationName
        self.timeOfDay = timeOfDay
        self.weather = weather
    }
}

public enum TimeOfDay: String, Codable, CaseIterable {
    case morning, afternoon, evening, night

    public static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

public enum Weather: String, Codable, CaseIterable {
    case clear, cloudy, rain, snow
}

/// Result of a finished experience — feeds the memory generator and bond system.
public struct ExperienceOutcome: Equatable {
    public var succeeded: Bool
    public var bondDelta: Int
    /// Short phrase the memory generator weaves into the session memory,
    /// e.g. "outran the warband" or "caught your future self".
    public var memorySeed: String
    public var summaryLine: String

    public init(succeeded: Bool, bondDelta: Int, memorySeed: String, summaryLine: String) {
        self.succeeded = succeeded
        self.bondDelta = bondDelta
        self.memorySeed = memorySeed
        self.summaryLine = summaryLine
    }
}

/// The plug-in contract. An experience is a pure state machine over
/// MovementUpdates. Adding a new experience means implementing this protocol
/// and registering it — no changes to the movement engine or the runner.
public protocol Experience: AnyObject {
    var id: String { get }
    var name: String { get }
    var summary: String { get }
    var difficulty: Difficulty { get }

    func begin(context: ExperienceContext) -> [ExperienceEvent]
    func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent]
    func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome
}
