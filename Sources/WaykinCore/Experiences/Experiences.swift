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
        var state = ExperienceSessionState()
        state.data["bond"] = "0"
        state.data["mood"] = context.timeOfDay == "night" ? "calm_guardian" : "curious"
        state.narrative.append("Your companion falls in step beside you.")
        return state
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        var state = previousState
        var bond = Int(state.data["bond"] ?? "0") ?? 0
        if movement.isMoving {
            bond += 1
            state.data["bond"] = "\(bond)"
        }
        let tone = context.timeOfDay == "night" ? "The stars feel closer tonight." : "Look at that view!"
        return ExperienceUpdate(
            state: state,
            companionCommands: [.showMessage(tone), .setBehavior(movement.isMoving ? "follow" : "observe")],
            audioCues: movement.isMoving ? ["soft footsteps"] : [],
            narrativeEvents: [tone],
            rewardEvents: []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        let bond = Int(state.data["bond"] ?? "0") ?? 0
        return ExperienceResult(
            outcome: "COMPLETED",
            bondDelta: bond / 10,
            memoryText: "We walked \(Int(session.distanceMeters))m together. Bond grew by \(bond / 10)."
        )
    }
}

// MARK: - Orc Pursuit
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
        var state = ExperienceSessionState()
        state.data["pursuerDistance"] = "120"
        state.data["threat"] = "2"
        state.narrative.append(context.timeOfDay == "night" ? "Torches flicker in the dark." : "You hear war drums.")
        return state
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        var state = previousState
        var dist = Double(state.data["pursuerDistance"] ?? "120") ?? 120
        var threat = Int(state.data["threat"] ?? "2") ?? 2

        if movement.isMoving && movement.speed > 1.5 {
            dist += movement.speed * 0.8
        } else {
            dist -= 4.0
            threat = min(10, threat + 1)
        }

        state.data["pursuerDistance"] = String(format: "%.0f", max(10, dist))
        state.data["threat"] = "\(threat)"

        let cmd: CompanionCommand = threat > 7 ? .setThreatLevel(0.9) : .setThreatLevel(0.3)
        let msg = dist < 30 ? "They're closing fast!" : "Keep the distance."

        return ExperienceUpdate(
            state: state,
            companionCommands: [cmd, .showMessage(msg)],
            audioCues: ["heartbeat", "distant drums"],
            narrativeEvents: [msg],
            rewardEvents: []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        let dist = Double(state.data["pursuerDistance"] ?? "50") ?? 50
        let outcome = dist > 80 ? "ESCAPED" : (dist < 20 ? "CAUGHT_SIMULATED" : "SURVIVED")
        return ExperienceResult(outcome: outcome, bondDelta: 2, memoryText: "Orc pursuit ended with \(outcome).")
    }
}

// MARK: - Future Self
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
        var state = ExperienceSessionState()
        state.data["leadMeters"] = "35"
        state.data["targetPace"] = "5.5"
        state.narrative.append("A familiar silhouette pulls ahead.")
        return state
    }

    public func update(previousState: ExperienceSessionState, movement: MovementSnapshot, context: ExperienceContext) -> ExperienceUpdate {
        var state = previousState
        var lead = Double(state.data["leadMeters"] ?? "35") ?? 35

        if movement.speed > 2.5 {
            lead = max(5, lead - (movement.speed - 2.0) * 2)
        } else {
            lead += 1.5
        }

        state.data["leadMeters"] = String(format: "%.0f", lead)

        let msg = lead < 15 ? "You're catching up!" : "Stay with the pace."

        return ExperienceUpdate(
            state: state,
            companionCommands: [.showMessage(msg), .setBehavior("lead")],
            audioCues: ["encouraging breaths"],
            narrativeEvents: [msg],
            rewardEvents: lead < 10 ? ["close_window"] : []
        )
    }

    public func finish(state: ExperienceSessionState, session: MovementSession) -> ExperienceResult {
        let lead = Double(state.data["leadMeters"] ?? "30") ?? 30
        let outcome = lead < 10 ? "CAUGHT_FUTURE_SELF" : "HELD_TARGET_PACE"
        return ExperienceResult(outcome: outcome, bondDelta: 3, memoryText: "You chased your future self. Ended at \(outcome).")
    }
}
