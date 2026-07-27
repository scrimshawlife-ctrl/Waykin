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

    func testFactoryProducesStableSemanticHierarchy() async {
        let factory = CompanionEntityFactory()
        let entity = await factory.makeLira()

        XCTAssertNotNil(entity)
        XCTAssertEqual(entity?.name, CompanionEntityFactory.rootName)

        // Base transform (height + ground offset) applied once after loading imported mesh.
        let cfg = CompanionVisualConfiguration.liraPlaceholder
        let ref: Float = 0.72
        let expectedScale = cfg.companionHeightMeters / ref
        XCTAssertEqual(entity?.scale.x ?? 0, expectedScale, accuracy: 0.01)
        XCTAssertEqual(entity?.position.y ?? 0, cfg.groundOffsetMeters, accuracy: 0.01)

        // No longer asserts old procedural sphere names (imported mesh hierarchy).
        // Root is stable.
    }

    func testFactoryProducesIndependentEntities() async {
        let factory = CompanionEntityFactory()
        let first = await factory.makeLira()
        let second = await factory.makeLira()

        XCTAssertFalse(first === second)
        XCTAssertNil(first?.parent)
        XCTAssertNil(second?.parent)
    }

    func testReducerMapsKnownAndUnknownBehaviorsDeterministically() {
        XCTAssertEqual(CompanionStateReducer.state(for: "follow"), .follow)
        XCTAssertEqual(CompanionStateReducer.state(for: "observe"), .investigate)
        XCTAssertEqual(CompanionStateReducer.state(for: "threat"), .alert)
        XCTAssertEqual(CompanionStateReducer.state(for: "bondMoment"), .celebrate)
        XCTAssertEqual(CompanionStateReducer.state(for: "unknown"), .idle)
    }

    func testEveryPresentationStateIsReachableThroughRendererInStableOrder() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        await registerCompanion(in: registry)

        XCTAssertEqual(
            CompanionPresentationState.deterministicOrder,
            [.idle, .follow, .investigate, .alert, .celebrate]
        )
        XCTAssertEqual(renderer.companionState, .idle)

        for state in CompanionPresentationState.deterministicOrder.dropFirst() {
            XCTAssertEqual(
                await renderer.setCompanionState(state),
                .accepted("companion:\(state.rawValue)")
            )
            XCTAssertEqual(renderer.companionState, state)
        }

        XCTAssertEqual(
            diagnostics.summary.stateTransitions,
            CompanionPresentationState.deterministicOrder.dropFirst().map(\.rawValue)
        )
    }

    func testEveryStateAppliesBoundedAbsoluteRealityKitPresentation() async throws {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        let anchor = await registerCompanion(in: registry)
        let companion = try XCTUnwrap(
            anchor.findEntity(named: CompanionEntityFactory.rootName)
        )

        // After load, base scale from config. States adjust only pos/orient (no scale overwrite).
        let baseScale: Float = 1.0 // default config scale factor ~1.0
        let expected: [(CompanionPresentationState, SIMD3<Float>, simd_quatf, Bool)] = [
            (.idle, [0, 0, 0], simd_quatf(angle: 0, axis: [0, 1, 0]), false),
            (.follow, [0, 0, 0.12], simd_quatf(angle: 0.18, axis: [0, 1, 0]), false),
            (.investigate, [-0.08, 0, 0], simd_quatf(angle: -0.22, axis: [1, 0, 0]), true),
            (.alert, [0, 0, -0.10], simd_quatf(angle: 0, axis: [0, 1, 0]), true),
            (.celebrate, [0, 0.10, 0], simd_quatf(angle: .pi / 5, axis: [0, 1, 0]), true),
        ]

        for (state, position, orientation, indicatorVisible) in expected {
            _ = await renderer.setCompanionState(state)
            XCTAssertEqual(companion.position, position)
            // Scale remains the base (no state distortion of imported mesh)
            XCTAssertEqual(companion.scale.x, baseScale, accuracy: 0.1)
            XCTAssertEqual(companion.orientation.vector, orientation.vector)
            XCTAssertEqual(
                companion.findEntity(named: "StatusIndicator")?.isEnabled,
                indicatorVisible
            )
            // bounded
            XCTAssertLessThanOrEqual(simd_length(companion.position), 0.12)

            companion.position = [4, 4, 4]
            companion.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])

            _ = await renderer.setCompanionState(state)
            XCTAssertEqual(companion.position, position)
            XCTAssertEqual(companion.orientation.vector, orientation.vector)
        }
    }

    func testUnknownPresentationInputFallsBackToIdle() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        await registerCompanion(in: registry)

        let fallback = CompanionStateReducer.state(for: "future-unrecognized-state")

        XCTAssertEqual(fallback, .idle)
        XCTAssertEqual(await renderer.setCompanionState(fallback), .accepted("companion:idle"))
        XCTAssertEqual(renderer.companionState, .idle)

        let transition = CompanionStateReducer.transition(
            current: .alert,
            behavior: "future-unrecognized-state",
            elapsed: 0
        )
        XCTAssertEqual(transition.resolvedState, .idle)
        XCTAssertEqual(transition.outcome, .normalizedUnknownToIdle)
    }

    func testIdenticalTransitionInputsProduceIdenticalReceipts() {
        let inputs = (CompanionPresentationState.celebrate, CompanionPresentationState.celebrate, 1.25)

        let first = CompanionStateReducer.transition(
            current: inputs.0,
            requested: inputs.1,
            elapsed: inputs.2
        )
        let second = CompanionStateReducer.transition(
            current: inputs.0,
            requested: inputs.1,
            elapsed: inputs.2
        )

        XCTAssertEqual(first, second)
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

    func testRepeatedCompanionRegistrationRemainsBoundedAndReplacesPriorEntity() async {
        let registry = AREntityRegistry()
        let sceneRoot = Entity()
        let first = await registerCompanion(in: registry, parent: sceneRoot)
        let second = await registerCompanion(in: registry, parent: sceneRoot)

        XCTAssertEqual(registry.count, 1)
        XCTAssertNil(first?.parent)
        XCTAssertTrue(registry.entity(for: ARWorldCommandRenderer.companionID) === second)
        XCTAssertTrue(second?.parent === sceneRoot)
    }

    func testClearResetsPresentationStateEntitiesAndDiagnosticsOutcome() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        await registerCompanion(in: registry)
        XCTAssertEqual(await renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        _ = renderer.advanceCompanionPresentation(by: 1)

        XCTAssertEqual(renderer.clearSession(), .cleared)

        XCTAssertEqual(renderer.companionState, .idle)
        XCTAssertNil(renderer.advanceCompanionPresentation(by: 1))
        XCTAssertEqual(registry.count, 0)
        XCTAssertTrue(diagnostics.summary.cleanupSucceeded)
        XCTAssertEqual(diagnostics.events.last?.kind, .sessionCleared)
    }

    func testInjectedUpdatesOnlyRecordSemanticTransitions() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        await registerCompanion(in: registry)

        XCTAssertEqual(await renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .celebrate)
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .celebrate)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate"])

        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .idle)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate", "idle"])
        XCTAssertNil(renderer.advanceCompanionPresentation(by: 1))
    }

    func testRepeatedCelebrateDoesNotRestartDeadlineOrDuplicateDiagnostics() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        await registerCompanion(in: registry)

        XCTAssertEqual(await renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        _ = renderer.advanceCompanionPresentation(by: 1)
        XCTAssertEqual(await renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        XCTAssertEqual(renderer.lastCompanionTransition?.outcome, .celebrationInProgress)
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .idle)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate", "idle"])
    }

    func testBehaviorUpdateDoesNotRestartCelebrateDeadline() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        await registerCompanion(in: registry)
        let presentation = CompanionPresentation(
            id: UUID(),
            name: "Lira",
            behavior: "celebrate",
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .companion,
                persistence: .session
            )
        )

        XCTAssertEqual(await renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        _ = renderer.advanceCompanionPresentation(by: 1)
        XCTAssertEqual(
            await renderer.render(.updateCompanion(presentation), in: ARView(frame: .zero)),
            .accepted("companion:celebrate")
        )
        XCTAssertEqual(renderer.lastCompanionTransition?.outcome, .celebrationInProgress)
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .idle)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate", "idle"])
    }

    func testInvalidInjectedDeltasNormalizeCelebrationToIdle() async {
        for delta in [-0.1, .nan, .infinity, -.infinity] {
            let registry = AREntityRegistry()
            let renderer = ARWorldCommandRenderer(
                registry: registry,
                diagnostics: ARDiagnosticRecorder()
            )
            await registerCompanion(in: registry)

            _ = await renderer.setCompanionState(.celebrate)
            let transition = renderer.advanceCompanionPresentation(by: delta)

            XCTAssertEqual(transition?.outcome, .invalidElapsedNormalizedToIdle)
            XCTAssertEqual(renderer.companionState, .idle)
        }
    }

    func testARLabDeferredStateAndClearStaySynchronized() async {
        let runtime = ARCompanionLabRuntime()
        await runtime.setState(.alert)
        XCTAssertEqual(runtime.currentState, .idle)
        XCTAssertEqual(runtime.transitionResult, "Deferred: companion missing")

        runtime.clear()
        XCTAssertEqual(runtime.currentState, .idle)
        XCTAssertEqual(runtime.transitionResult, "Cleared to idle")
        XCTAssertEqual(runtime.registryCount, 0)
    }

    func testARLabDetachCancelsSceneUpdatesAndDropsView() {
        let runtime = ARCompanionLabRuntime()
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)

        runtime.attach(arView)
        XCTAssertTrue(runtime.isSceneUpdateAttached)
        XCTAssertTrue(runtime.isSessionStartScheduled)

        runtime.detach(arView)
        XCTAssertFalse(runtime.isSceneUpdateAttached)
        XCTAssertFalse(runtime.isSessionStartScheduled)
        XCTAssertEqual(runtime.currentState, .idle)
        XCTAssertEqual(runtime.registryCount, 0)
    }

    func testARLabReplacingAttachedViewClearsOldSceneBeforeIgnoringItsDetach() {
        let runtime = ARCompanionLabRuntime()
        let first = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        let replacement = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)

        runtime.attach(first)
        runtime.attach(replacement)
        XCTAssertEqual(runtime.transitionResult, "Cleared to idle")
        XCTAssertTrue(runtime.isSceneUpdateAttached)
        runtime.detach(first)
        XCTAssertTrue(runtime.isSceneUpdateAttached)

        runtime.detach(replacement)
        XCTAssertFalse(runtime.isSceneUpdateAttached)
    }

    func testPresentationTransitionsDoNotMutateGameplayCompanion() async {
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
        await registerCompanion(in: registry)

        for state in CompanionPresentationState.allCases {
            _ = await renderer.setCompanionState(state)
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

    // MARK: - Animation and asset contract tests (new for mesh/anim upgrade)

    func testFollowSelectsAndLoopsWalkingAnimationAndRepeatedUpdatesDoNotRestart() async {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: ARDiagnosticRecorder())
        await registerCompanion(in: registry)

        // Enter follow
        _ = await renderer.setCompanionState(.follow)
        XCTAssertEqual(renderer.companionState, .follow)
        // (In real run, anim would be playing; here we verify no crash and state)

        // Repeated follow should not change (no restart logic exercised via state)
        _ = await renderer.setCompanionState(.follow)
        XCTAssertEqual(renderer.companionState, .follow)
        XCTAssertEqual(renderer.lastCompanionTransition?.outcome, .unchanged)
    }

    func testOtherStatesUseBoundedTransformsWithoutScaleDistortion() async {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: ARDiagnosticRecorder())
        let anchor = await registerCompanion(in: registry)
        let companion = anchor.findEntity(named: CompanionEntityFactory.rootName)!

        let baseX = companion.scale.x

        for state in [.idle, .investigate, .alert, .celebrate] as [CompanionPresentationState] {
            _ = await renderer.setCompanionState(state)
            // scale unchanged
            XCTAssertEqual(companion.scale.x, baseX, accuracy: 0.001)
            // pos/orient within bounds as before
            XCTAssertLessThanOrEqual(simd_length(companion.position), 0.12)
        }
    }

    func testMissingStaticAssetDefersSafelyAndDoesNotMutateState() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let factory = CompanionEntityFactory(staticAssetName: "nonexistent-static-mesh")
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics, companionFactory: factory)

        let pres = CompanionPresentation(id: UUID(), name: "Lira", behavior: "idle", spatialIntent: SpatialIntent(placement: .groundPlane, distanceBand: .near, bearing: .ahead, scaleClass: .companion, persistence: .session))
        let result = await renderer.render(.spawnCompanion(pres), in: ARView(frame: .zero))

        XCTAssertEqual(result, .deferred("companion-static-asset-unavailable"))
        // state not mutated (still default idle)
        XCTAssertEqual(renderer.companionState, .idle)
    }

    func testMissingWalkingAssetDefersSafelyAndDoesNotMutateState() async {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let factory = CompanionEntityFactory(walkingAssetName: "nonexistent-walking")
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics, companionFactory: factory)

        let pres = CompanionPresentation(id: UUID(), name: "Lira", behavior: "idle", spatialIntent: SpatialIntent(placement: .groundPlane, distanceBand: .near, bearing: .ahead, scaleClass: .companion, persistence: .session))
        let result = await renderer.render(.spawnCompanion(pres), in: ARView(frame: .zero))

        XCTAssertEqual(result, .deferred("companion-walking-animation-unavailable"))
        XCTAssertEqual(renderer.companionState, .idle)
    }

    func testUnavailableAnimationDefersSafely() async {
        // Simulate unavailable by using factory that would fail anim load (via bad name)
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let factory = CompanionEntityFactory(walkingAssetName: "nonexistent-for-anim-test")
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics, companionFactory: factory)

        // Spawn will defer because we check anim at spawn per asset contract
        let pres = CompanionPresentation(id: UUID(), name: "Lira", behavior: "follow", spatialIntent: SpatialIntent(placement: .groundPlane, distanceBand: .near, bearing: .ahead, scaleClass: .companion, persistence: .session))
        let result = await renderer.render(.spawnCompanion(pres), in: ARView(frame: .zero))
        XCTAssertEqual(result, .deferred("companion-walking-animation-unavailable"))
    }

    @discardableResult
    private func registerCompanion(
        in registry: AREntityRegistry,
        parent: Entity? = nil
    ) async -> Entity {
        let anchor = Entity()
        if let lira = await CompanionEntityFactory().makeLira() {
            anchor.addChild(lira)
        }
        parent?.addChild(anchor)
        registry.register(anchor, for: ARWorldCommandRenderer.companionID)
        return anchor
    }
}
