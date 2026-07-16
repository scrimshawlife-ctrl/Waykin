import Foundation

public enum ActivityType: String, Codable, CaseIterable, Sendable {
    case walk, run, cycle, hike, climb
}

public enum MovementState: String, Codable, Sendable {
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

// MARK: - Solo MVP World State
public struct WorldState: Codable, Equatable, Sendable {
    public var timeContext: TimeContext
    public var movementState: MovementState
    public var currentSpeedMetersPerSecond: Double
    public var sessionDistanceMeters: Double
    public var activeTime: TimeInterval
    public var bondLevel: Int
    public var familiarity: Double
    public var energy: Double
    public var pressure: Double
    public var lastEventAt: Date?

    public init(
        timeContext: TimeContext,
        movementState: MovementState,
        currentSpeedMetersPerSecond: Double,
        sessionDistanceMeters: Double,
        activeTime: TimeInterval,
        bondLevel: Int,
        familiarity: Double,
        energy: Double,
        pressure: Double,
        lastEventAt: Date? = nil
    ) {
        self.timeContext = timeContext
        self.movementState = movementState
        self.currentSpeedMetersPerSecond = currentSpeedMetersPerSecond.finiteOrZero
        self.sessionDistanceMeters = max(0, sessionDistanceMeters.finiteOrZero)
        self.activeTime = max(0, activeTime.finiteOrZero)
        self.bondLevel = max(0, bondLevel)
        self.familiarity = familiarity.clamped01
        self.energy = energy.clamped01
        self.pressure = pressure.clamped01
        self.lastEventAt = lastEventAt
    }

    public static func derive(
        from session: MovementSession,
        timeContext: TimeContext,
        bondLevel: Int,
        lastEventAt: Date? = nil
    ) -> WorldState {
        let walkingSpeed = max(0, session.currentSpeedMetersPerSecond.finiteOrZero)
        let movementEnergy = min(1, walkingSpeed / 2.2)
        let durationEnergy = min(0.25, session.activeTime / 1200)
        let familiarity = min(1, session.distanceMeters / 2000)
        let idlePressure = session.movementState == .paused ? 0.18 : 0
        let distancePressure = min(0.55, session.distanceMeters / 3000)
        let fatiguePressure = session.activeTime > 900 ? 0.12 : 0

        return WorldState(
            timeContext: timeContext,
            movementState: session.movementState,
            currentSpeedMetersPerSecond: walkingSpeed,
            sessionDistanceMeters: session.distanceMeters,
            activeTime: session.activeTime,
            bondLevel: bondLevel,
            familiarity: familiarity,
            energy: min(1, movementEnergy + durationEnergy),
            pressure: min(1, idlePressure + distancePressure + fatiguePressure),
            lastEventAt: lastEventAt
        )
    }
}

public enum WorldEventKind: String, Codable, CaseIterable, Sendable {
    case companionDrawsNear
    case companionMovesAhead
    case companionObserves
    case distantPresence
    case pursuitBegins
    case pursuitIntensifies
    case pursuitFades
    case familiarPlaceStirs
    case quietInterval
    case bondMoment
}

public struct WorldEvent: Codable, Equatable, Sendable {
    public let kind: WorldEventKind
    public let occurredAt: Date
    public let intensity: Double
    public let debugLabel: String

    public init(kind: WorldEventKind, occurredAt: Date, intensity: Double, debugLabel: String) {
        self.kind = kind
        self.occurredAt = occurredAt
        self.intensity = intensity.clamped01
        self.debugLabel = debugLabel
    }
}

public enum PursuitState: String, Codable, Equatable, Sendable {
    case inactive, noticed, approaching, close, fading
}

public enum AudioCueKind: String, Codable, CaseIterable, Sendable {
    case companionNear
    case companionAhead
    case distantFootsteps
    case pursuitPressure
    case pursuitRelease
    case bondMotif
    case quietShift
}

public enum AudioSpatialBias: String, Codable, Equatable, Sendable {
    case left, center, right, behind
}

public struct AudioCue: Codable, Equatable, Sendable {
    public let kind: AudioCueKind
    public let intensity: Double
    public let spatialBias: AudioSpatialBias?
    public let priority: Int
    public let cooldownGroup: String
    public let shouldFade: Bool
    public let debugLabel: String

