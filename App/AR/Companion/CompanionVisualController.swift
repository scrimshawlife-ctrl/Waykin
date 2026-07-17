import RealityKit
import UIKit

@MainActor
final class CompanionVisualController {
    private(set) var transition = CompanionPresentationTransition(state: .idle)

    func apply(
        behavior: String,
        deltaTime: TimeInterval = 0,
        to root: Entity
    ) {
        transition = CompanionStateReducer.reduce(
            current: transition,
            behavior: behavior,
            deltaTime: deltaTime
        )
        apply(transition.state, to: root)
    }

    func apply(_ state: CompanionPresentationState, to root: Entity) {
        transition = CompanionPresentationTransition(state: state)
        let body = root.findEntity(named: "Body")
        let head = root.findEntity(named: "Head")
        let tail = root.findEntity(named: "Tail")
        let glow = root.findEntity(named: "CoreGlow")
        let indicator = root.findEntity(named: "StatusIndicator")

        root.scale = [1, 1, 1]
        body?.scale = [1, 1, 1]
        head?.orientation = simd_quatf()
        tail?.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])
        glow?.scale = [1, 1, 1]
        indicator?.isEnabled = false

        switch state {
        case .idle:
            tail?.orientation = simd_quatf(angle: .pi / 2.7, axis: [1, 0.15, 0])
        case .follow:
            root.scale = [0.98, 1.02, 0.98]
            tail?.orientation = simd_quatf(angle: .pi / 2.25, axis: [1, 0, 0.2])
        case .investigate:
            head?.orientation = simd_quatf(angle: -0.28, axis: [1, 0, 0])
            glow?.scale = [1.3, 1.3, 1.3]
        case .alert:
            body?.scale = [0.95, 1.12, 0.95]
            indicator?.isEnabled = true
            glow?.scale = [1.5, 1.5, 1.5]
        case .celebrate:
            root.scale = [1.08, 1.08, 1.08]
            root.orientation = simd_quatf(angle: .pi / 8, axis: [0, 1, 0])
            glow?.scale = [1.65, 1.65, 1.65]
        }
    }
}

struct CompanionTransformPolicy: Equatable, Sendable {
    var preferredDistance: Float = 1.8
    var followThreshold: Float = 0.45
    var resetThreshold: Float = 8
    var maximumSpeed: Float = 1.5

    func step(current: SIMD3<Float>, target: SIMD3<Float>, deltaTime: Float) -> SIMD3<Float> {
        guard current.x.isFinite, current.y.isFinite, current.z.isFinite,
              target.x.isFinite, target.y.isFinite, target.z.isFinite else { return current }
        let offset = target - current
        let distance = simd_length(offset)
        if distance <= max(0, followThreshold) { return current }
        if distance >= max(followThreshold, resetThreshold) { return target }
        let safeDelta = min(max(deltaTime.isFinite ? deltaTime : 0, 0), 1)
        let maximumStep = max(0, maximumSpeed) * safeDelta
        guard distance > 0 else { return current }
        return current + simd_normalize(offset) * min(distance, maximumStep)
    }
}
