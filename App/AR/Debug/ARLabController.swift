import RealityKit
import SwiftUI
import WaykinCore

@MainActor
final class ARLabController: ObservableObject {
    @Published private(set) var capabilityState: ARCapabilityState = .checking
    @Published private(set) var companionState: CompanionPresentationState = .idle
    @Published private(set) var registryCount = 0
    @Published private(set) var lastCommandResult = "none"

    let sessionCoordinator = ARSessionCoordinator()
    let diagnostics = ARDiagnosticRecorder()

    private let registry = AREntityRegistry()
    private lazy var renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
    private weak var arView: ARView?
    private let companionID = UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!
    private let discoveryID = UUID(uuidString: "A2000000-0000-0000-0000-000000000002")!
    private let threatID = UUID(uuidString: "A3000000-0000-0000-0000-000000000003")!

    init() {
        sessionCoordinator.onCapabilityStateChange = { [weak self] state in
            self?.capabilityState = state
            if state == .active {
                self?.diagnostics.record(.trackingChanged, detail: "normal")
            }
        }
    }

    func attach(to arView: ARView) {
        self.arView = arView
        arView.session = sessionCoordinator.session
    }

    func start() async {
        diagnostics.record(.sessionStarted)
        await sessionCoordinator.start()
    }

    func placeCompanion() {
        let presentation = CompanionPresentation(
            id: companionID,
            name: "Lira",
            behavior: companionState.rawValue,
            spatialIntent: companionIntent
        )
        execute(.spawnCompanion(presentation))
    }

    func setCompanionState(_ state: CompanionPresentationState) {
        companionState = state
        let presentation = CompanionPresentation(
            id: companionID,
            name: "Lira",
            behavior: state.rawValue,
            spatialIntent: companionIntent
        )
        execute(.updateCompanion(presentation))
    }

    func spawnDiscovery() {
        execute(.spawnDiscovery(DiscoveryPresentation(
            id: discoveryID,
            kind: "engineering-discovery",
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .contextual,
                scaleClass: .discovery,
                persistence: .encounter
            )
        )))
    }

    func spawnThreat(intensity: Double = 0.65) {
        execute(.spawnThreat(ThreatPresentation(
            id: threatID,
            kind: "engineering-threat",
            intensity: intensity,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .medium,
                bearing: .ahead,
                scaleClass: .threat,
                persistence: .encounter
            )
        )))
    }

    func removeCompanion() {
        execute(.removeEntity(companionID))
    }

    func clear() {
        execute(.clearSession)
    }

    func resetTracking() async {
        clear()
        await sessionCoordinator.start(resetTracking: true)
    }

    func stop() {
        clear()
        diagnostics.record(.sessionStopped)
        sessionCoordinator.pause()
    }

    private func execute(_ command: ARWorldCommand) {
        guard let arView else {
            lastCommandResult = "deferred:no-ar-view"
            return
        }
        let result = renderer.render(command, in: arView)
        registryCount = registry.count
        lastCommandResult = result.rawValue
    }

    private var companionIntent: SpatialIntent {
        SpatialIntent(
            placement: .groundPlane,
            distanceBand: .near,
            bearing: .ahead,
            scaleClass: .companion,
            persistence: .session
        )
    }
}
