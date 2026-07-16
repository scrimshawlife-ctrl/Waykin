import XCTest
@testable import WaykinCore

final class ExperienceTests: XCTestCase {
    func testOrcPursuitThreatIncreasesWhenStopped() {
        let exp = OrcPursuitExperience()
        let ctx = ExperienceContext(timeOfDay: "night", activity: .walk)
        var state = exp.start(context: ctx)

        let stopped = MovementSnapshot(timestamp: Date(), speed: 0.1, distanceDelta: 0, isMoving: false)
        let update1 = exp.update(previousState: state, movement: stopped, context: ctx)
        state = update1.state

        if case .orcPursuit(let s) = state.runtimeState {
            XCTAssertGreaterThan(s.threatLevel, 2)
        } else {
            XCTFail("Expected orcPursuit state")
        }

        let moving = MovementSnapshot(timestamp: Date(), speed: 2.5, distanceDelta: 10, isMoving: true)
        let update2 = exp.update(previousState: state, movement: moving, context: ctx)
        if case .orcPursuit(let s2) = update2.state.runtimeState {
            XCTAssertGreaterThan(s2.pursuerDistanceMeters, 20)
        }
    }

    func testFutureSelfLeadAdjusts() {
        let exp = FutureSelfExperience()
        let ctx = ExperienceContext(timeOfDay: "day", activity: .run)
        var state = exp.start(context: ctx)

        let fast = MovementSnapshot(timestamp: Date(), speed: 3.0, distanceDelta: 15, isMoving: true)
        let update = exp.update(previousState: state, movement: fast, context: ctx)
        if case .futureSelf(let s) = update.state.runtimeState {
            XCTAssertLessThan(s.leadMeters, 35)
        }
    }

    func testRecommendationDayNightDiffers() {
        let rec = RecommendationEngine()
        let day = rec.recommend(for: "day", lastExperience: nil, activity: .walk)
        let night = rec.recommend(for: "night", lastExperience: nil, activity: .walk)

        XCTAssertEqual(day.map(\.experienceID), ["companion_walk"])
        XCTAssertEqual(night.map(\.experienceID), ["companion_walk"])
        XCTAssertNotEqual(day.first?.variantID, night.first?.variantID)
    }
}
