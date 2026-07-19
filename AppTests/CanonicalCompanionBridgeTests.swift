import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

/// WAYKIN-42: canonical runtime -> ARWorldCommand -> merged renderer.
/// Focused coverage: mapping, ordering, repeated updates, cleanup, and
/// non-mutation of gameplay values.
@MainActor
final class CanonicalCompanionBridgeTests: XCTestCase {

    private func makeStack() -> (bridge: CanonicalCompanionARBridge,
                                 renderer: ARWorldCommandRenderer,
                                 registry: AREntityRegistry,
                                 diagnostics: ARDiagnosticRecorder,
                                 arView: ARView) {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        let bridge = CanonicalCompanionARBridge(renderer: renderer, registry: registry)
        return (bridge, renderer, registry, diagnostics, ARView(frame: .zero))
    }

    /// Unit tests have no camera, so raycast placement always defers. This
    /// stands Lira up the same way the renderer's own tests do, letting the
    /// bridge exercise its update path.
    private func placeLira(in registry: AREntityRegistry) {
        let anchor = Entity()
        anchor.addChild(CompanionEntityFactory().makeLira())
        registry.register(anchor, for: ARWorldCommandRenderer.companionID)
    }

    private func makeRuntime(_ state: CompanionBehaviorState,
                             distance: Double = 2.5) -> CompanionRuntime {
        var runtime = CompanionRuntime()
        runtime.apply(command: .setBehavior(state.rawValue))
        runtime.apply(command: .setRelativeDistance(distance))
        return runtime
    }

    private func makeEvent(_ kind: WorldEventKind) -> WorldEvent {
        WorldEvent(kind: kind, occurredAt: Date(timeIntervalSince1970: 1_800_000_000),
                   intensity: 0.5, debugLabel: kind.rawValue)
    }

    // MARK: Mapping

    func testEveryCanonicalStateProjectsIntoNativePresentationVocabulary() {
        let expected: [CompanionBehaviorState: CompanionPresentationState] = [
            .idle: .idle,
            .rest: .idle,
            .follow: .follow,
            .drawNear: .follow,
            .lead: .follow,
            .observe: .investigate,
            .celebrate: .celebrate,
        ]
        XCTAssertEqual(expected.count, 7, "cover the full canonical vocabulary")

        for (canonical, presentation) in expected {
            let behavior = CanonicalCompanionARBridge.presentationBehavior(for: canonical)
            XCTAssertEqual(behavior, presentation.rawValue)
            // Deliberate mappings, never the unknown-input fallback: the
            // reducer must recognize each projected string natively.
            let transition = CompanionStateReducer.transition(
                current: .alert, behavior: behavior, elapsed: 0)
            XCTAssertNotEqual(transition.outcome, .normalizedUnknownToIdle,
                              "canonical \(canonical.rawValue) leaked into unknown-fallback")
        }
        // The fallback itself stays intact for genuinely unknown inputs.
        XCTAssertEqual(
            CompanionStateReducer.transition(current: .idle, behavior: "warpspeed", elapsed: 0).outcome,
            .normalizedUnknownToIdle)
    }

    func testPursuitAndBondEventsOverrideCompanionStateForPresentationOnly() {
        for kind in [WorldEventKind.pursuitBegins, .pursuitIntensifies] {
            XCTAssertEqual(
                CanonicalCompanionARBridge.presentationBehavior(for: .follow, lastEvent: kind),
                CompanionPresentationState.alert.rawValue)
        }
        XCTAssertEqual(
            CanonicalCompanionARBridge.presentationBehavior(for: .drawNear, lastEvent: .bondMoment),
            CompanionPresentationState.celebrate.rawValue)
        // Every other event kind defers to the companion state.
        for kind in [WorldEventKind.companionDrawsNear, .companionMovesAhead, .companionObserves,
                     .distantPresence, .pursuitFades, .familiarPlaceStirs, .quietInterval] {
            XCTAssertEqual(
                CanonicalCompanionARBridge.presentationBehavior(for: .observe, lastEvent: kind),
                CompanionPresentationState.investigate.rawValue)
        }
    }

    func testDistanceBandProjectionIsTotalAndBounded() {
        XCTAssertEqual(CanonicalCompanionARBridge.distanceBand(forRelativeDistance: 0.4), .immediate)
        XCTAssertEqual(CanonicalCompanionARBridge.distanceBand(forRelativeDistance: 1.2), .near)
        XCTAssertEqual(CanonicalCompanionARBridge.distanceBand(forRelativeDistance: 2.5), .medium)
        XCTAssertEqual(CanonicalCompanionARBridge.distanceBand(forRelativeDistance: 8), .far)
        XCTAssertEqual(CanonicalCompanionARBridge.distanceBand(forRelativeDistance: .nan), .near)
        XCTAssertEqual(CanonicalCompanionARBridge.distanceBand(forRelativeDistance: .infinity), .far)
    }

    // MARK: Routing, identity, repeated updates

