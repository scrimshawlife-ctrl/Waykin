import Foundation

// MARK: - Companion Walk
public struct CompanionWalkExperience: WaykinExperience {
    public var definition: ExperienceDefinition {
        ExperienceDefinition(
            id: "companion_walk",
            name: "Companion Walk",
            description: "A calm exploration with your companion.",
            intensity: "low",
            timeAffinity: ["day", "night"]
        )
    }

    public init() {}

    public func start(context: ExperienceContext) -> ExperienceSessionState {
        let timeContext = TimeContext(rawValue: context.timeOfDay) ?? .midday
        let initialWorld = WorldState(
            timeContext: timeContext,
            movementState: .idle,
            currentSpeedMetersPerSecond: 0,
            sessionDistanceMeters: 0,
            activeTime: 0,
            bondLevel: context.bondLevel,
            familiarity: 0,
            energy: 0,
            pressure: 0
        )
        let state = CompanionWalkState(
            accumulatedBondProgress: 0,
            movementSeconds: 0,
            milestoneIndex: 0,
            tone: context.timeOfDay == "night" ? "calm_guardian" : "curious",
            worldState: initialWorld
        )
        return ExperienceSessionState(runtimeState: .companionWalk(state))
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        guard case .companionWalk(var walkState) = previousState.runtimeState else {
            return ExperienceUpdate(state: previousState, companionCommands: [], audioCues: [], narrativeEvents: [], rewardEvents: [])
        }

        let delta = max(0, movement.distanceDelta.finiteOrZero)
        let tickSeconds: TimeInterval = movement.isMoving ? max(1, delta / max(movement.speed, 0.5)) : 1
        if movement.isMoving {
            walkState.movementSeconds += tickSeconds
            walkState.accumulatedBondProgress += min(0.4, tickSeconds / 90)
        }

        let timeContext = TimeContext(rawValue: context.timeOfDay) ?? .midday
        let priorWorld = walkState.worldState
        let priorDistance = priorWorld?.sessionDistanceMeters ?? 0
        let pressure = Self.nextPressure(previous: priorWorld?.pressure ?? 0, movement: movement, activeTime: walkState.movementSeconds)
        var worldState = WorldState(
            timeContext: timeContext,
            movementState: movement.isMoving ? .moving : .paused,
            currentSpeedMetersPerSecond: movement.speed,
            sessionDistanceMeters: priorDistance + delta,
            activeTime: walkState.movementSeconds,
            bondLevel: context.bondLevel,
            familiarity: min(1, (priorDistance + delta) / 1800),
            energy: min(1, max(0, movement.speed) / 2.2),
            pressure: pressure,
            lastEventAt: walkState.lastEvent?.occurredAt
        )

        var generator = WorldEventGenerator(seed: context.eventSeed)
        let event = generator.evaluate(state: worldState, now: movement.timestamp)
        worldState.lastEventAt = event?.occurredAt ?? worldState.lastEventAt

        if let event {
            walkState.lastEvent = event
            walkState.pursuitState = Self.nextPursuitState(current: walkState.pursuitState, event: event)
        } else if walkState.pursuitState == .close && pressure < 0.45 {
            walkState.pursuitState = .fading
        }

        var audioLayer = AudioExperienceLayer()
        let cue = audioLayer.cue(for: event, now: movement.timestamp)
        walkState.activeAudioCues = cue.map { [$0] } ?? []
        walkState.worldState = worldState

        let behavior = Self.behavior(for: event, moving: movement.isMoving)
        let tone = Self.message(for: event, timeContext: timeContext, pursuitState: walkState.pursuitState)
        let newState = ExperienceSessionState(runtimeState: .companionWalk(walkState), narrative: event.map { [$0.debugLabel] } ?? [])

        return ExperienceUpdate(
            state: newState,
            companionCommands: [.showMessage(tone), .setBehavior(behavior.rawValue)],
            audioCues: cue.map { [$0.kind.rawValue] } ?? [],
            semanticAudioCues: cue.map { [$0] } ?? [],
            narrativeEvents: event.map { [$0.kind.rawValue] } ?? [],
            rewardEvents: []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        if case .companionWalk(let walkState) = state.runtimeState {
            let bond = max(1, Int(walkState.accumulatedBondProgress.rounded(.down)))
            let distance = Int(session.distanceMeters)
            let memory = Self.memoryText(
                companionName: "Lira",
                distanceMeters: distance,
                event: walkState.lastEvent,
                bondDelta: bond
            )
            return ExperienceResult(
                outcome: "COMPLETED",
                bondDelta: bond,
                memoryText: memory
            )
        }
        return ExperienceResult(outcome: "COMPLETED", bondDelta: 1, memoryText: "Walk completed.")
    }

    private static func nextPressure(previous: Double, movement: MovementSnapshot, activeTime: TimeInterval) -> Double {
        let timePressure = min(0.45, activeTime / 1800)
        let pausePressure = movement.isMoving ? -0.08 : 0.16
        let speedRelief = movement.speed > 1.2 ? -0.06 : 0.04
        return (previous + timePressure + pausePressure + speedRelief).clamped01
    }

    private static func nextPursuitState(current: PursuitState, event: WorldEvent) -> PursuitState {
        switch event.kind {
        case .distantPresence:
            return current == .inactive ? .noticed : current
        case .pursuitBegins:
            return .approaching
        case .pursuitIntensifies:
            return .close
        case .pursuitFades:
            return .fading
        default:
            return current
        }
    }

    private static func behavior(for event: WorldEvent?, moving: Bool) -> CompanionBehaviorState {
        guard let event else { return moving ? .follow : .observe }
        switch event.kind {
        case .companionDrawsNear, .bondMoment:
            return .drawNear
        case .companionMovesAhead, .pursuitFades:
            return .lead
        case .quietInterval:
            return .rest
        case .companionObserves, .familiarPlaceStirs, .distantPresence:
            return .observe
        case .pursuitBegins, .pursuitIntensifies:
            return .follow
        }
    }

    private static func message(for event: WorldEvent?, timeContext: TimeContext, pursuitState: PursuitState) -> String {
        guard let event else {
            return timeContext == .night ? "Lira keeps close in the dark." : "Lira matches your pace."
        }

        switch event.kind {
        case .companionDrawsNear:
            return "Lira draws near."
        case .companionMovesAhead:
            return "Lira moves a few steps ahead."
        case .companionObserves:
            return "Lira pauses, listening."
        case .distantPresence:
            return "Something distant notices the walk."
        case .pursuitBegins:
            return "A presence begins to follow."
        case .pursuitIntensifies:
            return "The pressure moves closer."
        case .pursuitFades:
            return "The pressure falls away."
        case .familiarPlaceStirs:
            return "This place feels faintly remembered."
        case .quietInterval:
            return "The world settles into quiet."
        case .bondMoment:
            return "Lira answers with a familiar motif."
        }
    }

    private static func memoryText(companionName: String, distanceMeters: Int, event: WorldEvent?, bondDelta: Int) -> String {
        if let event {
            switch event.kind {
            case .pursuitBegins, .pursuitIntensifies, .distantPresence:
                return "A distant presence followed during a \(distanceMeters)m walk, then faded. Bond increased by \(bondDelta)."
            case .bondMoment, .companionDrawsNear:
                return "\(companionName) stayed close during a \(distanceMeters)m walk. Bond increased by \(bondDelta)."
            default:
                return "\(companionName) noticed a quiet shift during a \(distanceMeters)m walk. Bond increased by \(bondDelta)."
            }
        }
        return "\(companionName) stayed close during a quiet \(distanceMeters)m walk. Bond increased by \(bondDelta)."
    }
}

// MARK: - Deprecated Proof-of-Concept Experiences
@available(*, deprecated, message: "Legacy proof-of-concept runtime. Use CompanionWalkExperience with bounded PursuitState pressure.")
public struct OrcPursuitExperience: WaykinExperience {
    public var definition: ExperienceDefinition {
        ExperienceDefinition(
            id: "orc_pursuit",
            name: "Orc Pursuit",
            description: "A raiding party is after you. Keep moving.",
            intensity: "high",
            timeAffinity: ["day", "night"]
        )
    }

