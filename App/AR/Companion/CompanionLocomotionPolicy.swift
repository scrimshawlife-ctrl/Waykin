import Foundation
import simd

struct CompanionLocomotionConfiguration: Equatable {
    let preferredDistance: Float
    let activationThreshold: Float
    let resetThreshold: Float
    let maximumSpeed: Float

    static let defaultAR = CompanionLocomotionConfiguration(
        preferredDistance: 1.8,
        activationThreshold: 0.45,
        resetThreshold: 8.0,
        maximumSpeed: 1.5
    )
}

enum CompanionLocomotionDecision: Equatable {
    case hold
    case move(SIMD3<Float>)
    case reset(SIMD3<Float>)
}

struct CompanionLocomotionPolicy {
    let configuration: CompanionLocomotionConfiguration

    init(configuration: CompanionLocomotionConfiguration = .defaultAR) {
        self.configuration = configuration
    }

    func decision(
        current: SIMD3<Float>,
        target: SIMD3<Float>,
        deltaTime: TimeInterval
    ) -> CompanionLocomotionDecision {
        guard current.allFinite, target.allFinite, deltaTime.isFinite, deltaTime > 0 else {
            return .hold
        }

        let offset = target - current
        let distance = simd_length(offset)
        guard distance > configuration.activationThreshold else { return .hold }
        guard distance <= configuration.resetThreshold else { return .reset(target) }

        let maximumStep = configuration.maximumSpeed * Float(deltaTime)
        guard maximumStep > 0 else { return .hold }
        let step = min(distance, maximumStep)
        return .move(current + simd_normalize(offset) * step)
    }
}

private extension SIMD3 where Scalar == Float {
    var allFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}