    public init(
        kind: AudioCueKind,
        intensity: Double,
        spatialBias: AudioSpatialBias? = nil,
        priority: Int,
        cooldownGroup: String,
        shouldFade: Bool,
        debugLabel: String
    ) {
        self.kind = kind
        self.intensity = intensity.clamped01
        self.spatialBias = spatialBias
        self.priority = max(0, priority)
        self.cooldownGroup = cooldownGroup
        self.shouldFade = shouldFade
        self.debugLabel = debugLabel
    }
}

public enum AudioAssetAvailability: Equatable, Sendable {
    case available(String)
    case missing
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

// MARK: - Typed Experience State
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
    public var worldState: WorldState?
    public var pursuitState: PursuitState
    public var lastEvent: WorldEvent?
    public var activeAudioCues: [AudioCue]

    public init(
        accumulatedBondProgress: Double,
        movementSeconds: TimeInterval,
        milestoneIndex: Int,
        tone: String,
        worldState: WorldState? = nil,
        pursuitState: PursuitState = .inactive,
        lastEvent: WorldEvent? = nil,
        activeAudioCues: [AudioCue] = []
    ) {
        self.accumulatedBondProgress = accumulatedBondProgress
        self.movementSeconds = movementSeconds
        self.milestoneIndex = milestoneIndex
        self.tone = tone
        self.worldState = worldState
        self.pursuitState = pursuitState
        self.lastEvent = lastEvent
        self.activeAudioCues = activeAudioCues
    }
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

public struct SessionMemory: Codable, Identifiable, Equatable {
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

// MARK: - Time Context & Variants (formalized)
public enum TimeContext: String, Codable, CaseIterable, Sendable {
    case dawn, morning, midday, goldenHour, twilight, night, deepNight
}

public enum ExperienceVariantID: String, Codable, CaseIterable {
    // Companion Walk
    case daylightExplorer, twilightLantern, nighttimeGuardian
    // Orc Pursuit
    case daylightRaiders, twilightTorchPursuit, nighttimeShadowPursuit
    // Future Self
    case daylightRival, twilightEcho, nighttimeGhost
}

public struct ExperienceVariantDefinition {
    public let id: ExperienceVariantID
    public let timeContexts: Set<TimeContext>
    public let difficultyModifier: Double
    public let visualProfile: String
    public let audioProfile: String
    public let narrativeTone: String
}

// MARK: - Demo Scenarios
public enum DemoScenarioID: String, Codable, CaseIterable {
    case calmDayWalk
    case nightOrcPursuit
    case futureSelfInterval
}

public struct DemoScenario {
    public let id: DemoScenarioID
    public let activity: ActivityType
    public let experienceID: String
    public let timeContext: TimeContext
    public let ticks: [(delta: TimeInterval, speed: Double)]
    public let expectedOutcome: String
}

// MARK: - Presentation
public struct Coordinate: Codable, Equatable {
    public let lat: Double
    public let lon: Double
}

public struct MapEntity: Identifiable, Equatable {
    public let id: UUID
    public let role: String
    public let coordinate: Coordinate
    public let relativeDistanceMeters: Double?
}

public struct MapPresentationState {
    public var userCoordinate: Coordinate?
    public var route: [Coordinate]
    public var entities: [MapEntity]
    public var statusText: String
}

// MARK: - Session Summary
public struct SessionSummary: Identifiable, Equatable {
    public let id: UUID
    public let sessionID: UUID
    public let activity: ActivityType
    public let experience: String
    public let variant: String
    public let duration: TimeInterval
    public let activeTime: TimeInterval
    public let distanceMeters: Double
    public let averageSpeed: Double
    public let outcome: String
    public let bondDelta: Int
    public let memory: SessionMemory
}
