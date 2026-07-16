import Foundation

public enum ActivityType: String, Codable, CaseIterable {
    case walk
    case run
    case cycle
    case hike
    case climb
}

public enum MovementState: String, Codable {
    case idle, moving, paused, stopped
}

public struct RoutePoint: Codable, Equatable {
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let speed: Double

    public init(timestamp: Date, latitude: Double, longitude: Double, altitude: Double?, speed: Double) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
    }
}

public struct MovementSnapshot: Codable {
    public let timestamp: Date
    public let speed: Double
    public let distanceDelta: Double
    public let isMoving: Bool

    public init(timestamp: Date, speed: Double, distanceDelta: Double, isMoving: Bool) {
        self.timestamp = timestamp
        self.speed = speed
        self.distanceDelta = distanceDelta
        self.isMoving = isMoving
    }
}

public struct MovementSession: Codable, Identifiable {
    public let id: UUID
    public let activityType: ActivityType
    public let experienceID: String
    public let startedAt: Date
    public var endedAt: Date?
    public var elapsedTime: TimeInterval
    public var activeTime: TimeInterval
    public var distanceMeters: Double
    public var currentSpeedMetersPerSecond: Double
    public var averageSpeedMetersPerSecond: Double
    public var routePoints: [RoutePoint]
    public var movementState: MovementState
    public var experienceState: ExperienceSessionState

    public init(id: UUID = UUID(), activityType: ActivityType, experienceID: String, startedAt: Date = Date()) {
        self.id = id
        self.activityType = activityType
        self.experienceID = experienceID
        self.startedAt = startedAt
        self.endedAt = nil
        self.elapsedTime = 0
        self.activeTime = 0
        self.distanceMeters = 0
        self.currentSpeedMetersPerSecond = 0
        self.averageSpeedMetersPerSecond = 0
        self.routePoints = []
        self.movementState = .idle
        self.experienceState = ExperienceSessionState()
    }
}

// MARK: - Typed Experience State (replaces stringly-typed data)
public enum ExperienceRuntimeState: Codable, Equatable {
    case companionWalk(CompanionWalkState)
    case orcPursuit(OrcPursuitState)
    case futureSelf(FutureSelfState)
}

public struct CompanionWalkState: Codable, Equatable {
    public var accumulatedBondProgress: Double
    public var movementSeconds: TimeInterval
    public var milestoneIndex: Int
    public var tone: String
}

public struct OrcPursuitState: Codable, Equatable {
    public var pursuerDistanceMeters: Double
    public var threatLevel: Double
    public var escapeMomentum: Double
    public var pressureTier: Int
    public var nearCaptureCount: Int
    public var elapsedSeconds: TimeInterval
}

public struct FutureSelfState: Codable, Equatable {
    public var targetSpeedMetersPerSecond: Double
    public var leadMeters: Double
    public var paceStability: Double
    public var catchWindowActive: Bool
    public var catchCount: Int
    public var effortTrend: Double
}

public struct ExperienceSessionState: Codable {
    public var runtimeState: ExperienceRuntimeState?
    public var narrative: [String] = []

    public init(runtimeState: ExperienceRuntimeState? = nil, narrative: [String] = []) {
        self.runtimeState = runtimeState
        self.narrative = narrative
    }
}

public struct ExperienceResult: Codable {
    public let outcome: String
    public let bondDelta: Int
    public let memoryText: String

    public init(outcome: String, bondDelta: Int, memoryText: String) {
        self.outcome = outcome
        self.bondDelta = bondDelta
        self.memoryText = memoryText
    }
}

public struct Companion: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var archetype: String
    public var bondLevel: Int
    public var lastSessionID: UUID?
    public var memories: [SessionMemory]

    public init(id: UUID = UUID(), name: String, archetype: String, bondLevel: Int, lastSessionID: UUID?, memories: [SessionMemory]) {
        self.id = id
        self.name = name
        self.archetype = archetype
        self.bondLevel = bondLevel
        self.lastSessionID = lastSessionID
        self.memories = memories
    }
}

public struct SessionMemory: Codable, Identifiable {
    public let id: UUID
    public let sessionID: UUID
    public let text: String
    public let timestamp: Date

    public init(id: UUID = UUID(), sessionID: UUID, text: String, timestamp: Date = Date()) {
        self.id = id
        self.sessionID = sessionID
        self.text = text
        self.timestamp = timestamp
    }
}

public struct ExperienceDefinition: Codable {
    public let id: String
    public let name: String
    public let description: String
    public let intensity: String
    public let timeAffinity: [String]

    public init(id: String, name: String, description: String, intensity: String, timeAffinity: [String]) {
        self.id = id
        self.name = name
        self.description = description
        self.intensity = intensity
        self.timeAffinity = timeAffinity
    }
}

public struct ExperienceRecommendation: Codable {
    public let experienceID: String
    public let variantID: String
    public let observedReasons: [String]
    public let inferredReasons: [String]
    public let unavailableSignals: [String]
    public var score: Double

    public init(experienceID: String, variantID: String, observedReasons: [String], inferredReasons: [String], unavailableSignals: [String], score: Double) {
        self.experienceID = experienceID
        self.variantID = variantID
        self.observedReasons = observedReasons
        self.inferredReasons = inferredReasons
        self.unavailableSignals = unavailableSignals
        self.score = score
    }
}

public enum AttentionState {
    case idle, lowAttentionMovement, highAttentionMovement, paused, postSession
}
