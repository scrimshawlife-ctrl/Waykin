import XCTest
@testable import WaykinCore

final class ExperienceTests: XCTestCase {
    func testRecommendationDayNightDiffers() {
        let rec = RecommendationEngine()
        let day = rec.recommend(for: "day", lastExperience: nil, activity: .walk)
        let night = rec.recommend(for: "night", lastExperience: nil, activity: .walk)

        XCTAssertEqual(day.map(\.experienceID), ["companion_walk"])
        XCTAssertEqual(night.map(\.experienceID), ["companion_walk"])
        XCTAssertNotEqual(day.first?.variantID, night.first?.variantID)
    }

    func testRecommendationsNeverReturnLegacyExperienceIDs() {
        let rec = RecommendationEngine()
        for time in ["day", "night", "twilight"] {
            let ids = rec.recommend(for: time, lastExperience: "orc_pursuit", activity: .walk).map(\.experienceID)
            XCTAssertFalse(ids.contains("orc_pursuit"))
            XCTAssertFalse(ids.contains("future_self"))
            XCTAssertEqual(Set(ids), ["companion_walk"])
        }
    }

    func testVariantIDsAreLimitedToCompanionWalk() {
        let variants = Set(ExperienceVariantID.allCases.map(\.rawValue))
        XCTAssertEqual(variants, ["daylightExplorer", "twilightLantern", "nighttimeGuardian"])
    }
}
