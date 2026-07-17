import RealityKit
import WaykinCore

@MainActor
enum ARCommandResult: String, Equatable {
    case accepted
    case deferred
    case rejected
}

@MainActor
final class ARWorldCommandRenderer {
    private let registry: AREntityRegistry
    private let placementResolver: ARPlacementResolver
    private let companionFactory: CompanionEntityFactory
    private let discoveryFactory: DiscoveryPlaceholderFactory
    private let threatFactory: ThreatPlaceholderFactory
    private let diagnostics: ARDiagnosticRecorder

    init(
        registry: AREntityRegistry,
        placementResolver: ARPlacementResolver,
        diagnostics: ARDiagnosticRecorder
    ) {
        self.registry = registry
        self.placementResolver = placementResolver
        self.diagnostics = diagnostics
        self.companionFactory = CompanionEntityFactory()
        self.discoveryFactory = DiscoveryPlaceholderFactory()
        self.threatFactory = ThreatPlaceholderFactory()
    }

    @discardableResult
    func render(_ command: ARWorldCommand, in arView: ARView) -> ARCommandResult {
        switch command {
        case .spawnCompanion(let presentation):
            placeCompanion(presentation, in: arView)
        case .updateCompanion(let presentation):
            updateCompanion(presentation, in: arView)
        case .spawnDiscovery(let presentation):
            place(
                discoveryFactory.makeEntity(),
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
        case .spawnThreat(let presentation):
            place(
                threatFactory.makeEntity(intensity: presentation.intensity),
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
        case .updateThreat(let presentation):
            place(
                threatFactory.makeEntity(intensity: presentation.intensity),
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
        case .removeEntity(let id):
            placementResolver.remove(id: id.uuidString)
            diagnostics.record(.entityRemoved, detail: id.uuidString)
            return .accepted
        case .clearSession:
            placementResolver.clear()
            diagnostics.record(.sessionCleared)
            return .accepted
        }
    }

    private func updateCompanion(_ presentation: CompanionPresentation, in arView: ARView) -> ARCommandResult {
        let id = presentation.id.uuidString
        guard let anchor = registry.entity(for: id),
              let lira = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
            return placeCompanion(presentation, in: arView)
        }

        let state = CompanionStateReducer.state(for: presentation.behavior)
        apply(state: state, to: lira)
        diagnostics.record(.stateChanged, detail: state.rawValue)
        return .accepted
    }

    private func placeCompanion(_ presentation: CompanionPresentation, in arView: ARView) -> ARCommandResult {
        let lira = companionFactory.makeLira()
        let state = CompanionStateReducer.state(for: presentation.behavior)
        apply(state: state, to: lira)
        let result = place(lira, id: presentation.id.uuidString, intent: presentation.spatialIntent, in: arView)
        if result == .accepted {
            diagnostics.record(.stateChanged, detail: state.rawValue)
        }
        return result
    }

    private func place(
        _ entity: Entity,
        id: String,
        intent: SpatialIntent,
        in arView: ARView
    ) -> ARCommandResult {
        diagnostics.record(.placementAttempted, detail: id)
        let replaced = registry.entity(for: id) != nil
        guard placementResolver.place(entity: entity, id: id, intent: intent, in: arView) else {
            diagnostics.record(.placementFailed, detail: id)
            return .deferred
        }
        diagnostics.record(.placementSucceeded, detail: id)
        diagnostics.record(replaced ? .entityReplaced : .entityCreated, detail: id)
        return .accepted
    }

    private func apply(state: CompanionPresentationState, to lira: Entity) {
        lira.transform.scale = SIMD3(repeating: 1)
        lira.position.y = 0.015
        lira.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])

        switch state {
        case .idle:
            lira.position.y = 0.025
        case .follow:
            lira.orientation = simd_quatf(angle: 0.18, axis: [0, 1, 0])
        case .investigate:
            lira.orientation = simd_quatf(angle: -0.35, axis: [1, 0, 0])
        case .alert:
            lira.transform.scale = SIMD3(repeating: 1.08)
            lira.position.y = 0.055
        case .celebrate:
            lira.transform.scale = SIMD3(repeating: 1.12)
            lira.position.y = 0.16
            lira.orientation = simd_quatf(angle: .pi / 5, axis: [0, 1, 0])
        }
    }
}
