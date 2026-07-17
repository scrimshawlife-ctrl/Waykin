import Observation
import RealityKit
import WaykinCore

@MainActor
@Observable
final class ARPresentationController {
    private(set) var registryCount = 0
    private(set) var currentCompanionState: CompanionPresentationState = .idle
    private(set) var lastCommandResult: ARCommandResult?
    private(set) var receipt = ARValidationReceipt(
        eventCount: 0,
        placementSuccessCount: 0,
        placementFailureCount: 0,
        replacementCount: 0,
        stateTransitions: [],
        cleanupSucceeded: false
    )

    private let registry = AREntityRegistry()
    private let diagnostics = ARDiagnosticRecorder()
    private lazy var placementResolver = ARPlacementResolver(registry: registry)
    private lazy var renderer = ARWorldCommandRenderer(
        registry: registry,
        placementResolver: placementResolver,
        diagnostics: diagnostics
    )
    private weak var arView: ARView?
    private let companionID = UUID(uuidString: "00000000-0000-0000-0000-00000000A201")!
    private let discoveryID = UUID(uuidString: "00000000-0000-0000-0000-00000000A202")!
    private let threatID = UUID(uuidString: "00000000-0000-0000-0000-00000000A203")!

    func attach(to arView: ARView) {
        self.arView = arView
        diagnostics.record(.sessionStarted)
        refreshDiagnostics()
    }

    func placeCompanion() {
        guard let arView else { return }
        render(.spawnCompanion(companionPresentation(state: currentCompanionState)), in: arView)
    }

    func setCompanionState(_ state: CompanionPresentationState) {
        currentCompanionState = state
        guard let arView else { return }
        render(.updateCompanion(companionPresentation(state: state)), in: arView)
    }

    func spawnDiscovery() {
        guard let arView else { return }
        let presentation = DiscoveryPresentation(
            id: discoveryID,
            kind: "engineering_discovery",
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .contextual,
                scaleClass: .discovery,
                persistence: .encounter
            )
        )
        render(.spawnDiscovery(presentation), in: arView)
    }

    func spawnThreat(intensity: Double = 0.65) {
        guard let arView else { return }
        let presentation = ThreatPresentation(
            id: threatID,
            kind: "engineering_threat",
            intensity: intensity,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .medium,
                bearing: .ahead,
                scaleClass: .threat,
                persistence: .encounter
            )
        )
        render(.spawnThreat(presentation), in: arView)
    }

    func clear() {
        guard let arView else {
            registry.clear()
            refreshDiagnostics()
            return
        }
        render(.clearSession, in: arView)
    }

    private func render(_ command: ARWorldCommand, in arView: ARView) {
        lastCommandResult = renderer.render(command, in: arView)
        registryCount = registry.count
        refreshDiagnostics()
    }

    private func companionPresentation(state: CompanionPresentationState) -> CompanionPresentation {
        CompanionPresentation(
            id: companionID,
            name: "Lira",
            behavior: state.rawValue,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .companion,
                persistence: .session
            )
        )
    }

    private func refreshDiagnostics() {
        registryCount = registry.count
        receipt = diagnostics.receipt(registryCount: registry.count)
    }
}
