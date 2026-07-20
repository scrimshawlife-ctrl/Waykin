import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class PathARCouplingTests: XCTestCase {
    func testPathStrainedBiasesInvestigateWithoutThreatEntities() {
        let mapper = CanonicalARWorldCommandMapper(companionID: UUID(), companionName: "Lira")
        var runtime = CompanionRuntime()
        runtime.apply(command: .setBehavior(CompanionBehaviorState.follow.rawValue))
        runtime.apply(command: .setRelativeDistance(1.8))

        let commands = mapper.update(
            companionRuntime: runtime,
            event: nil,
            pursuitState: .inactive,
            pathRelation: .strained,
            pathIntegrityPressure: 0.5
        )
        guard case .updateCompanion(let presentation) = commands.first else {
            return XCTFail("Expected updateCompanion")
        }
        XCTAssertEqual(presentation.behavior, "investigate")
        XCTAssertFalse(commands.contains {
            if case .spawnThreat = $0 { return true }
            if case .spawnDiscovery = $0 { return true }
            return false
        })
    }

    func testPathOffPathBiasesAlertWithoutThreatEntities() {
        let mapper = CanonicalARWorldCommandMapper(companionID: UUID(), companionName: "Lira")
        var runtime = CompanionRuntime()
        runtime.apply(command: .setBehavior(CompanionBehaviorState.follow.rawValue))

        let commands = mapper.update(
            companionRuntime: runtime,
            event: nil,
            pursuitState: .inactive,
            pathRelation: .offPath,
            pathIntegrityPressure: 0.8
        )
        guard case .updateCompanion(let presentation) = commands.first else {
            return XCTFail("Expected updateCompanion")
        }
        XCTAssertEqual(presentation.behavior, "alert")
        XCTAssertFalse(commands.contains {
            if case .spawnThreat = $0 { return true }
            return false
        })
    }

    func testLeadKeepsFarBandAndAheadBearing() {
        let mapper = CanonicalARWorldCommandMapper(companionID: UUID(), companionName: "Lira")
        var runtime = CompanionRuntime()
        runtime.apply(event: WorldEvent(
            kind: .companionMovesAhead,
            occurredAt: Date(),
            intensity: 0.5,
            debugLabel: "ahead"
        ))
        let commands = mapper.update(
            companionRuntime: runtime,
            event: WorldEvent(
                kind: .companionMovesAhead,
                occurredAt: Date(),
                intensity: 0.5,
                debugLabel: "ahead"
            )
        )
        guard case .updateCompanion(let presentation) = commands.first else {
            return XCTFail("Expected updateCompanion")
        }
        XCTAssertEqual(presentation.behavior, "follow")
        XCTAssertEqual(presentation.spatialIntent.distanceBand, .far)
        XCTAssertEqual(presentation.spatialIntent.bearing, .ahead)
    }

    func testQuietIntervalMapsToIdleARString() {
        let mapper = CanonicalARWorldCommandMapper(companionID: UUID(), companionName: "Lira")
        var runtime = CompanionRuntime()
        runtime.apply(event: WorldEvent(
            kind: .quietInterval,
            occurredAt: Date(),
            intensity: 0.2,
            debugLabel: "quiet"
        ))
        let commands = mapper.update(
            companionRuntime: runtime,
            event: WorldEvent(
                kind: .quietInterval,
                occurredAt: Date(),
                intensity: 0.2,
                debugLabel: "quiet"
            )
        )
        guard case .updateCompanion(let presentation) = commands.first else {
            return XCTFail("Expected updateCompanion")
        }
        XCTAssertEqual(runtime.state, .rest)
        XCTAssertEqual(presentation.behavior, "idle")
    }
}
