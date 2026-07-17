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

    func testEventSemanticsOverrideGenericRuntimeState() {
        let adapter = ARCompanionRuntimeAdapter()
        var runtime = CompanionRuntime()
        runtime.state = .follow

        XCTAssertEqual(
            adapter.presentationState(runtime: runtime, event: event(.pursuitBegins)),
            .alert
        )
        XCTAssertEqual(
            adapter.presentationState(runtime: runtime, event: event(.bondMoment)),
            .celebrate
        )
        XCTAssertEqual(
            adapter.presentationState(runtime: runtime, event: event(.companionObserves)),
            .investigate
        )
    }

    func testAdapterProducesStableCompanionIdentity() {
        let adapter = ARCompanionRuntimeAdapter()
        var runtime = CompanionRuntime()
        runtime.state = .observe
        runtime.relativeDistance = 2.5

        let first = adapter.companionCommand(runtime: runtime, event: nil, replacingExisting: false)
        let second = adapter.companionCommand(runtime: runtime, event: nil, replacingExisting: true)

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
        var states: [CompanionPresentationState] = []
        while bridge.tickIndex < bridge.totalTicks {
            guard let frame = bridge.advance() else {
                return XCTFail("Expected a demo frame")
            }
            if let event = frame.eventKind {
                events.append(event)
                states.append(frame.companionState)
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
        XCTAssertEqual(states, [
            .investigate,
            .alert,
            .investigate,
            .alert,
            .alert,
            .follow,
            .celebrate
        ])
    }

    func testThreatLifecycleUsesStableSemanticIdentity() {
        let adapter = ARCompanionRuntimeAdapter()
        let begins = event(.pursuitBegins)
        let intensifies = event(.pursuitIntensifies)
        let fades = event(.pursuitFades)

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

    private func event(_ kind: WorldEventKind) -> WorldEvent {
        WorldEvent(
            kind: kind,
            occurredAt: .distantPast,
            intensity: 0.5,
            debugLabel: kind.rawValue
        )
    }
}
