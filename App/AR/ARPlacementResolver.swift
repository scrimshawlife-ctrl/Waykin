import ARKit
import RealityKit
import simd
import UIKit
import WaykinCore

@MainActor
final class ARPlacementResolver {
    /// When companion is farther than this (meters, approx) from the camera, re-plant ahead.
    static let companionReplantDistanceMeters: Float = 6.0
    /// Camera-space offset when using camera anchor fallback / continuous plant (meters).
    static let companionCameraOffset = SIMD3<Float>(0, -0.15, -1.35)

    private let registry: AREntityRegistry
    /// Last continuity diagnostic detail for AR chrome / tests (#125).
    private(set) var lastContinuityNote: String = "none"

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
        // Session companion: prefer ground plant ahead of camera; fall back to camera anchor
        // so presence does not vanish when world anchors drop (#125).
        if intent.scaleClass == .companion && intent.persistence == .session {
            return placeCompanion(
                id: id,
                entity: entity,
                in: arView,
                screenPoint: screenPoint,
                reason: "spawn"
            )
        }

        guard intent.placement == .groundPlane || intent.placement == .worldRelative else {
            if intent.placement == .cameraRelative {
                return placeOnCamera(id: id, entity: entity, in: arView, reason: "camera_intent")
            }
            return false
        }
        return placeOnGroundPlane(
            id: id,
            entity: entity,
            in: arView,
            screenPoint: screenPoint,
            reason: "ground"
        )
    }

    /// Re-plant companion if missing from registry/scene or too far from camera.
    @discardableResult
    func ensureCompanionContinuity(
        id: String,
        makeEntity: () -> Entity,
        in arView: ARView
    ) -> Bool {
        if let anchor = registry.entity(for: id) {
            if isCompanionFarOrDetached(anchor: anchor, arView: arView) {
                let companion = anchor.findEntity(named: CompanionEntityFactory.rootName)
                    ?? anchor.children.first
                let entity = companion.map { existing -> Entity in
                    existing.removeFromParent()
                    return existing
                } ?? makeEntity()
                return placeCompanion(
                    id: id,
                    entity: entity,
                    in: arView,
                    screenPoint: nil,
                    reason: "replant_far_or_detached"
                )
            }
            lastContinuityNote = "ok_present"
            return true
        }
        // Missing entirely — recover with a fresh entity (same as re-open sheet path).
        return placeCompanion(
            id: id,
            entity: makeEntity(),
            in: arView,
            screenPoint: nil,
            reason: "replant_missing"
        )
    }

    @discardableResult
    func placePlaceholder(
        id: String,
        intent: SpatialIntent,
        in arView: ARView,
        screenPoint: CGPoint? = nil
    ) -> Bool {
        let radius = placeholderRadius(for: intent.scaleClass)
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: .systemTeal, isMetallic: false)
        let marker = ModelEntity(mesh: mesh, materials: [material])
        marker.position.y = radius
        return place(id: id, intent: intent, entity: marker, in: arView, screenPoint: screenPoint)
    }

    func remove(id: String) {
        registry.remove(id)
    }

    func clear() {
        registry.clear()
        lastContinuityNote = "cleared"
    }

    // MARK: - Private

    private func placeCompanion(
        id: String,
        entity: Entity,
        in arView: ARView,
        screenPoint: CGPoint?,
        reason: String
    ) -> Bool {
        if placeOnGroundPlane(id: id, entity: entity, in: arView, screenPoint: screenPoint, reason: reason + "+ground") {
            return true
        }
        return placeOnCamera(id: id, entity: entity, in: arView, reason: reason + "+camera_fallback")
    }

    private func placeOnGroundPlane(
        id: String,
        entity: Entity,
        in arView: ARView,
        screenPoint: CGPoint?,
        reason: String
    ) -> Bool {
        let point = screenPoint ?? CGPoint(x: arView.bounds.midX, y: arView.bounds.midY * 1.08)
        guard let query = arView.makeRaycastQuery(
            from: point,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ), let result = arView.session.raycast(query).first else {
            lastContinuityNote = "ground_raycast_failed:\(reason)"
            return false
        }

        let anchor = AnchorEntity(raycastResult: result)
        // Keep local plant slightly above plane.
        if entity.position == .zero {
            entity.position = SIMD3<Float>(0, 0.02, 0)
        }
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        registry.register(anchor, for: id)
        lastContinuityNote = "planted_ground:\(reason)"
        return true
    }

    private func placeOnCamera(
        id: String,
        entity: Entity,
        in arView: ARView,
        reason: String
    ) -> Bool {
        let anchor = AnchorEntity(.camera)
        entity.position = Self.companionCameraOffset
        entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        registry.register(anchor, for: id)
        lastContinuityNote = "planted_camera:\(reason)"
        return true
    }

    private func isCompanionFarOrDetached(anchor: Entity, arView: ARView) -> Bool {
        // Detached from scene graph.
        if anchor.scene == nil {
            return true
        }
        // Approximate distance: transform relative to camera.
        let camera = arView.cameraTransform
        let anchorPos = anchor.position(relativeTo: nil)
        let cameraPos = camera.translation
        return Self.shouldReplant(distanceMeters: simd_length(anchorPos - cameraPos))
    }

    /// Pure distance gate for tests / diagnostics (#125).
    static func shouldReplant(distanceMeters: Float, threshold: Float = companionReplantDistanceMeters) -> Bool {
        !distanceMeters.isFinite || distanceMeters > threshold
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
