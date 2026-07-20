import Foundation

public enum ActivityType: String, Codable, CaseIterable, Sendable {
    case walk, run, cycle, hike, climb
}

public enum MovementState: String, Codable, Equatable, Sendable {
    case idle, moving, paused, stopped
}

public struct RoutePoint: Codable, Equatable, Sendable {
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

public struct MovementSnapshot: Codable, Equatable, Sendable {
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

public enum WorldEventKind: String, Codable, CaseIterable, Hashable, Sendable {
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
    @available(*, deprecated, message: "Legacy proof-of-concept state retained only for temporary Codable compatibility.")
    case orcPursuit(OrcPursuitState)
    @available(*, deprecated, message: "Legacy proof-of-concept state retained only for temporary Codable compatibility.")
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
    public var lastEventElapsed: TimeInterval?
    public var lastEventElapsedByKind: [WorldEventKind: TimeInterval]
    public var eventHistory: [WorldEvent]
    public var activeAudioCues: [AudioCue]
    /// Last companion behavior raw value presented this session (audio coupling #130).
    public var lastPresentedBehavior: String?
    /// Session elapsed when a behavior-transition cue was last accepted.
    public var lastBehaviorAudioElapsed: TimeInterval?

    public init(
        accumulatedBondProgress: Double,
        movementSeconds: TimeInterval,
        milestoneIndex: Int,
        tone: String,
        worldState: WorldState? = nil,
        pursuitState: PursuitState = .inactive,
        lastEvent: WorldEvent? = nil,
        lastEventElapsed: TimeInterval? = nil,
        lastEventElapsedByKind: [WorldEventKind: TimeInterval] = [:],
        eventHistory: [WorldEvent] = [],
        activeAudioCues: [AudioCue] = [],
        lastPresentedBehavior: String? = nil,
        lastBehaviorAudioElapsed: TimeInterval? = nil
    ) {
        self.accumulatedBondProgress = accumulatedBondProgress
        self.movementSeconds = movementSeconds
        self.milestoneIndex = milestoneIndex
        self.tone = tone
        self.worldState = worldState
        self.pursuitState = pursuitState
        self.lastEvent = lastEvent
        self.lastEventElapsed = lastEventElapsed
        self.lastEventElapsedByKind = lastEventElapsedByKind
        self.eventHistory = eventHistory
        self.activeAudioCues = activeAudioCues
        self.lastPresentedBehavior = lastPresentedBehavior
        self.lastBehaviorAudioElapsed = lastBehaviorAudioElapsed
    }

    private enum CodingKeys: String, CodingKey {
        case accumulatedBondProgress
        case movementSeconds
        case milestoneIndex
        case tone
        case worldState
        case pursuitState
        case lastEvent
        case lastEventElapsed
        case lastEventElapsedByKind
        case eventHistory
        case activeAudioCues
        case lastPresentedBehavior
        case lastBehaviorAudioElapsed
    }

    // Decode defaults for mid-session schema evolution (behavior audio fields are session-local).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accumulatedBondProgress = try container.decode(Double.self, forKey: .accumulatedBondProgress)
        movementSeconds = try container.decode(TimeInterval.self, forKey: .movementSeconds)
        milestoneIndex = try container.decode(Int.self, forKey: .milestoneIndex)
        tone = try container.decode(String.self, forKey: .tone)
        worldState = try container.decodeIfPresent(WorldState.self, forKey: .worldState)
        pursuitState = try container.decodeIfPresent(PursuitState.self, forKey: .pursuitState) ?? .inactive
        lastEvent = try container.decodeIfPresent(WorldEvent.self, forKey: .lastEvent)
        lastEventElapsed = try container.decodeIfPresent(TimeInterval.self, forKey: .lastEventElapsed)
        lastEventElapsedByKind = try container.decodeIfPresent([WorldEventKind: TimeInterval].self, forKey: .lastEventElapsedByKind) ?? [:]
        eventHistory = try container.decodeIfPresent([WorldEvent].self, forKey: .eventHistory) ?? []
        activeAudioCues = try container.decodeIfPresent([AudioCue].self, forKey: .activeAudioCues) ?? []
        lastPresentedBehavior = try container.decodeIfPresent(String.self, forKey: .lastPresentedBehavior)
        lastBehaviorAudioElapsed = try container.decodeIfPresent(TimeInterval.self, forKey: .lastBehaviorAudioElapsed)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accumulatedBondProgress, forKey: .accumulatedBondProgress)
        try container.encode(movementSeconds, forKey: .movementSeconds)
        try container.encode(milestoneIndex, forKey: .milestoneIndex)
        try container.encode(tone, forKey: .tone)
        try container.encodeIfPresent(worldState, forKey: .worldState)
        try container.encode(pursuitState, forKey: .pursuitState)
        try container.encodeIfPresent(lastEvent, forKey: .lastEvent)
        try container.encodeIfPresent(lastEventElapsed, forKey: .lastEventElapsed)
        try container.encode(lastEventElapsedByKind, forKey: .lastEventElapsedByKind)
        try container.encode(eventHistory, forKey: .eventHistory)
        try container.encode(activeAudioCues, forKey: .activeAudioCues)
        try container.encodeIfPresent(lastPresentedBehavior, forKey: .lastPresentedBehavior)
        try container.encodeIfPresent(lastBehaviorAudioElapsed, forKey: .lastBehaviorAudioElapsed)
    }
}

