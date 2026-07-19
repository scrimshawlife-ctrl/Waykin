import CoreLocation
import RealityKit
import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class CanonicalARRuntimeIntegrationTests: XCTestCase {
    private let companionID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let eventDate = Date(timeIntervalSince1970: 1_234)

    func testDemoArcProjectsStableIdentityAndOrderedCanonicalStates() throws {
        let controller = DemoSessionController(movementEngine: MovementEngine())
        let mapper = makeMapper()
        try controller.start(scenarioID: .calmDayWalk)

        var batches = [mapper.spawn(companionRuntime: controller.companionRuntime)]
        while let scenario = controller.currentScenario,
              controller.tickIndex < scenario.ticks.count {
            controller.advanceOneTick()
            batches.append(mapper.update(
                companionRuntime: controller.companionRuntime,
                event: controller.currentEvent
            ))
        }

        XCTAssertEqual(batches.count, 8)
        XCTAssertEqual(
            batches.compactMap { companionPresentation(in: $0)?.behavior },
            ["follow", "investigate", "follow", "investigate", "alert", "alert", "follow", "celebrate"]
        )
        XCTAssertTrue(batches.allSatisfy {
            companionPresentation(in: $0)?.id == companionID
                && companionPresentation(in: $0)?.name == "Lira"
        })
        XCTAssertEqual(batches.map(eventCommandKinds), [
            [],
            ["removeDiscovery"],
            ["removeDiscovery"],
            ["discovery"],
            ["removeDiscovery", "spawnThreat"],
            ["removeDiscovery", "updateThreat"],
            ["removeDiscovery", "removeThreat"],
            ["removeDiscovery"]
        ])
    }

    func testIdenticalCanonicalInputsProduceIdenticalCommands() {
        var runtime = CompanionRuntime()
        let event = makeEvent(.pursuitIntensifies, intensity: 0.8)
        runtime.apply(event: event)
        let mapper = makeMapper()

        let first = mapper.update(companionRuntime: runtime, event: event)
        let second = mapper.update(companionRuntime: runtime, event: event)

        XCTAssertEqual(first, second)
    }

    func testEventMappingUsesBoundedStableEventIdentities() throws {
        let mapper = makeMapper()
        var runtime = CompanionRuntime()

        let discovery = makeEvent(.distantPresence, intensity: 0.4)
        runtime.apply(event: discovery)
        let discoveryCommands = mapper.update(companionRuntime: runtime, event: discovery)
        guard case .spawnDiscovery(let discoveryPresentation) = try XCTUnwrap(discoveryCommands.last) else {
            return XCTFail("Expected discovery command")
        }
        XCTAssertEqual(discoveryPresentation.id, CanonicalARWorldCommandMapper.discoveryID)

        let threat = makeEvent(.pursuitBegins, intensity: 3)
        runtime.apply(event: threat)
        let threatCommands = mapper.update(companionRuntime: runtime, event: threat)
        guard case .spawnThreat(let threatPresentation) = try XCTUnwrap(threatCommands.last) else {
            return XCTFail("Expected threat command")
        }
        XCTAssertEqual(threatPresentation.id, CanonicalARWorldCommandMapper.threatID)
        XCTAssertEqual(threatPresentation.intensity, 1)

        let fade = makeEvent(.pursuitFades)
        runtime.apply(event: fade)
        XCTAssertEqual(
            mapper.update(companionRuntime: runtime, event: fade).last,
            .removeEntity(CanonicalARWorldCommandMapper.threatID)
        )
    }

    func testLateSnapshotRestoresAnActivePursuitWithStableIdentity() throws {
        let mapper = makeMapper()
        var runtime = CompanionRuntime()
        let event = makeEvent(.pursuitBegins, intensity: 0.7)
        runtime.apply(event: event)

        let commands = mapper.snapshot(
            companionRuntime: runtime,
            pursuitState: .approaching,
            lastEvent: event
        )

        XCTAssertEqual(commands.count, 2)
        guard case .spawnThreat(let threat) = try XCTUnwrap(commands.last) else {
            return XCTFail("Expected active pursuit threat")
        }
        XCTAssertEqual(threat.id, CanonicalARWorldCommandMapper.threatID)
        XCTAssertEqual(threat.intensity, 0.7)
    }

    func testLateSnapshotKeepsNoticedAsDiscoveryAndRejectsUnrelatedThreatMetadata() throws {
        let mapper = makeMapper()
        var runtime = CompanionRuntime()
        let distant = makeEvent(.distantPresence, intensity: 0.4)
        runtime.apply(event: distant)

        let noticed = mapper.snapshot(
            companionRuntime: runtime,
            pursuitState: .noticed,
            lastEvent: distant
        )
        let continuous = mapper.update(companionRuntime: runtime, event: distant)

        XCTAssertEqual(noticed.count, 2)
        guard case .spawnDiscovery(let restored) = try XCTUnwrap(noticed.last),
              case .spawnDiscovery(let projected) = try XCTUnwrap(continuous.last) else {
            return XCTFail("Expected matching discovery projections")
        }
        XCTAssertEqual(restored, projected)

        let unrelated = makeEvent(.bondMoment, intensity: 0.99)
        let approaching = mapper.snapshot(
            companionRuntime: runtime,
            pursuitState: .approaching,
            lastEvent: unrelated
        )
        guard case .spawnThreat(let threat) = try XCTUnwrap(approaching.last) else {
            return XCTFail("Expected restored pursuit threat")
        }
        XCTAssertEqual(threat.kind, WorldEventKind.pursuitBegins.rawValue)
        XCTAssertEqual(threat.intensity, 0.65)
    }

    func testTransientDiscoveryIsRemovedBeforeTheNextProjection() {
        let mapper = makeMapper()
        var runtime = CompanionRuntime()
        let discovery = makeEvent(.distantPresence)
        runtime.apply(event: discovery)

        XCTAssertEqual(eventCommandKinds(in: mapper.update(companionRuntime: runtime, event: discovery)), ["discovery"])
        XCTAssertEqual(eventCommandKinds(in: mapper.update(companionRuntime: runtime, event: nil)), ["removeDiscovery"])

        let pursuit = makeEvent(.pursuitBegins)
        runtime.apply(event: pursuit)
        XCTAssertEqual(
            eventCommandKinds(in: mapper.update(companionRuntime: runtime, event: pursuit)),
            ["removeDiscovery", "spawnThreat"]
        )
    }

    func testAppModelProjectionDoesNotChangeCanonicalGameplayOutcome() throws {
        let model = try makeAppModel()
        let baseline = try makeAppModel()
        let originalCompanion = model.companion
        var deliveredBatches: [[ARWorldCommand]] = []
        let owner = model.attachARWorldCommandHandler { deliveredBatches.append($0) }

        model.startDemo(.calmDayWalk)
        baseline.startDemo(.calmDayWalk)
        guard case .spawnCompanion(let spawn) = try XCTUnwrap(deliveredBatches.first?.first) else {
            return XCTFail("Expected companion spawn")
        }
        XCTAssertEqual(spawn.id, originalCompanion.id)
        XCTAssertEqual(spawn.name, originalCompanion.name)

        model.runDemoToEnd()
        baseline.runDemoToEnd()
        XCTAssertEqual(deliveredBatches.count, 8)
        XCTAssertEqual(
            deliveredBatches.compactMap { companionPresentation(in: $0)?.behavior },
            ["follow", "investigate", "follow", "investigate", "alert", "alert", "follow", "celebrate"]
        )
        XCTAssertEqual(model.companion.id, originalCompanion.id)
        XCTAssertEqual(model.companion.bondLevel, originalCompanion.bondLevel)
        XCTAssertEqual(model.movementEngine.currentSession?.experienceID, "companion_walk")
        XCTAssertEqual(model.demoController.companionRuntime.state, baseline.demoController.companionRuntime.state)
        XCTAssertEqual(
            model.demoController.companionRuntime.relativeDistance,
            baseline.demoController.companionRuntime.relativeDistance
        )
        XCTAssertEqual(
            model.demoController.companionWalkState?.accumulatedBondProgress,
            baseline.demoController.companionWalkState?.accumulatedBondProgress
        )
        XCTAssertEqual(
            model.demoController.companionWalkState?.movementSeconds,
            baseline.demoController.companionWalkState?.movementSeconds
        )
        XCTAssertEqual(
            model.demoController.companionWalkState?.pursuitState,
            baseline.demoController.companionWalkState?.pursuitState
        )
        XCTAssertEqual(
            model.demoController.companionWalkState?.eventHistory.map(\.kind),
            baseline.demoController.companionWalkState?.eventHistory.map(\.kind)
        )
        XCTAssertEqual(
            model.demoController.companionWalkState?.activeAudioCues.map(\.kind),
            baseline.demoController.companionWalkState?.activeAudioCues.map(\.kind)
        )
        XCTAssertEqual(
            model.movementEngine.currentSession?.distanceMeters,
            baseline.movementEngine.currentSession?.distanceMeters
        )

        model.endDemo()
        baseline.endDemo()
        XCTAssertEqual(deliveredBatches.last, [.clearSession])
        XCTAssertEqual(model.companion.bondLevel, baseline.companion.bondLevel)
        XCTAssertEqual(model.lastSummary?.outcome, baseline.lastSummary?.outcome)
        XCTAssertEqual(model.lastSummary?.memory.text, baseline.lastSummary?.memory.text)
        model.detachARWorldCommandHandler(owner: owner)
    }

    func testOrderedBatchUsesExistingRendererAndClearRemovesPresentation() throws {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        let anchor = Entity()
        anchor.addChild(CompanionEntityFactory().makeLira())
        registry.register(anchor, for: ARWorldCommandRenderer.companionID)

        var runtime = CompanionRuntime()
        let threatAnchor = Entity()
        registry.register(threatAnchor, for: CanonicalARWorldCommandMapper.threatID.uuidString)
        let event = makeEvent(.pursuitFades)
        runtime.apply(event: event)
        let mapper = makeMapper()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)

        XCTAssertEqual(
            renderer.render(mapper.update(companionRuntime: runtime, event: event), in: arView),
            [
                .accepted("companion:follow"),
                .removed(CanonicalARWorldCommandMapper.discoveryID.uuidString),
                .removed(CanonicalARWorldCommandMapper.threatID.uuidString)
            ]
        )
        XCTAssertEqual(renderer.companionState, .follow)
        XCTAssertEqual(registry.count, 1)
        _ = renderer.render(mapper.update(companionRuntime: runtime, event: event), in: arView)
        XCTAssertEqual(registry.count, 1)
        XCTAssertEqual(renderer.render(mapper.clear(), in: arView), [.cleared])
        XCTAssertEqual(registry.count, 0)
        XCTAssertEqual(renderer.companionState, .idle)
    }

    func testProductionHostReceivesClearSynchronouslyBeforeDetach() throws {
        let model = try makeAppModel()
        model.startDemo(.calmDayWalk)
        let runtime = CanonicalARSessionRuntime()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        runtime.attach(arView, appModel: model)

        model.endDemo()

        XCTAssertEqual(runtime.lastResult, "Session cleared")
        XCTAssertEqual(runtime.companionState, .idle)
        runtime.detach(arView, appModel: model)
    }

    func testProductionHostLateAttachQueuesCompanionBeforeActiveThreat() throws {
        let model = try makeAppModel()
        model.startDemo(.calmDayWalk)
        for _ in 0..<4 {
            model.advanceDemo()
        }
        let runtime = CanonicalARSessionRuntime()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)

        runtime.attach(arView, appModel: model)

        XCTAssertEqual(runtime.pendingCommandSnapshot.count, 2)
        guard case .spawnCompanion = runtime.pendingCommandSnapshot[0],
              case .spawnThreat(let threat) = runtime.pendingCommandSnapshot[1] else {
            return XCTFail("Expected companion then active threat")
        }
        XCTAssertEqual(threat.id, CanonicalARWorldCommandMapper.threatID)
        model.endDemo()
        XCTAssertTrue(runtime.pendingCommandSnapshot.isEmpty)
        runtime.detach(arView, appModel: model)
    }

    func testDeferredHostCoalescesToABoundedLatestProjectionAndClearPreemptsIt() throws {
        let model = try makeAppModel()
        let runtime = CanonicalARSessionRuntime()
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let mapper = makeMapper()
        var companionRuntime = CompanionRuntime()
        runtime.attach(arView, appModel: model)

        for index in 0..<200 {
            let event: WorldEvent = index.isMultiple(of: 2)
                ? makeEvent(.pursuitBegins, intensity: Double(index) / 200)
                : makeEvent(.pursuitIntensifies, intensity: Double(index) / 200)
            companionRuntime.apply(event: event)
            runtime.receive(mapper.update(companionRuntime: companionRuntime, event: event))
            XCTAssertLessThanOrEqual(runtime.pendingCommandSnapshot.count, 3)
        }

        XCTAssertEqual(eventCommandKinds(in: runtime.pendingCommandSnapshot), ["removeDiscovery", "updateThreat"])
        guard case .updateCompanion(let latestCompanion) = runtime.pendingCommandSnapshot.first else {
            return XCTFail("Expected latest companion projection first")
        }
        XCTAssertEqual(latestCompanion.behavior, "alert")

        runtime.receive([.clearSession])
        XCTAssertTrue(runtime.pendingCommandSnapshot.isEmpty)
        XCTAssertEqual(runtime.lastResult, "Session cleared")
        runtime.detach(arView, appModel: model)
    }

    func testDeferredHostDrainsOnlyLatestStableProjectionsInOrder() throws {
        let model = try makeAppModel()
        var acceptsCommands = false
        var renderedCommands: [ARWorldCommand] = []
        let runtime = CanonicalARSessionRuntime { command, _ in
            renderedCommands.append(command)
            return acceptsCommands ? .accepted("test") : .deferred("test")
        }
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let mapper = makeMapper()
        var companionRuntime = CompanionRuntime()
        runtime.attach(arView, appModel: model)

        runtime.receive(mapper.spawn(companionRuntime: companionRuntime))
        let discovery = makeEvent(.distantPresence)
        companionRuntime.apply(event: discovery)
        runtime.receive(mapper.update(companionRuntime: companionRuntime, event: discovery))
        let threat = makeEvent(.pursuitIntensifies)
        companionRuntime.apply(event: threat)
        runtime.receive(mapper.update(companionRuntime: companionRuntime, event: threat))

        let retainedProjection = runtime.pendingCommandSnapshot
        XCTAssertEqual(retainedProjection.count, 4)
        XCTAssertEqual(
            eventCommandKinds(in: Array(retainedProjection.dropFirst())),
            ["removeDiscovery", "updateThreat"]
        )

        renderedCommands.removeAll()
        acceptsCommands = true
        runtime.receive([])

        XCTAssertEqual(renderedCommands, retainedProjection)
        XCTAssertTrue(runtime.pendingCommandSnapshot.isEmpty)
        runtime.detach(arView, appModel: model)
    }

    func testStaleHandlerOwnerCannotDetachTheCurrentHost() throws {
        let model = try makeAppModel()
        var firstBatches: [[ARWorldCommand]] = []
        var secondBatches: [[ARWorldCommand]] = []
        model.startDemo(.calmDayWalk)
        let firstOwner = model.attachARWorldCommandHandler { firstBatches.append($0) }
        let secondOwner = model.attachARWorldCommandHandler { secondBatches.append($0) }

        model.detachARWorldCommandHandler(owner: firstOwner)
        model.endDemo()

        XCTAssertNotEqual(firstBatches.last, [.clearSession])
        XCTAssertEqual(secondBatches.last, [.clearSession])
        model.detachARWorldCommandHandler(owner: secondOwner)
    }

    private func makeMapper() -> CanonicalARWorldCommandMapper {
        CanonicalARWorldCommandMapper(companionID: companionID, companionName: "Lira")
    }

    private func makeEvent(_ kind: WorldEventKind, intensity: Double = 0.6) -> WorldEvent {
        WorldEvent(kind: kind, occurredAt: eventDate, intensity: intensity, debugLabel: kind.rawValue)
    }

    private func companionPresentation(in commands: [ARWorldCommand]) -> CompanionPresentation? {
        guard let first = commands.first else { return nil }
        switch first {
        case .spawnCompanion(let presentation), .updateCompanion(let presentation):
            return presentation
        default:
            return nil
        }
    }

    private func eventCommandKinds(in commands: [ARWorldCommand]) -> [String] {
        commands.dropFirst().map { command in
            switch command {
            case .spawnDiscovery: return "discovery"
            case .spawnThreat: return "spawnThreat"
            case .updateThreat: return "updateThreat"
            case .removeEntity(let id) where id == CanonicalARWorldCommandMapper.discoveryID:
                return "removeDiscovery"
            case .removeEntity(let id) where id == CanonicalARWorldCommandMapper.threatID:
                return "removeThreat"
            default: return "unexpected"
            }
        }
    }

    private func makeAppModel() throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            audioPlayer: SilentAudioPlayer(),
            realLocationProvider: InertLocationProvider(),
            fieldTestReceiptStore: nil
        )
    }
}

private final class InertLocationProvider: RealLocationProviding {
    var onLocationSample: ((LocationSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onSignalStateChange: ((LiveLocationSignalState) -> Void)?
    var authorizationStatus: CLAuthorizationStatus = .denied
    var locationServicesEnabled = true

    func requestAuthorization() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
}

@MainActor
private final class SilentAudioPlayer: AudioCuePlaying {
    func handle(_ cues: [AudioCue]) {}
    func pauseAll() {}
    func resumeAll() {}
    func stopAll(fadeOut: Bool) {}
}
