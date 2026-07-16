import Foundation

public struct RecommendationEngine {
    public init() {}

    public func recommend(for timeOfDay: String, lastExperience: String?, activity: ActivityType) -> [ExperienceRecommendation] {
        var recs: [ExperienceRecommendation] = []

        if timeOfDay == "night" {
            recs.append(ExperienceRecommendation(
                experienceID: "companion_walk",
                variantID: "guardian",
                observedReasons: ["night time"],
                inferredReasons: ["calm tone suits reflective walks"],
                unavailableSignals: [],
                score: 0.9
            ))
            recs.append(ExperienceRecommendation(
                experienceID: "orc_pursuit",
                variantID: "torch",
                observedReasons: ["night"],
                inferredReasons: ["suspense fits darkness"],
                unavailableSignals: [],
                score: 0.7
            ))
        } else {
            recs.append(ExperienceRecommendation(
                experienceID: "future_self",
                variantID: "day",
                observedReasons: ["daytime energy"],
                inferredReasons: ["competitive pacing good for day"],
                unavailableSignals: [],
                score: 0.85
            ))
            recs.append(ExperienceRecommendation(
                experienceID: "companion_walk",
                variantID: "curious",
                observedReasons: ["day"],
                inferredReasons: ["exploration fits daylight"],
                unavailableSignals: [],
                score: 0.8
            ))
        }

        if lastExperience == "future_self" {
            recs = recs.map { var r = $0; if r.experienceID == "companion_walk" { r.score += 0.1 }; return r }.sorted { $0.score > $1.score }
        }

        return Array(recs.prefix(3))
    }
}
