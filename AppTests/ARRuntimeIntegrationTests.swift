import RealityKit
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
        bridge.markCompanionPlaced()
        bridge.acknowledgeRenderedFrame()

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
            bridge.acknowledgeRenderedFrame()
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
        XCTAssertFalse(bridge.isRunning)
        XCTAssertNil(bridge.controller.movementEngine.currentSession)
    }

    func testDemoBridgeRetriesSpawnUntilRendererAcknowledgesPlacement() throws {
        let bridge = ARDemoRuntimeBridge()
        let opening = try bridge.start()

        guard case .spawnCompanion = opening.commands.first else {
            return XCTFail("Expected opening spawn")
        }
        guard let retry = bridge.advance(), case .spawnCompanion = retry.commands.first else {
            return XCTFail("Expected spawn retry after deferred placement")
        }
        XCTAssertEqual(retry.tickIndex, opening.tickIndex)
        XCTAssertNil(retry.eventKind)

        bridge.markCompanionPlaced()
        bridge.acknowledgeRenderedFrame()
        guard let update = bridge.advance(), case .updateCompanion = update.commands.first else {
            return XCTFail("Expected updates after placement acknowledgement")
        }
        XCTAssertEqual(update.tickIndex, 1)
    }

    func testThreatLifecycleUsesStableSemanticIdentity() {
        let adapter = ARCompanionRuntimeAdapter()
        let begins = event(.pursuitBegins)
        let intensifies = event(.pursuitIntensifies)
        let fades = event(.pursuitFades)

        guard case .spawnThreat(let initial)? = adapter.eventCommands(
            for: begins,
            threatExists: false
        ).first,
              case .updateThreat(let updated)? = adapter.eventCommands(
                for: intensifies,
                threatExists: true
              ).first,
              case .removeEntity(let removed)? = adapter.eventCommands(for: fades).first else {
            return XCTFail("Expected threat spawn, update representation, and removal")
        }

        XCTAssertEqual(initial.id, ARCompanionRuntimeAdapter.threatID)
        XCTAssertEqual(updated.id, initial.id)
        XCTAssertGreaterThan(updated.intensity, initial.intensity)
        XCTAssertEqual(removed, initial.id)
    }

    func testAmbientEventsDoNotInventDiscoveryEntities() {
        let adapter = ARCompanionRuntimeAdapter()

        XCTAssertTrue(adapter.eventCommands(for: event(.companionObserves)).isEmpty)
        XCTAssertTrue(adapter.eventCommands(for: event(.familiarPlaceStirs)).isEmpty)
        XCTAssertTrue(adapter.eventCommands(for: event(.quietInterval)).isEmpty)
    }

    func testThreatUpdatePreservesAnchorAndAppliesIntensity() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        let anchor = Entity()
        let marker = Entity()
        anchor.addChild(marker)
        let id = ARCompanionRuntimeAdapter.threatID
        registry.register(anchor, for: id.uuidString)

        let presentation = ThreatPresentation(
            id: id,
            kind: WorldEventKind.pursuitIntensifies.rawValue,
            intensity: 0.85,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .medium,
                bearing: .ahead,
                scaleClass: .threat,
                persistence: .encounter
            )
        )
        let result = renderer.render(.updateThreat(presentation), in: ARView(frame: .zero))

        XCTAssertEqual(result, .accepted("threat:update"))
        XCTAssertTrue(registry.entity(for: id.uuidString) === anchor)
        XCTAssertGreaterThan(marker.scale.x, 1)
    }

    func testCompanionUpdateUsesPresentationIdentityEndToEnd() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        let id = UUID()
        let anchor = Entity()
        anchor.addChild(CompanionEntityFactory().makeLira())
        registry.register(anchor, for: id.uuidString)
        let presentation = CompanionPresentation(
            id: id,
            name: "Lira",
            behavior: CompanionPresentationState.alert.rawValue,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .companion,
                persistence: .session
            )
        )

        let result = renderer.render(.updateCompanion(presentation), in: ARView(frame: .zero))

        XCTAssertEqual(result, .accepted("companion:alert"))
        XCTAssertTrue(registry.entity(for: id.uuidString) === anchor)
    }

    func testDemoBridgeAcknowledgesThreatBeforeEmittingUpdates() throws {
        let bridge = ARDemoRuntimeBridge()
        _ = try bridge.start()
        bridge.markCompanionPlaced()
        bridge.acknowledgeRenderedFrame()
        _ = bridge.advance()
        bridge.acknowledgeRenderedFrame()
        _ = bridge.advance()
        bridge.acknowledgeRenderedFrame()
        guard let distant = bridge.advance(),
              case .spawnThreat = distant.commands.last else {
            return XCTFail("Expected initial threat spawn")
        }

        bridge.markThreatPlaced()
        bridge.acknowledgeRenderedFrame()
        guard let pursuit = bridge.advance(),
              case .updateThreat = pursuit.commands.last else {
            return XCTFail("Expected in-place threat update")
        }
    }

    func testFinalFrameDoesNotEndSessionUntilRenderingIsAcknowledged() throws {
        let bridge = ARDemoRuntimeBridge()
        _ = try bridge.start()
        bridge.markCompanionPlaced()
        bridge.acknowledgeRenderedFrame()

        var finalFrame: ARDemoFrame?
        for _ in 0..<bridge.totalTicks {
            guard let frame = bridge.advance() else {
                return XCTFail("Expected every canonical frame")
            }
            finalFrame = frame
            if !frame.isComplete {
                bridge.acknowledgeRenderedFrame()
            }
        }

        guard let finalFrame else { return XCTFail("Expected final frame") }
        XCTAssertTrue(finalFrame.isComplete)
        XCTAssertTrue(bridge.isRunning)
        XCTAssertNotNil(bridge.controller.movementEngine.currentSession)

        guard let retry = bridge.advance() else {
            return XCTFail("Expected the unacknowledged final frame to retry")
        }
        XCTAssertEqual(retry.tickIndex, finalFrame.tickIndex)
        XCTAssertEqual(retry.eventKind, finalFrame.eventKind)
        XCTAssertTrue(bridge.isRunning)

        bridge.acknowledgeRenderedFrame()
        XCTAssertFalse(bridge.isRunning)
        XCTAssertNil(bridge.controller.movementEngine.currentSession)
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
