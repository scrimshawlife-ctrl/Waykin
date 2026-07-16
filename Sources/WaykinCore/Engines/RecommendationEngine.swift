import Foundation

public struct RecommendationEngine {
    public init() {}

    public func recommend(for timeOfDay: String, lastExperience: String?, activity: ActivityType) -> [ExperienceRecommendation] {
        let variant = timeOfDay == "night" ? "nighttimeGuardian" : "daylightExplorer"
        return [
            ExperienceRecommendation(
                experienceID: "companion_walk",
                variantID: variant,
                observedReasons: ["walking is the MVP activity"],
                inferredReasons: ["Lira can respond through companion, pressure, and quiet-world events"],
                unavailableSignals: ["weather", "terrain", "nearby players"],
                score: 1.0
            )
        ]
    }
}
