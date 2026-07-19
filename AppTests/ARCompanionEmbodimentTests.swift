import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class ARCompanionEmbodimentTests: XCTestCase {
    func testVisualConfigurationClampsUnsafeValues() {
        let configuration = CompanionVisualConfiguration(
            companionHeightMeters: 20,
            groundOffsetMeters: -4,
            glowIntensity: .infinity
        )

        XCTAssertEqual(configuration.companionHeightMeters, 1.5)
        XCTAssertEqual(configuration.groundOffsetMeters, 0)
        XCTAssertEqual(configuration.glowIntensity, 1)
    }

    func testFactoryProducesStableSemanticHierarchy() {
        let entity = CompanionEntityFactory().makeLira()

        XCTAssertEqual(entity.name, CompanionEntityFactory.rootName)
        for name in [
            "Body", "Head", "LeftEar", "RightEar", "Tail",
            "CoreGlow", "GroundShadow", "StatusIndicator"
        ] {
            XCTAssertNotNil(entity.findEntity(named: name), "Missing \(name)")
        }
    }

    func testFactoryProducesIndependentEntities() {
        let factory = CompanionEntityFactory()
        let first = factory.makeLira()
        let second = factory.makeLira()

        XCTAssertFalse(first === second)
        XCTAssertNil(first.parent)
        XCTAssertNil(second.parent)
    }

    func testReducerMapsKnownAndUnknownBehaviorsDeterministically() {
        XCTAssertEqual(CompanionStateReducer.state(for: "follow"), .follow)
        XCTAssertEqual(CompanionStateReducer.state(for: "observe"), .investigate)
        XCTAssertEqual(CompanionStateReducer.state(for: "threat"), .alert)
        XCTAssertEqual(CompanionStateReducer.state(for: "bondMoment"), .celebrate)
        XCTAssertEqual(CompanionStateReducer.state(for: "unknown"), .idle)
    }

    func testEveryPresentationStateIsReachableThroughRendererInStableOrder() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        registerCompanion(in: registry)

        XCTAssertEqual(
            CompanionPresentationState.deterministicOrder,
            [.idle, .follow, .investigate, .alert, .celebrate]
        )
        XCTAssertEqual(renderer.companionState, .idle)

        for state in CompanionPresentationState.deterministicOrder.dropFirst() {
            XCTAssertEqual(
                renderer.setCompanionState(state),
                .accepted("companion:\(state.rawValue)")
            )
            XCTAssertEqual(renderer.companionState, state)
        }

        XCTAssertEqual(
            diagnostics.summary.stateTransitions,
            CompanionPresentationState.deterministicOrder.dropFirst().map(\.rawValue)
        )
    }

    func testEveryStateAppliesBoundedAbsoluteRealityKitPresentation() throws {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        let anchor = registerCompanion(in: registry)
        let companion = try XCTUnwrap(
            anchor.findEntity(named: CompanionEntityFactory.rootName)
        )
        let expected: [(CompanionPresentationState, SIMD3<Float>, SIMD3<Float>, Bool)] = [
            (.idle, [0, 0, 0], [1, 1, 1], false),
            (.follow, [0, 0, 0.12], [1.02, 1.02, 1.02], false),
            (.investigate, [-0.08, 0, 0], [1, 0.92, 1.08], true),
            (.alert, [0, 0, -0.10], [1.05, 1.14, 0.96], true),
            (.celebrate, [0, 0.10, 0], [1.12, 1.12, 1.12], true),
        ]

        for (state, position, scale, indicatorVisible) in expected {
            _ = renderer.setCompanionState(state)
            XCTAssertEqual(companion.position, position)
            XCTAssertEqual(companion.scale, scale)
            XCTAssertEqual(
                companion.findEntity(named: "StatusIndicator")?.isEnabled,
                indicatorVisible
            )
            XCTAssertLessThanOrEqual(simd_length(companion.position), 0.12)
            XCTAssertLessThanOrEqual(max(scale.x, max(scale.y, scale.z)), 1.14)
        }
    }

    func testUnknownPresentationInputFallsBackToIdle() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        registerCompanion(in: registry)

        let fallback = CompanionStateReducer.state(for: "future-unrecognized-state")

        XCTAssertEqual(fallback, .idle)
        XCTAssertEqual(renderer.setCompanionState(fallback), .accepted("companion:idle"))
        XCTAssertEqual(renderer.companionState, .idle)
    }

    func testCelebrateReturnsToIdleAfterBoundedDuration() {
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(
                current: .celebrate,
                requested: .celebrate,
                elapsed: 1.499
            ),
            .celebrate
        )
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(
                current: .celebrate,
                requested: .celebrate,
                elapsed: 1.5
            ),
            .idle
        )
    }

    func testRepeatedCompanionRegistrationRemainsBoundedAndReplacesPriorEntity() {
        let registry = AREntityRegistry()
        let sceneRoot = Entity()
        let first = registerCompanion(in: registry, parent: sceneRoot)
        let second = registerCompanion(in: registry, parent: sceneRoot)

        XCTAssertEqual(registry.count, 1)
        XCTAssertNil(first.parent)
        XCTAssertTrue(registry.entity(for: ARWorldCommandRenderer.companionID) === second)
        XCTAssertTrue(second.parent === sceneRoot)
    }

    func testClearResetsPresentationStateEntitiesAndDiagnosticsOutcome() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        registerCompanion(in: registry)
        XCTAssertEqual(renderer.setCompanionState(.alert), .accepted("companion:alert"))

        XCTAssertEqual(renderer.clearSession(), .cleared)

        XCTAssertEqual(renderer.companionState, .idle)
        XCTAssertEqual(registry.count, 0)
        XCTAssertTrue(diagnostics.summary.cleanupSucceeded)
        XCTAssertEqual(diagnostics.events.last?.kind, .sessionCleared)
    }

    func testInjectedUpdatesOnlyRecordSemanticTransitions() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        registerCompanion(in: registry)

        XCTAssertEqual(renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .celebrate)
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .celebrate)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate"])

        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .idle)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate", "idle"])
        XCTAssertNil(renderer.advanceCompanionPresentation(by: 1))
    }

    func testRepeatedCelebrateDoesNotRestartDeadlineOrDuplicateDiagnostics() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        registerCompanion(in: registry)

        XCTAssertEqual(renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        _ = renderer.advanceCompanionPresentation(by: 1)
        XCTAssertEqual(renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        XCTAssertEqual(renderer.lastCompanionTransition?.outcome, .celebrationInProgress)
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .idle)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate", "idle"])
    }

    func testInvalidInjectedDeltaNormalizesCelebrationToIdle() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        registerCompanion(in: registry)

        _ = renderer.setCompanionState(.celebrate)
        let transition = renderer.advanceCompanionPresentation(by: -0.1)

        XCTAssertEqual(transition?.outcome, .invalidElapsedNormalizedToIdle)
        XCTAssertEqual(renderer.companionState, .idle)
    }

    func testARLabDeferredStateAndDetachedClearStaySynchronized() {
        let runtime = ARCompanionLabRuntime()

        runtime.setState(.alert)
        XCTAssertEqual(runtime.currentState, .idle)
        XCTAssertEqual(runtime.transitionResult, "Deferred: companion missing")

        runtime.clear()
        XCTAssertEqual(runtime.currentState, .idle)
        XCTAssertEqual(runtime.transitionResult, "Cleared to idle")
        XCTAssertEqual(runtime.registryCount, 0)
    }

    func testPresentationTransitionsDoNotMutateGameplayCompanion() {
        let companionID = UUID()
        let sessionID = UUID()
        let gameplayCompanion = Companion(
            id: companionID,
            name: "Lira",
            archetype: "waykin",
            bondLevel: 12,
            lastSessionID: sessionID,
            memories: []
        )
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        registerCompanion(in: registry)

        for state in CompanionPresentationState.allCases {
            _ = renderer.setCompanionState(state)
        }

        XCTAssertEqual(gameplayCompanion.id, companionID)
        XCTAssertEqual(gameplayCompanion.name, "Lira")
        XCTAssertEqual(gameplayCompanion.archetype, "waykin")
        XCTAssertEqual(gameplayCompanion.bondLevel, 12)
        XCTAssertEqual(gameplayCompanion.lastSessionID, sessionID)
        XCTAssertTrue(gameplayCompanion.memories.isEmpty)
    }

    func testDiagnosticsBuildPrivacyFilteredSummary() throws {
        let recorder = ARDiagnosticRecorder()
        recorder.record(.sessionStarted)
        recorder.record(.trackingNormal)
        recorder.record(.entityCreated, detail: "companion")
        recorder.record(.stateChanged, detail: "idle")
        recorder.record(.entityReplaced, detail: "companion")
        recorder.record(.sessionCleared)

        let receipt = recorder.summary
        XCTAssertTrue(receipt.sessionStarted)
        XCTAssertTrue(receipt.trackingNormalReached)
        XCTAssertTrue(receipt.companionPlaced)
        XCTAssertEqual(receipt.replacementCount, 1)
        XCTAssertEqual(receipt.stateTransitions, ["idle"])
        XCTAssertTrue(receipt.cleanupSucceeded)

        let encoded = try JSONEncoder().encode(receipt)
        let text = String(decoding: encoded, as: UTF8.self)
        XCTAssertFalse(text.localizedCaseInsensitiveContains("latitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("longitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("image"))
    }

    @discardableResult
    private func registerCompanion(
        in registry: AREntityRegistry,
        parent: Entity? = nil
    ) -> Entity {
        let anchor = Entity()
        anchor.addChild(CompanionEntityFactory().makeLira())
        parent?.addChild(anchor)
        registry.register(anchor, for: ARWorldCommandRenderer.companionID)
        return anchor
    }
}
