import ARKit
import RealityKit
import UIKit
import WaykinCore

@MainActor
final class ARPlacementResolver {
    private let registry: AREntityRegistry

    @MainActor
    private enum PlaceholderResources {
        static let companionMesh = MeshResource.generateSphere(radius: 0.12)
        static let discoveryMesh = MeshResource.generateSphere(radius: 0.08)
        static let threatMesh = MeshResource.generateSphere(radius: 0.18)
        static let environmentalMesh = MeshResource.generateSphere(radius: 0.24)
        static let material = SimpleMaterial(color: .systemTeal, isMetallic: false)
    }

    init(registry: AREntityRegistry) {
        self.registry = registry
    }

    @discardableResult
    func place(
        id: String,
        intent: SpatialIntent,
        entity: Entity,
        in arView: ARView,
        screenPoint: CGPoint? = nil
    ) -> Bool {
        guard intent.placement == .groundPlane else { return false }
        let point = screenPoint ?? CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        guard let query = arView.makeRaycastQuery(
            from: point,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ), let result = arView.session.raycast(query).first else {
            return false
        }

        let anchor = AnchorEntity(raycastResult: result)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        registry.register(anchor, for: id)
        return true
    }

    @discardableResult
    func placePlaceholder(
        id: String,
        intent: SpatialIntent,
        in arView: ARView,
        screenPoint: CGPoint? = nil
    ) -> Bool {
        let radius = placeholderRadius(for: intent.scaleClass)
        let marker = ModelEntity(
            mesh: placeholderMesh(for: intent.scaleClass),
            materials: [PlaceholderResources.material]
        )
        marker.position.y = radius
        return place(id: id, intent: intent, entity: marker, in: arView, screenPoint: screenPoint)
    }

    func remove(id: String) {
        registry.remove(id)
    }

    func clear() {
        registry.clear()
    }

    private func placeholderRadius(for scaleClass: SpatialScaleClass) -> Float {
        switch scaleClass {
        case .companion: 0.12
        case .discovery: 0.08
        case .threat: 0.18
        case .environmental: 0.24
        }
    }

    private func placeholderMesh(for scaleClass: SpatialScaleClass) -> MeshResource {
        switch scaleClass {
        case .companion: PlaceholderResources.companionMesh
        case .discovery: PlaceholderResources.discoveryMesh
        case .threat: PlaceholderResources.threatMesh
        case .environmental: PlaceholderResources.environmentalMesh
        }
    }
}