    func testSyncSpawnsWhenAbsentUpdatesWhenPlacedAndKeepsOneLira() {
        let stack = makeStack()

        // No placed Lira: the bridge emits spawnCompanion; with no camera
        // the raycast defers, and the bridge simply retries next sync.
        let first = stack.bridge.sync(companion: makeRuntime(.follow), in: stack.arView)
        XCTAssertEqual(first, .deferred("companion"))
        if case .spawnCompanion(let presentation)? = stack.bridge.lastCommand {
            XCTAssertEqual(presentation.id, CanonicalCompanionARBridge.liraPresentationID)
            XCTAssertEqual(presentation.name, "Lira")
        } else {
            XCTFail("expected spawnCompanion, got \(String(describing: stack.bridge.lastCommand))")
        }
        XCTAssertEqual(stack.registry.count, 0)

        // Once Lira is placed, syncs route through updateCompanion.
        placeLira(in: stack.registry)
        for state in [CompanionBehaviorState.observe, .lead, .rest] {
            let result = stack.bridge.sync(companion: makeRuntime(state), in: stack.arView)
            guard case .accepted = result else {
                return XCTFail("update should be accepted, got \(result)")
            }
            if case .updateCompanion? = stack.bridge.lastCommand {} else {
                XCTFail("expected updateCompanion, got \(String(describing: stack.bridge.lastCommand))")
            }
            XCTAssertEqual(stack.registry.count, 1, "one Lira identity, always")
        }
        XCTAssertEqual(stack.renderer.companionState, .idle) // rest -> idle
    }

    func testRepeatedIdenticalSyncsDoNotDuplicateTransitions() {
        let stack = makeStack()
        placeLira(in: stack.registry)

        for _ in 0..<3 {
            _ = stack.bridge.sync(companion: makeRuntime(.follow), in: stack.arView)
        }
        let transitions = stack.diagnostics.summary.stateTransitions
        XCTAssertEqual(transitions, ["follow"],
                       "identical repeated syncs must record one semantic transition")
        XCTAssertEqual(stack.registry.count, 1)
    }

    func testBridgedCelebrationCompletesThroughExistingTiming() {
        let stack = makeStack()
        placeLira(in: stack.registry)

        _ = stack.bridge.sync(companion: makeRuntime(.drawNear),
                              lastEvent: makeEvent(.bondMoment),
                              in: stack.arView)
        XCTAssertEqual(stack.renderer.companionState, .celebrate)

        // The merged renderer's own deterministic timing finishes it.
        let done = stack.renderer.advanceCompanionPresentation(by: 1.6)
        XCTAssertEqual(done?.outcome, .celebrationCompleted)
        XCTAssertEqual(stack.renderer.companionState, .idle)
    }

    // MARK: Ordering

    func testIdenticalCanonicalSequencesProduceIdenticalCommandsAndReceipts() {
        func run() -> (commands: [ARWorldCommand], transitions: [String]) {
            let stack = makeStack()
            placeLira(in: stack.registry)
            var commands: [ARWorldCommand] = []
            let script: [(CompanionBehaviorState, WorldEventKind?, Double)] = [
                (.follow, nil, 2.5),
                (.observe, .companionObserves, 2.5),
                (.follow, .pursuitBegins, 1.8),
                (.drawNear, .bondMoment, 1.2),
                (.rest, nil, 3.0),
            ]
            for (state, kind, distance) in script {
                _ = stack.bridge.sync(companion: makeRuntime(state, distance: distance),
                                      lastEvent: kind.map(makeEvent),
                                      in: stack.arView)
                if let command = stack.bridge.lastCommand { commands.append(command) }
            }
            return (commands, stack.diagnostics.summary.stateTransitions)
        }

        let first = run()
        let second = run()
        XCTAssertEqual(first.commands, second.commands)
        XCTAssertEqual(first.transitions, second.transitions)
        XCTAssertEqual(first.transitions, ["follow", "investigate", "alert", "celebrate", "idle"])
    }

    // MARK: Cleanup

    func testClearRoutesThroughRendererAndNextSyncRespawns() {
        let stack = makeStack()
        placeLira(in: stack.registry)
        _ = stack.bridge.sync(companion: makeRuntime(.celebrate), in: stack.arView)

        XCTAssertEqual(stack.bridge.clear(), .cleared)
        XCTAssertEqual(stack.registry.count, 0)
        XCTAssertEqual(stack.renderer.companionState, .idle)
        XCTAssertNil(stack.renderer.lastCompanionTransition)

        _ = stack.bridge.sync(companion: makeRuntime(.follow), in: stack.arView)
        if case .spawnCompanion? = stack.bridge.lastCommand {} else {
            XCTFail("after clear the bridge must respawn, got \(String(describing: stack.bridge.lastCommand))")
        }
    }

    // MARK: Gameplay non-mutation

    func testBridgeNeverMutatesCanonicalGameplayValues() {
        let stack = makeStack()
        placeLira(in: stack.registry)

        let runtime = makeRuntime(.follow, distance: 1.8)
        let stateBefore = runtime.state
        let distanceBefore = runtime.relativeDistance
        let event = makeEvent(.pursuitIntensifies)

        for _ in 0..<5 {
            _ = stack.bridge.sync(companion: runtime, lastEvent: event, in: stack.arView)
        }
        _ = stack.bridge.clear()

        XCTAssertEqual(runtime.state, stateBefore)
        XCTAssertEqual(runtime.relativeDistance, distanceBefore)
        XCTAssertEqual(event.kind, .pursuitIntensifies)
        XCTAssertEqual(event.intensity, 0.5)
    }
}
