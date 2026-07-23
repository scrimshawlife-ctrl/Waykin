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
    /// Entities currently riding the camera fallback. Camera anchoring is a stopgap for
    /// "no plane yet" — without tracking it, a camera-anchored companion looks healthy to
    /// the continuity check (always near, always attached) and never returns to the ground.
    private var cameraAnchoredIDs: Set<String> = []
    /// Whether the companion is currently stuck on the camera fallback.
    var isCompanionCameraAnchored: Bool {
        cameraAnchoredIDs.contains(ARWorldCommandRenderer.companionID)
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
            // Riding the camera is a stopgap, not a resting state: keep trying to plant
            // her on real ground so she stops following the view around.
            if promoteCameraAnchorToGround(id: id, in: arView) {
                return true
            }
            lastContinuityNote = isCompanionCameraAnchored ? "ok_camera_waiting_for_ground" : "ok_present"
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
        cameraAnchoredIDs.remove(id)
    }

    func clear() {
        registry.clear()
        cameraAnchoredIDs.removeAll()
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

    /// Screen points to probe for ground. A single sample just below centre misses often
    /// outdoors — it lands on sky or distant geometry. Sampling progressively lower finds
    /// the ground the walker is actually standing on.
    private func groundProbePoints(in arView: ARView, preferred: CGPoint?) -> [CGPoint] {
        var points: [CGPoint] = []
        if let preferred { points.append(preferred) }
        let bounds = arView.bounds
        guard bounds.width > 1, bounds.height > 1 else { return points }
        for fraction in [0.62, 0.72, 0.84, 0.54, 0.94] {
            points.append(CGPoint(x: bounds.midX, y: bounds.height * fraction))
        }
        return points
    }

    /// First horizontal hit across the probe points. Real detected planes beat estimates.
    private func groundRaycast(in arView: ARView, screenPoint: CGPoint?) -> ARRaycastResult? {
        let points = groundProbePoints(in: arView, preferred: screenPoint)
        for target in [ARRaycastQuery.Target.existingPlaneGeometry, .estimatedPlane] {
            for point in points {
                guard let query = arView.makeRaycastQuery(
                    from: point,
                    allowing: target,
                    alignment: .horizontal
                ) else { continue }
                if let result = arView.session.raycast(query).first {
                    return result
                }
            }
        }
        return nil
    }

    private func placeOnGroundPlane(
        id: String,
        entity: Entity,
        in arView: ARView,
        screenPoint: CGPoint?,
        reason: String
    ) -> Bool {
        guard let result = groundRaycast(in: arView, screenPoint: screenPoint) else {
            lastContinuityNote = "ground_raycast_failed:\(reason)"
            return false
        }
        cameraAnchoredIDs.remove(id)

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
        cameraAnchoredIDs.insert(id)
        lastContinuityNote = "planted_camera:\(reason)"
        return true
    }

    /// Move a camera-anchored companion onto real ground as soon as a plane exists.
    /// Probes first and only re-parents on a hit, so a failed probe can't cause a
    /// visible re-spawn pop every continuity tick.
    private func promoteCameraAnchorToGround(id: String, in arView: ARView) -> Bool {
        guard cameraAnchoredIDs.contains(id),
              let anchor = registry.entity(for: id),
              groundRaycast(in: arView, screenPoint: nil) != nil,
              let companion = anchor.findEntity(named: CompanionEntityFactory.rootName)
                ?? anchor.children.first else { return false }
        companion.removeFromParent()
        // Reset the camera-space offset before planting in world space.
        companion.position = .zero
        if placeOnGroundPlane(
            id: id,
            entity: companion,
            in: arView,
            screenPoint: nil,
            reason: "promoted_camera_to_ground"
        ) {
            return true
        }
        // Probe passed but plant failed — keep presence rather than dropping her.
        return placeOnCamera(id: id, entity: companion, in: arView, reason: "promote_retry_failed")
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
