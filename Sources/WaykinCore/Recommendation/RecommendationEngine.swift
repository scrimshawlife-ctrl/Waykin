import Foundation

public struct Recommendation: Equatable {
    public var experienceID: String
    public var experienceName: String
    public var reason: String
    public var score: Double
}

/// Phase 8: score every registered experience against current conditions and
/// history; return the top three with human-readable reasons.
public final class RecommendationEngine {
    private let experiences: ExperienceEngine
    private let memoryEngine: MemoryEngine

    public init(experiences: ExperienceEngine, memoryEngine: MemoryEngine) {
        self.experiences = experiences
        self.memoryEngine = memoryEngine
    }

    public struct Conditions {
        public var timeOfDay: TimeOfDay
        public var weather: Weather
        /// Minutes the user says they have.
        public var availableMinutes: Int

        public init(timeOfDay: TimeOfDay, weather: Weather, availableMinutes: Int) {
            self.timeOfDay = timeOfDay
            self.weather = weather
            self.availableMinutes = availableMinutes
        }
    }

    public func recommend(_ conditions: Conditions, limit: Int = 3) -> [Recommendation] {
        let history = memoryEngine.recentMemories(limit: 10)
        let lastExperienceID = history.first?.experienceID
        let playCounts = Dictionary(grouping: history, by: \.experienceID).mapValues(\.count)

        let scored = experiences.available.map { registration -> Recommendation in
            var score = 1.0
            var reasons: [String] = []

            // Variety: don't repeat yesterday's experience.
            if registration.id == lastExperienceID {
                score -= 0.4
            } else if playCounts[registration.id] == nil, !history.isEmpty {
                score += 0.3
                reasons.append("you haven't tried this yet")
            }

            // Fit the time window: challenging experiences need room.
            switch registration.difficulty {
            case .relaxed:
                if conditions.availableMinutes < 15 { score += 0.3; reasons.append("fits a short window") }
            case .moderate:
                if conditions.availableMinutes >= 15 { score += 0.2; reasons.append("a good stretch goal for today") }
            case .challenging:
                if conditions.availableMinutes >= 20 { score += 0.2; reasons.append("you have time for a real chase") }
                else { score -= 0.5 }
            }

            // Conditions: bad weather favors calm; evenings favor atmosphere.
            if conditions.weather == .rain || conditions.weather == .snow {
                score += registration.difficulty == .relaxed ? 0.2 : -0.2
                if registration.difficulty == .relaxed { reasons.append("gentle pace for rough weather") }
            }
            if conditions.timeOfDay == .evening, registration.id == OrcPursuitExperience.experienceID {
                score += 0.15
                reasons.append("dusk makes the chase better")
            }

            let reason = reasons.first ?? "a good match for right now"
            return Recommendation(experienceID: registration.id,
                                  experienceName: registration.name,
                                  reason: reason,
                                  score: score)
        }

        return Array(scored.sorted { $0.score > $1.score }.prefix(limit))
    }
}
