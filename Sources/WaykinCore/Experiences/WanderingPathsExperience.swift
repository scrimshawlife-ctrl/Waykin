import Foundation

/// An ambient, emergent walk: the world-event generator (ported from the
/// sibling implementation) surfaces moments — quiet stretches, a distant
/// presence, a brief pursuit that builds and fades, bond moments — based on
/// how you're actually moving. No fail state; the walk writes itself.
///
/// This is also the standing proof of the plug-in contract: a fourth
/// experience added with zero changes to the engines.
public final class WanderingPathsExperience: Experience {
    public static let experienceID = "wandering-paths"

    public let id = WanderingPathsExperience.experienceID
    public let name = "Wandering Paths"
    public let summary = "An open walk where the world stirs around you."
    public let difficulty = Difficulty.relaxed

    private var generator: WorldEventGenerator
    private var pressure = 0.0
    private var familiarity: Double
    private var lastElapsed: TimeInterval = 0
    private var bondMoments = 0
    private var eventKinds: Set<WorldEventKind> = []

    /// - Parameter seed: replay seed; a given seed reproduces the same walk.
    public init(seed: UInt64 = 0x57A9D1) {
        generator = WorldEventGenerator(
            seed: seed,
            configuration: WorldEventConfiguration(minimumTickSpacing: 60))
        familiarity = 0
    }

    public func begin(context: ExperienceContext) -> [ExperienceEvent] {
        familiarity = context.placeFamiliarity
        return [
            .companionBehavior(.follow),
            .audio(.ambient),
            .dialogue("No quest today. Let's just walk \(context.locationName) and see what the world does."),
        ]
    }

    public func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent] {
        let dt = max(0, update.elapsedSeconds - lastElapsed)
        lastElapsed = update.elapsedSeconds

        // Pressure decays while you move with energy; lingers when you idle.
        let decay = update.isMoving ? 0.004 : 0.001
        pressure = max(0, pressure - decay * dt)

        // The world breathes: a slow ambient swell (≈8-minute period) floors
        // the pressure so pursuit arcs can ignite without an external system,
        // which the original relied on. Movement can outrun it; idling can't.
        let ambient = 0.4 * pow(sin(update.elapsedSeconds / 150), 2)
        pressure = min(1, max(pressure, ambient))

        let energy = min(1, update.speedMetersPerSecond / 2.2)
            + min(0.25, update.elapsedSeconds / 1200)
        let snapshot = WorldSnapshot(
            energy: min(1, energy),
            pressure: pressure,
            familiarity: familiarity,
            bondPoints: context.companion.relationship.bondPoints,
            isMoving: update.isMoving)

        var events: [ExperienceEvent] = [
            .companionBehavior(update.isMoving
                ? (update.detectedActivity == .running ? .run : .walk)
                : .idle),
        ]

        if let event = generator.evaluate(snapshot, elapsed: update.elapsedSeconds) {
            eventKinds.insert(event.kind)
            events.append(contentsOf: present(event, context: context))
        }
        events.append(.threatLevel(pressure))
        return events
    }

    public func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome {
        let km = session.distanceMeters / 1000
        let bond = max(2, min(9, Int(km * 3) + bondMoments * 2))
        let seed: String
        if eventKinds.contains(.pursuitIntensifies) || eventKinds.contains(.pursuitBegins) {
            seed = "wandered until something followed, then lost it"
        } else if bondMoments > 0 {
            seed = "wandered and shared a quiet moment"
        } else {
            seed = "wandered wherever the paths led"
        }
        return ExperienceOutcome(
            succeeded: true,
            bondDelta: bond,
            memorySeed: seed,
            summaryLine: String(format: "An open %.1f km wander — %d moment%@ along the way.",
                                km, eventKinds.count, eventKinds.count == 1 ? "" : "s")
        )
    }

    /// Map a world event onto the experience-event channels.
    private func present(_ event: WorldEvent, context: ExperienceContext) -> [ExperienceEvent] {
        let name = context.companion.name
        switch event.kind {
        case .quietInterval:
            return [.dialogue("The path has gone quiet. I like it like this.")]
        case .companionDrawsNear:
            return [.companionBehavior(.follow), .dialogue("\(name) draws near, matching your stride.")]
        case .companionMovesAhead:
            return [.companionBehavior(.run), .dialogue("\(name) darts ahead to scout the bend.")]
        case .companionObserves:
            return [.companionBehavior(.alert), .dialogue("\(name) pauses, watching something you can't see yet.")]
        case .distantPresence:
            pressure = min(1, max(pressure, 0.3))
            return [.audio(.heartbeatSlow), .dialogue("Something is keeping pace, far off the trail.")]
        case .pursuitBegins:
            pressure = min(1, max(pressure, 0.5))
            return [.audio(.heartbeatSlow), .companionBehavior(.alert),
                    .dialogue("It's closer now. Stay with me — keep moving.")]
        case .pursuitIntensifies:
            pressure = min(1, pressure + 0.2)
            return [.audio(.heartbeatFast), .dialogue("Faster. It's right behind the treeline!")]
        case .pursuitFades:
            pressure = 0.12
            return [.audio(.chime), .companionBehavior(.celebrate),
                    .milestone("The presence faded"),
                    .dialogue("...and it's gone. The path is ours again.")]
        case .familiarPlaceStirs:
            return [.audio(.chime), .dialogue("The path feels familiar here. We've written memories on it.")]
        case .bondMoment:
            bondMoments += 1
            return [.companionBehavior(.celebrate), .audio(.chime),
                    .milestone("A shared moment"),
                    .dialogue("\(name) leans against you for a step. Just because.")]
        }
    }
}
