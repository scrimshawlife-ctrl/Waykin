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

    func testActivityEnergyHintRaisesWorldEnergyWithoutReplacingSpeed() {
        let experience = CompanionWalkExperience()
        let baseContext = ExperienceContext(timeOfDay: "day", activity: .walk, bondLevel: 3)
        let hintedContext = ExperienceContext(
            timeOfDay: "day",
            activity: .walk,
            bondLevel: 3,
            activityEnergyHint: 0.2
        )
        let state = experience.start(context: baseContext)
        let movement = MovementSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_000),
            speed: 0.2,
            distanceDelta: 0.2,
            isMoving: true
        )
        let baseUpdate = experience.update(previousState: state, movement: movement, context: baseContext)
        let hintedUpdate = experience.update(previousState: state, movement: movement, context: hintedContext)

        guard
            case .companionWalk(let baseWalk) = baseUpdate.state.runtimeState,
            case .companionWalk(let hintedWalk) = hintedUpdate.state.runtimeState,
            let baseEnergy = baseWalk.worldState?.energy,
            let hintedEnergy = hintedWalk.worldState?.energy
        else {
            return XCTFail("Expected companion walk world state")
        }
        XCTAssertGreaterThan(hintedEnergy, baseEnergy)
        XCTAssertGreaterThanOrEqual(hintedEnergy, 0.2)
    }
}