    public init() {}

    public func start(context: ExperienceContext) -> ExperienceSessionState {
        let state = OrcPursuitState(
            pursuerDistanceMeters: 120,
            threatLevel: 2,
            escapeMomentum: 0,
            pressureTier: 1,
            nearCaptureCount: 0,
            elapsedSeconds: 0
        )
        return ExperienceSessionState(runtimeState: .orcPursuit(state))
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        guard case .orcPursuit(var pursuit) = previousState.runtimeState else {
            return ExperienceUpdate(state: previousState, companionCommands: [], audioCues: [], narrativeEvents: [], rewardEvents: [])
        }

        pursuit.elapsedSeconds += 1.0

        if movement.isMoving && movement.speed > 1.5 {
            pursuit.pursuerDistanceMeters += movement.speed * 0.8
        } else {
            pursuit.pursuerDistanceMeters -= 4.0
            pursuit.threatLevel = min(10, pursuit.threatLevel + 0.5)
        }

        let newState = ExperienceSessionState(runtimeState: .orcPursuit(pursuit))
        let msg = pursuit.pursuerDistanceMeters < 30 ? "They're closing fast!" : "Keep the distance."

        return ExperienceUpdate(
            state: newState,
            companionCommands: [.setThreatLevel(pursuit.threatLevel / 10), .showMessage(msg)],
            audioCues: ["heartbeat", "distant drums"],
            narrativeEvents: [msg],
            rewardEvents: []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        if case .orcPursuit(let pursuit) = state.runtimeState {
            let outcome = pursuit.pursuerDistanceMeters > 80 ? "ESCAPED" : (pursuit.pursuerDistanceMeters < 20 ? "CAUGHT_SIMULATED" : "SURVIVED")
            return ExperienceResult(outcome: outcome, bondDelta: 2, memoryText: "Orc pursuit ended with \(outcome).")
        }
        return ExperienceResult(outcome: "SURVIVED", bondDelta: 1, memoryText: "Pursuit ended.")
    }
}

@available(*, deprecated, message: "Legacy proof-of-concept runtime. Use CompanionWalkExperience with companion lead behavior.")
public struct FutureSelfExperience: WaykinExperience {
    public var definition: ExperienceDefinition {
        ExperienceDefinition(
            id: "future_self",
            name: "Future Self",
            description: "Chase a better version of yourself.",
            intensity: "medium",
            timeAffinity: ["day", "night"]
        )
    }

