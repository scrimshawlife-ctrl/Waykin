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
        for name in CompanionEntityFactory.requiredNodeNames {
            XCTAssertNotNil(entity.findEntity(named: name), "Missing \(name)")
        }
        // A1–A3 living familiar anchors present on mid-LOD.
        XCTAssertNotNil(entity.findEntity(named: "Head"))
        XCTAssertNotNil(entity.findEntity(named: "CoreGlow"))
        XCTAssertNotNil(entity.findEntity(named: "Filament"))
        XCTAssertEqual(
            LiraARAssetCatalog.packagedLODHint,
            "packaged_usdz:Lira_AR_Base:MESHY_TEXTURED_STATIC_V1"
        )
        XCTAssertEqual(LiraARAssetCatalog.packagedEvidenceClass, "MESHY_TEXTURED_STATIC_V1")
    }

    func testAssetLoaderClonesInjectedTemplateAndAppliesSkin() {
        let loader = LiraARAssetLoader()
        let template = CompanionEntityFactory(skin: .dawn).makeLira()
        loader.installTemplateForTesting(template, label: "fixture.usdz")
        XCTAssertEqual(loader.source, .usdz("fixture.usdz"))
        XCTAssertTrue(loader.activeLODDescription.contains("artist_usdz:fixture.usdz"))

        loader.skin = .veil
        let first = loader.makeLira()
        let second = loader.makeLira()
        XCTAssertEqual(first.name, CompanionEntityFactory.rootName)
        XCTAssertEqual(second.name, CompanionEntityFactory.rootName)
        XCTAssertFalse(first === second)
        for name in CompanionEntityFactory.requiredNodeNames {
            XCTAssertNotNil(first.findEntity(named: name), "clone missing \(name)")
        }
    }

    func testAssetLoaderFallsBackWhenNoBundleUSDZ() async {
        let loader = LiraARAssetLoader()
        // Inject missing asset: packaged USDZ may now exist on main after mid-LOD shipping.
        await loader.preloadFromBundle(usdzURL: nil)
        XCTAssertEqual(loader.source, .procedural)
        XCTAssertTrue(LiraARAssetLoader.hasRequiredNodes(loader.makeLira()))
    }

    func testAssetLoaderFallsBackWhenUSDZURLUnreadable() async {
        let loader = LiraARAssetLoader()
        let missing = URL(fileURLWithPath: "/tmp/waykin-missing-Lira_AR_Base.usdz")
        await loader.preloadFromBundle(usdzURL: missing)
        XCTAssertEqual(loader.source, .procedural)
        XCTAssertTrue(LiraARAssetLoader.hasRequiredNodes(loader.makeLira()))
    }

    func testAssetLoaderUsesPackagedUSDZWhenBundled() async throws {
        guard LiraARAssetCatalog.hasPackagedUSDZ,
              let url = LiraARAssetCatalog.baseUSDZURL else {
            throw XCTSkip("Packaged Lira_AR_Base.usdz not present in this test host")
        }
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle(usdzURL: url)
        // Shipped skinned package must load in sim; procedural is only for explicit fallback tests.
        guard case .usdz(let name) = loader.source else {
            XCTFail("expected usdz load, got \(loader.activeLODDescription)")
            return
        }
        XCTAssertEqual(name, "Lira_AR_Base.usdz")
        XCTAssertTrue(loader.activeLODDescription.contains("Lira_AR_Base"))
        XCTAssertTrue(LiraARAssetLoader.hasRequiredNodes(loader.makeLira()))
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
        let expected: [(CompanionPresentationState, SIMD3<Float>, SIMD3<Float>, simd_quatf, Bool)] = [
            (.idle, [0, 0, 0], [1, 1, 1], simd_quatf(angle: 0, axis: [0, 1, 0]), false),
            (.follow, [0, 0, 0.12], [1.02, 1.02, 1.02], simd_quatf(angle: 0.18, axis: [0, 1, 0]), false),
            (.investigate, [-0.08, 0, 0], [1, 0.92, 1.08], simd_quatf(angle: -0.22, axis: [1, 0, 0]), true),
            (.alert, [0, 0, -0.10], [1.05, 1.14, 0.96], simd_quatf(angle: 0, axis: [0, 1, 0]), true),
            (.celebrate, [0, 0.10, 0], [1.12, 1.12, 1.12], simd_quatf(angle: .pi / 5, axis: [0, 1, 0]), true),
        ]

        for (state, position, scale, orientation, indicatorVisible) in expected {
            _ = renderer.setCompanionState(state)
            XCTAssertEqual(companion.position, position)
            XCTAssertEqual(companion.scale, scale)
            XCTAssertEqual(companion.orientation.vector, orientation.vector)
            XCTAssertEqual(
                companion.findEntity(named: "StatusIndicator")?.isEnabled,
                indicatorVisible
            )
            let indicator = try XCTUnwrap(
                companion.findEntity(named: "StatusIndicator") as? ModelEntity
            )
            XCTAssertTrue(try XCTUnwrap(indicator.model?.materials.first) is SimpleMaterial)
            XCTAssertLessThanOrEqual(simd_length(companion.position), 0.12)
            XCTAssertLessThanOrEqual(max(scale.x, max(scale.y, scale.z)), 1.14)

            companion.position = [4, 4, 4]
            companion.scale = [3, 3, 3]
            companion.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            indicator.model?.materials = [UnlitMaterial(color: .black)]

            _ = renderer.setCompanionState(state)
            XCTAssertEqual(companion.position, position)
            XCTAssertEqual(companion.scale, scale)
            XCTAssertEqual(companion.orientation.vector, orientation.vector)
            XCTAssertTrue(try XCTUnwrap(indicator.model?.materials.first) is SimpleMaterial)
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
        XCTAssertEqual(renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        _ = renderer.advanceCompanionPresentation(by: 1)

        XCTAssertEqual(renderer.clearSession(), .cleared)

        XCTAssertEqual(renderer.companionState, .idle)
        XCTAssertNil(renderer.advanceCompanionPresentation(by: 1))
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

    func testBehaviorUpdateDoesNotRestartCelebrateDeadline() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        registerCompanion(in: registry)
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

        XCTAssertEqual(renderer.setCompanionState(.celebrate), .accepted("companion:celebrate"))
        _ = renderer.advanceCompanionPresentation(by: 1)
        XCTAssertEqual(
            renderer.render(.updateCompanion(presentation), in: ARView(frame: .zero)),
            .accepted("companion:celebrate")
        )
        XCTAssertEqual(renderer.lastCompanionTransition?.outcome, .celebrationInProgress)
        XCTAssertEqual(renderer.advanceCompanionPresentation(by: 0.5)?.resolvedState, .idle)
        XCTAssertEqual(diagnostics.summary.stateTransitions, ["celebrate", "idle"])
    }

    func testInvalidInjectedDeltasNormalizeCelebrationToIdle() {
        for delta in [-0.1, .nan, .infinity, -.infinity] {
            let registry = AREntityRegistry()
            let renderer = ARWorldCommandRenderer(
                registry: registry,
                diagnostics: ARDiagnosticRecorder()
            )
            registerCompanion(in: registry)

            _ = renderer.setCompanionState(.celebrate)
            let transition = renderer.advanceCompanionPresentation(by: delta)

            XCTAssertEqual(transition?.outcome, .invalidElapsedNormalizedToIdle)
            XCTAssertEqual(renderer.companionState, .idle)
        }
    }

    func testARLabDeferredStateAndClearStaySynchronized() {
        let runtime = ARCompanionLabRuntime()

        runtime.setState(.alert)
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
