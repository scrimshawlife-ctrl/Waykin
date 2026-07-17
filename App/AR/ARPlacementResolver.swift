import ARKit
import RealityKit
import UIKit
import WaykinCore

@MainActor
final class ARPlacementResolver {
    private let registry: AREntityRegistry

    init(registry: AREntityRegistry) {
        self.registry = registry
    }

    @discardableResult
    func placePlaceholder(id: String, intent: SpatialIntent, in arView: ARView) -> Bool {
        let radius = placeholderRadius(for: intent.scaleClass)
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: .systemTeal, isMetallic: false)
        let marker = ModelEntity(mesh: mesh, materials: [material])
        marker.position.y = radius
        return place(entity: marker, id: id, intent: intent, in: arView)
    }

    @discardableResult
    func place(entity: Entity, id: String, intent: SpatialIntent, in arView: ARView) -> Bool {
        guard intent.placement == .groundPlane else { return false }

        let point = candidateScreenPoint(for: intent, bounds: arView.bounds)
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

    func candidateScreenPoint(for intent: SpatialIntent, bounds: CGRect) -> CGPoint {
        let x: CGFloat
        switch intent.bearing {
        case .beside: x = bounds.midX + bounds.width * 0.22
        case .behind: x = bounds.midX
        case .ahead, .contextual: x = bounds.midX
        }

        let y: CGFloat
        switch intent.distanceBand {
        case .immediate: y = bounds.midY + bounds.height * 0.22
        case .near: y = bounds.midY + bounds.height * 0.12
        case .medium: y = bounds.midY
        case .far: y = bounds.midY - bounds.height * 0.12
        }
        return CGPoint(x: x, y: y)
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
}
