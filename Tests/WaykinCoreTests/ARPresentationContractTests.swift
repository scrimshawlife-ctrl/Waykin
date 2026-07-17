import Foundation
import XCTest
@testable import WaykinCore

final class ARPresentationContractTests: XCTestCase {
    func testSpatialIntentRoundTripsThroughJSON() throws {
        let intent = SpatialIntent(
            placement: .groundPlane,
            distanceBand: .near,
            bearing: .ahead,
            scaleClass: .companion,
            persistence: .session
        )

        let data = try JSONEncoder().encode(intent)
        let decoded = try JSONDecoder().decode(SpatialIntent.self, from: data)

        XCTAssertEqual(decoded, intent)
    }

    func testARWorldCommandRoundTripsWithoutPlatformFrameworks() throws {
        let presentation = CompanionPresentation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Lira",
            behavior: "following",
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .companion,
                persistence: .session
            )
        )
        let command = ARWorldCommand.spawnCompanion(presentation)

        let data = try JSONEncoder().encode(command)
        let decoded = try JSONDecoder().decode(ARWorldCommand.self, from: data)

        XCTAssertEqual(decoded, command)
    }

    func testThreatIntensityIsNormalizedToUnitInterval() {
        let spatialIntent = SpatialIntent(
            placement: .worldRelative,
            distanceBand: .far,
            bearing: .behind,
            scaleClass: .threat,
            persistence: .encounter
        )

        XCTAssertEqual(
            ThreatPresentation(id: UUID(), kind: "shadow", intensity: -1, spatialIntent: spatialIntent).intensity,
            0
        )
        XCTAssertEqual(
            ThreatPresentation(id: UUID(), kind: "shadow", intensity: 2, spatialIntent: spatialIntent).intensity,
            1
        )
        XCTAssertEqual(
            ThreatPresentation(id: UUID(), kind: "shadow", intensity: .infinity, spatialIntent: spatialIntent).intensity,
            0
        )
    }

    func testCapabilityStateRemainsPlatformNeutralAndCodable() throws {
        let states = ARCapabilityState.allCases
        let data = try JSONEncoder().encode(states)
        let decoded = try JSONDecoder().decode([ARCapabilityState].self, from: data)

        XCTAssertEqual(decoded, states)
        XCTAssertEqual(decoded.last, .active)
    }
}