    public init() {}

    public func start(context: ExperienceContext) -> ExperienceSessionState {
        let state = FutureSelfState(
            targetSpeedMetersPerSecond: 2.8,
            leadMeters: 35,
            paceStability: 0,
            catchWindowActive: false,
            catchCount: 0,
            effortTrend: 0
        )
        return ExperienceSessionState(runtimeState: .futureSelf(state))
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        guard case .futureSelf(var fs) = previousState.runtimeState else {
            return ExperienceUpdate(state: previousState, companionCommands: [], audioCues: [], narrativeEvents: [], rewardEvents: [])
        }

        if movement.speed > fs.targetSpeedMetersPerSecond {
            fs.leadMeters = max(5, fs.leadMeters - (movement.speed - fs.targetSpeedMetersPerSecond) * 1.5)
        } else {
            fs.leadMeters += 1.2
        }

        let newState = ExperienceSessionState(runtimeState: .futureSelf(fs))
        let msg = fs.leadMeters < 15 ? "You're catching up!" : "Stay with the pace."

        return ExperienceUpdate(
            state: newState,
            companionCommands: [.showMessage(msg), .setBehavior("lead")],
            audioCues: ["encouraging breaths"],
            narrativeEvents: [msg],
            rewardEvents: fs.leadMeters < 10 ? ["close_window"] : []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        if case .futureSelf(let fs) = state.runtimeState {
            let outcome = fs.leadMeters < 10 ? "CAUGHT_FUTURE_SELF" : "HELD_TARGET_PACE"
            return ExperienceResult(outcome: outcome, bondDelta: 3, memoryText: "You chased your future self. Ended at \(outcome).")
        }
        return ExperienceResult(outcome: "HELD_TARGET_PACE", bondDelta: 2, memoryText: "Chase completed.")
    }
}
