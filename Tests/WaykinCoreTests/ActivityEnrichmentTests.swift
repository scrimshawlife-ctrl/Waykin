import XCTest
@testable import WaykinCore

final class ActivityEnrichmentTests: XCTestCase {
    func testEmptyHasNoEnergyHint() {
        XCTAssertEqual(ActivityEnrichment.empty.energyHint, 0)
        XCTAssertEqual(ActivityEnrichment.empty.stepCadenceBand, .unknown)
        XCTAssertFalse(ActivityEnrichment.empty.authorizationDenied)
    }

    func testCadenceBandsIncreaseEnergyHint() {
        let low = ActivityEnrichment(stepCadenceBand: .low)
        let mid = ActivityEnrichment(stepCadenceBand: .moderate)
        let high = ActivityEnrichment(stepCadenceBand: .high)
        XCTAssertLessThan(low.energyHint, mid.energyHint)
        XCTAssertLessThan(mid.energyHint, high.energyHint)
        XCTAssertLessThanOrEqual(high.energyHint, 0.25)
    }

    func testNegativeInputsClamp() {
        let sample = ActivityEnrichment(
            stepCadenceBand: .moderate,
            stepCountWindow: -5,
            walkingDistanceMetersWindow: -10
        )
        XCTAssertEqual(sample.stepCountWindow, 0)
        XCTAssertEqual(sample.walkingDistanceMetersWindow, 0)
    }
}
