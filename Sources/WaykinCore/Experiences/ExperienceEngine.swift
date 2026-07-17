import Foundation

/// Registry + runner. Experiences are registered as factories so each session
/// gets a fresh state machine. The engine knows nothing about any concrete
/// experience — that's the modularity guarantee.
public final class ExperienceEngine {
    public struct Registration {
        public let id: String
        public let name: String
        public let summary: String
        public let difficulty: Difficulty
        let make: () -> Experience

        public init(id: String, name: String, summary: String,
                    difficulty: Difficulty, make: @escaping () -> Experience) {
            self.id = id
            self.name = name
            self.summary = summary
            self.difficulty = difficulty
            self.make = make
        }
    }

    private var registrations: [String: Registration] = [:]
    private var order: [String] = []

    public init() {}

    /// Engine preloaded with the three MPOC experiences.
    public static func standard() -> ExperienceEngine {
        let engine = ExperienceEngine()
        engine.register(id: WalkTogetherExperience.experienceID,
                        name: "Companion Walk",
                        summary: "A relaxed walk together. No pressure, just presence.",
                        difficulty: .relaxed) { WalkTogetherExperience() }
        engine.register(id: OrcPursuitExperience.experienceID,
                        name: "Orc Pursuit",
                        summary: "A warband is on your trail. Keep moving to stay ahead.",
                        difficulty: .challenging) { OrcPursuitExperience() }
        engine.register(id: FutureSelfExperience.experienceID,
                        name: "Future Self",
                        summary: "A ghost of a slightly better you stays ahead. Catch it.",
                        difficulty: .moderate) { FutureSelfExperience() }
        engine.register(id: WanderingPathsExperience.experienceID,
                        name: "Wandering Paths",
                        summary: "An open walk where the world stirs around you.",
                        difficulty: .relaxed) { WanderingPathsExperience() }
        return engine
    }

    public func register(id: String, name: String, summary: String,
                         difficulty: Difficulty, make: @escaping () -> Experience) {
        if registrations[id] == nil { order.append(id) }
        registrations[id] = Registration(id: id, name: name, summary: summary,
                                         difficulty: difficulty, make: make)
    }

    public var available: [Registration] { order.compactMap { registrations[$0] } }

    public func makeExperience(id: String) -> Experience? {
        registrations[id]?.make()
    }
}

/// Drives one experience through one session. Owned by the session view model
/// (app) or the simulator loop.
public final class ExperienceRunner {
    public let experience: Experience
    public let context: ExperienceContext

    public init(experience: Experience, context: ExperienceContext) {
        self.experience = experience
        self.context = context
    }

    public func begin() -> [ExperienceEvent] {
        experience.begin(context: context)
    }

    public func handle(_ update: MovementUpdate) -> [ExperienceEvent] {
        experience.update(update, context: context)
    }

    public func finish(session: MovementSession) -> ExperienceOutcome {
        experience.end(session: session, context: context)
    }
}
