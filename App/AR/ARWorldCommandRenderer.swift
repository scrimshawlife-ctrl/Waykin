import ARKit
import RealityKit
import UIKit
import WaykinCore

@MainActor
final class ARWorldCommandRenderer {
    enum Result: String, Equatable {
        case applied
        case deferred
        case missingEntity
    }

    private let registry: AREntityRegistry
    private let diagnostics: ARDiagnosticRecorder
    private let companionVisualController = CompanionVisualController()

    init(registry: AREntityRegistry, diagnostics: ARDiagnosticRecorder) {
        self.registry = registry
        self.diagnostics = diagnostics
    }

    @discardableResult
    func render(_ command: ARWorldCommand, in arView: ARView) -> Result {
        switch command {
        case .spawnCompanion(let presentation):
            return place(
                id: presentation.id.uuidString,
                kind: "companion",
                entity: CompanionEntityFactory.makeLira(),
                intent: presentation.spatialIntent,
                in: arView,
                afterPlacement: { [companionVisualController] entity in
                    companionVisualController.apply(behavior: presentation.behavior, to: entity)
                }
            )

        case .updateCompanion(let presentation):
            guard let anchor = registry.entity(for: presentation.id.uuidString),
                  let root = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
                return .missingEntity
            }
            companionVisualController.apply(behavior: presentation.behavior, to: root)
            diagnostics.record(.companionStateChanged, detail: companionVisualController.transition.state.rawValue)
            return .applied

        case .spawnDiscovery(let presentation):
            return place(
                id: presentation.id.uuidString,
                kind: "discovery",
                entity: ARPlaceholderFactory.makeDiscovery(),
                intent: presentation.spatialIntent,
                in: arView
            )

        case .spawnThreat(let presentation):
            return place(
                id: presentation.id.uuidString,
                kind: "threat",
                entity: ARPlaceholderFactory.makeThreat(intensity: presentation.intensity),
                intent: presentation.spatialIntent,
                in: arView
            )

        case .updateThreat(let presentation):
            guard registry.entity(for: presentation.id.uuidString) != nil else { return .missingEntity }
            return place(
                id: presentation.id.uuidString,
                kind: "threat",
                entity: ARPlaceholderFactory.makeThreat(intensity: presentation.intensity),
                intent: presentation.spatialIntent,
                in: arView
            )

        case .removeEntity(let id):
            guard registry.remove(id.uuidString) != nil else { return .missingEntity }
            diagnostics.record(.entityRemoved, detail: id.uuidString)
            return .applied

        case .clearSession:
            registry.clear()
            diagnostics.record(.sessionCleared)
            return .applied
        }
    }

    private func place(
        id: String,
        kind: String,
        entity: Entity,
        intent: SpatialIntent,
        in arView: ARView,
        afterPlacement: ((Entity) -> Void)? = nil
    ) -> Result {
        diagnostics.record(.placementAttempted, detail: kind)
        guard intent.placement == .groundPlane else {
            diagnostics.record(.placementFailed, detail: "unsupported-placement")
            return .deferred
        }
        let point = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        guard let query = arView.makeRaycastQuery(from: point, allowing: .estimatedPlane, alignment: .horizontal),
              let result = arView.session.raycast(query).first else {
            diagnostics.record(.placementFailed, detail: kind)
            return .deferred
        }

        let wasReplacement = registry.entity(for: id) != nil
        let anchor = AnchorEntity(raycastResult: result)
        anchor.addChild(entity)
        afterPlacement?(entity)
        arView.scene.addAnchor(anchor)
        registry.register(anchor, for: id)
        diagnostics.record(wasReplacement ? .entityReplaced : .entityCreated, detail: kind)
        diagnostics.record(.placementSucceeded, detail: kind)
        return .applied
    }
}
