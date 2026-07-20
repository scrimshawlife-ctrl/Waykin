import XCTest
@testable import WaykinCore

final class ActivityEnrichmentTests: XCTestCase {
    func testEmptyHasNoEnergyHint() {
        XCTAssertEqual(ActivityEnrichment.empty.energyHint, 0)
        XCTAssertEqual(ActivityEnrichment.empty.stepCadenceBand, .unknown)
        XCTAssertFalse(ActivityEnrichment.empty.authorizationDenied)
        XCTAssertEqual(ActivityEnrichment.empty.stepVolumeAvailability, .unknown)
    }

    func testCadenceBandsIncreaseEnergyHint() {
        let low = ActivityEnrichment(stepCadenceBand: .low, stepVolumeAvailability: .present)
        let mid = ActivityEnrichment(stepCadenceBand: .moderate, stepVolumeAvailability: .present)
        let high = ActivityEnrichment(stepCadenceBand: .high, stepVolumeAvailability: .present)
        XCTAssertLessThan(low.energyHint, mid.energyHint)
        XCTAssertLessThan(mid.energyHint, high.energyHint)
        XCTAssertLessThanOrEqual(high.energyHint, 0.25)
    }

    func testDistanceFallbackOnlyWhenStepsUnknown() {
        let withSteps = ActivityEnrichment(
            stepCadenceBand: .moderate,
            walkingDistanceMetersWindow: 5_000,
            stepVolumeAvailability: .present,
            walkingDistanceAvailability: .present
        )
        XCTAssertEqual(withSteps.energyHint, 0.12, accuracy: 0.001)

        let distanceOnly = ActivityEnrichment(
            stepCadenceBand: .unknown,
            walkingDistanceMetersWindow: 5_000,
            stepVolumeAvailability: .noData,
            walkingDistanceAvailability: .present
        )
        XCTAssertEqual(distanceOnly.energyHint, 0.12, accuracy: 0.001)
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
