import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class ARRuntimeIntegrationTests: XCTestCase {
    func testAdapterMapsCanonicalCompanionStatesDeterministically() {
        let adapter = ARCompanionRuntimeAdapter()

        XCTAssertEqual(adapter.presentationState(for: .idle), .idle)
        XCTAssertEqual(adapter.presentationState(for: .rest), .idle)
        XCTAssertEqual(adapter.presentationState(for: .follow), .follow)
        XCTAssertEqual(adapter.presentationState(for: .lead), .follow)
        XCTAssertEqual(adapter.presentationState(for: .observe), .investigate)
        XCTAssertEqual(adapter.presentationState(for: .drawNear), .alert)
        XCTAssertEqual(adapter.presentationState(for: .celebrate), .celebrate)
    }

    func testAdapterProducesStableCompanionIdentity() {
        let adapter = ARCompanionRuntimeAdapter()
        var runtime = CompanionRuntime()
        runtime.state = .observe
        runtime.relativeDistance = 2.5

        let first = adapter.companionCommand(runtime: runtime, replacingExisting: false)
        let second = adapter.companionCommand(runtime: runtime, replacingExisting: true)

        guard case .spawnCompanion(let spawn) = first,
              case .updateCompanion(let update) = second else {
            return XCTFail("Expected spawn followed by update")
        }
        XCTAssertEqual(spawn.id, ARCompanionRuntimeAdapter.companionID)
        XCTAssertEqual(update.id, spawn.id)
        XCTAssertEqual(spawn.behavior, CompanionPresentationState.investigate.rawValue)
        XCTAssertEqual(spawn.spatialIntent.distanceBand, .near)
    }

    func testDemoBridgeEmitsCanonicalSevenEventArc() throws {
        let bridge = ARDemoRuntimeBridge()
        let opening = try bridge.start()

        XCTAssertEqual(opening.tickIndex, 0)
        XCTAssertNil(opening.eventKind)
        XCTAssertEqual(opening.commands.count, 1)

        var events: [WorldEventKind] = []
        while bridge.tickIndex < bridge.totalTicks {
            guard let frame = bridge.advance() else {
                return XCTFail("Expected a demo frame")
            }
            if let event = frame.eventKind {
                events.append(event)
            }
        }

        XCTAssertEqual(events, [
            .companionObserves,
            .companionDrawsNear,
            .distantPresence,
            .pursuitBegins,
            .pursuitIntensifies,
            .pursuitFades,
            .bondMoment
        ])
    }

    func testThreatLifecycleUsesStableSemanticIdentity() {
        let adapter = ARCompanionRuntimeAdapter()
        let begins = WorldEvent(kind: .pursuitBegins, timestamp: .distantPast, metadata: [:])
        let intensifies = WorldEvent(kind: .pursuitIntensifies, timestamp: .distantPast, metadata: [:])
        let fades = WorldEvent(kind: .pursuitFades, timestamp: .distantPast, metadata: [:])

        guard case .spawnThreat(let initial)? = adapter.eventCommands(for: begins).first,
              case .spawnThreat(let updated)? = adapter.eventCommands(for: intensifies).first,
              case .removeEntity(let removed)? = adapter.eventCommands(for: fades).first else {
            return XCTFail("Expected threat spawn, update representation, and removal")
        }

        XCTAssertEqual(initial.id, ARCompanionRuntimeAdapter.threatID)
        XCTAssertEqual(updated.id, initial.id)
        XCTAssertGreaterThan(updated.intensity, initial.intensity)
        XCTAssertEqual(removed, initial.id)
    }
}
