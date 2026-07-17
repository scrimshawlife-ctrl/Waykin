import Foundation

/// Relaxed exploration. Positive dialogue at distance milestones,
/// gentle nudges after long pauses. Cannot fail.
public final class WalkTogetherExperience: Experience {
    public static let experienceID = "walk-together"

    public let id = WalkTogetherExperience.experienceID
    public let name = "Companion Walk"
    public let summary = "A relaxed walk together. No pressure, just presence."
    public let difficulty = Difficulty.relaxed

    private var nextMilestoneMeters: Double = 250
    private var stoppedSince: TimeInterval?
    private var remarkedOnPause = false

    public init() {}

    public func begin(context: ExperienceContext) -> [ExperienceEvent] {
        let opener: String
        switch context.timeOfDay {
        case .morning: opener = "Morning air! Let's see where \(context.locationName) takes us."
        case .afternoon: opener = "A walk through \(context.locationName)? Perfect. Lead the way."
        case .evening: opener = "Evening light suits \(context.locationName). Let's wander."
        case .night: opener = "A night walk — quiet and ours. Stay close."
        }
        return [.companionBehavior(.follow), .audio(.ambient), .dialogue(opener)]
    }

    public func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent] {
        var events: [ExperienceEvent] = []

        if update.distanceMeters >= nextMilestoneMeters {
            events.append(.milestone(String(format: "%.0f m together", nextMilestoneMeters)))
            events.append(.dialogue(milestoneLine(at: nextMilestoneMeters, context: context)))
            events.append(.audio(.chime))
            nextMilestoneMeters += 250
        }

        if update.isMoving {
            stoppedSince = nil
            remarkedOnPause = false
            events.append(.companionBehavior(update.detectedActivity == .running ? .run : .walk))
        } else {
            if stoppedSince == nil { stoppedSince = update.elapsedSeconds }
            events.append(.companionBehavior(.idle))
            if let since = stoppedSince, update.elapsedSeconds - since > 45, !remarkedOnPause {
                remarkedOnPause = true
                events.append(.dialogue("Taking it in? I like this spot too."))
            }
        }
        return events
    }

    public func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome {
        let km = session.distanceMeters / 1000
        let bond = max(2, min(8, Int(km * 4)))
        return ExperienceOutcome(
            succeeded: true,
            bondDelta: bond,
            memorySeed: "just walked and talked",
            summaryLine: String(format: "A calm %.1f km walk together.", km)
        )
    }

    private func milestoneLine(at meters: Double, context: ExperienceContext) -> String {
        let lines = [
            "Look at us go. \(context.locationName) is better with company.",
            "I'm starting to know these paths by heart.",
            "You set a good rhythm. I could do this all day.",
            "Another stretch behind us. Tell me something about your day?",
        ]
        let index = Int(meters / 250 - 1) % lines.count
        return lines[index]
    }
}