@available(*, deprecated, message: "Legacy proof-of-concept state retained only for temporary Codable compatibility.")
public struct OrcPursuitState: Codable, Equatable {
    public var pursuerDistanceMeters: Double
    public var threatLevel: Double
    public var escapeMomentum: Double
    public var pressureTier: Int
    public var nearCaptureCount: Int
    public var elapsedSeconds: TimeInterval
}

@available(*, deprecated, message: "Legacy proof-of-concept state retained only for temporary Codable compatibility.")
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
    case daylightExplorer, twilightLantern, nighttimeGuardian
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
}

public struct DemoScenario {
    public let id: DemoScenarioID
    public let activity: ActivityType
    public let experienceID: String
    public let timeContext: TimeContext
    public let ticks: [(delta: TimeInterval, speed: Double)]
    public let expectedOutcome: String
}

// MARK: - Presentation (legacy demo-controller only)
//
// `MapPresentationState` / `MapEntity` / this `Coordinate` are retained for
// `DemoSessionController.presentationState` only. They are **not** the App
// MapKit surface. Product session maps use App-layer `WalkPathTrace` and
// `PlannedWalkRoute` (#121 / #155 / #179). Do not extend these types for new
// map features; prefer App presentation types.

public struct Coordinate: Codable, Equatable {
    public let lat: Double
    public let lon: Double
}

/// Legacy entity payload for demo `MapPresentationState` only — not MapKit.
public struct MapEntity: Identifiable, Equatable {
    public let id: UUID
    public let role: String
    public let coordinate: Coordinate
    public let relativeDistanceMeters: Double?
}

/// Legacy demo-controller presentation bag. Not used by App MapKit maps.
/// See App `WalkPathTrace` / `PlannedWalkRoute` for session chrome.
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
    /// Semantic path relation at end (`PathRelation.rawValue`); nil when not recorded.
    public let pathRelation: String?
    public let pathMetersAlongPath: Double
    /// Coarse cadence band (`StepCadenceBand.rawValue`); nil/unknown when unavailable.
    public let activityCadenceBand: String?

    public init(
        id: UUID,
        sessionID: UUID,
        activity: ActivityType,
        experience: String,
        variant: String,
        duration: TimeInterval,
        activeTime: TimeInterval,
        distanceMeters: Double,
        averageSpeed: Double,
        outcome: String,
        bondDelta: Int,
        memory: SessionMemory,
        pathRelation: String? = nil,
        pathMetersAlongPath: Double = 0,
        activityCadenceBand: String? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.activity = activity
        self.experience = experience
        self.variant = variant
        self.duration = duration
        self.activeTime = activeTime
        self.distanceMeters = distanceMeters
        self.averageSpeed = averageSpeed
        self.outcome = outcome
        self.bondDelta = bondDelta
        self.memory = memory
        self.pathRelation = pathRelation
        self.pathMetersAlongPath = max(0, pathMetersAlongPath.finiteOrZero)
        self.activityCadenceBand = activityCadenceBand
    }

    /// Human path line for summary UI.
    public var pathPresentationLine: String? {
        guard let raw = pathRelation, let relation = PathRelation(rawValue: raw) else { return nil }
        return WalkPathCopy.pathLine(relation: relation, metersAlongPath: pathMetersAlongPath)
    }

    /// Human cadence line for summary UI; nil when unknown.
    public var cadencePresentationLine: String? {
        guard let raw = activityCadenceBand,
              let band = StepCadenceBand(rawValue: raw) else { return nil }
        return WalkPathCopy.cadenceLine(band: band)
    }

    public func withWalkSurfacing(
        path: PathProgressSnapshot,
        enrichment: ActivityEnrichment,
        memoryText: String? = nil
    ) -> SessionSummary {
        let text = memoryText ?? memory.text
        return SessionSummary(
            id: id,
            sessionID: sessionID,
            activity: activity,
            experience: experience,
            variant: variant,
            duration: duration,
            activeTime: activeTime,
            distanceMeters: distanceMeters,
            averageSpeed: averageSpeed,
            outcome: outcome,
            bondDelta: bondDelta,
            memory: SessionMemory(sessionID: memory.sessionID, text: text),
            pathRelation: path.relation.rawValue,
            pathMetersAlongPath: path.metersAlongPath,
            activityCadenceBand: enrichment.stepCadenceBand == .unknown
                ? nil
                : enrichment.stepCadenceBand.rawValue
        )
    }
}
