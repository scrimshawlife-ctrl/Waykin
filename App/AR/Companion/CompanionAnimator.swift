import RealityKit

@MainActor
final class CompanionAnimator {
    private(set) var state: CompanionPresentationState = .idle

    func apply(_ newState: CompanionPresentationState, to entity: Entity, animated: Bool = true) {
        state = newState
        let duration: TimeInterval = animated ? 0.35 : 0
        var transform = entity.transform

        switch newState {
        case .idle:
            transform.scale = SIMD3(repeating: 1)
            transform.translation.y = 0
        case .follow:
            transform.scale = SIMD3(repeating: 1.02)
            transform.translation.y = 0.015
        case .investigate:
            transform.scale = SIMD3<Float>(0.98, 0.96, 1.04)
            transform.translation.y = -0.015
        case .alert:
            transform.scale = SIMD3<Float>(1.03, 1.12, 0.98)
            transform.translation.y = 0.035
        case .celebrate:
            transform.scale = SIMD3(repeating: 1.10)
            transform.translation.y = 0.11
        }

        if animated {
            entity.move(to: transform, relativeTo: entity.parent, duration: duration, timingFunction: .easeInOut)
        } else {
            entity.transform = transform
        }
    }
}
