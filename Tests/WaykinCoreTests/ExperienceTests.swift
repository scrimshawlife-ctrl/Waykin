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

        let threat1 = Int(state.data["threat"] ?? "0") ?? 0
        XCTAssertGreaterThan(threat1, 2)

        // Moving should reduce threat/distance
        let moving = MovementSnapshot(timestamp: Date(), speed: 2.5, distanceDelta: 10, isMoving: true)
        let update2 = exp.update(previousState: state, movement: moving, context: ctx)
        let dist = Double(update2.state.data["pursuerDistance"] ?? "0") ?? 0
        XCTAssertGreaterThan(dist, 20)
    }

    func testFutureSelfLeadAdjusts() {
        let exp = FutureSelfExperience()
        let ctx = ExperienceContext(timeOfDay: "day", activity: .run)
        var state = exp.start(context: ctx)

        let fast = MovementSnapshot(timestamp: Date(), speed: 3.0, distanceDelta: 15, isMoving: true)
        let update = exp.update(previousState: state, movement: fast, context: ctx)
        let lead = Double(update.state.data["leadMeters"] ?? "100") ?? 100
        XCTAssertLessThan(lead, 35) // should close
    }

    func testRecommendationDayNightDiffers() {
        let rec = RecommendationEngine()
        let day = rec.recommend(for: "day", lastExperience: nil, activity: .walk)
        let night = rec.recommend(for: "night", lastExperience: nil, activity: .walk)

        XCTAssertTrue(day.contains { $0.experienceID == "future_self" })
        XCTAssertTrue(night.contains { $0.experienceID == "companion_walk" })
    }
}
