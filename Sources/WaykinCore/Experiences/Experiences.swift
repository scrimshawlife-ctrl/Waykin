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
        let state = CompanionWalkState(
            accumulatedBondProgress: 0,
            movementSeconds: 0,
            milestoneIndex: 0,
            tone: context.timeOfDay == "night" ? "calm_guardian" : "curious"
        )
        return ExperienceSessionState(runtimeState: .companionWalk(state))
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        guard case .companionWalk(var walkState) = previousState.runtimeState else {
            return ExperienceUpdate(state: previousState, companionCommands: [], audioCues: [], narrativeEvents: [], rewardEvents: [])
        }

        if movement.isMoving {
            walkState.movementSeconds += 1.0
            walkState.accumulatedBondProgress += 0.1
        }

        let newState = ExperienceSessionState(runtimeState: .companionWalk(walkState))

        let tone = context.timeOfDay == "night" ? "The stars feel closer tonight." : "Look at that view!"
        return ExperienceUpdate(
            state: newState,
            companionCommands: [.showMessage(tone), .setBehavior(movement.isMoving ? "follow" : "observe")],
            audioCues: movement.isMoving ? ["soft footsteps"] : [],
            narrativeEvents: [tone],
            rewardEvents: []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        if case .companionWalk(let walkState) = state.runtimeState {
            let bond = Int(walkState.accumulatedBondProgress)
            return ExperienceResult(
                outcome: "COMPLETED",
                bondDelta: bond / 10,
                memoryText: "We walked \(Int(session.distanceMeters))m together. Bond grew by \(bond / 10)."
            )
        }
        return ExperienceResult(outcome: "COMPLETED", bondDelta: 1, memoryText: "Walk completed.")
    }
}

// MARK: - Orc Pursuit (typed state skeleton, time-based logic to be expanded)
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

// MARK: - Future Self (typed state skeleton)
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
