import Foundation

public protocol MemoryGenerating {
    func generateMemory(session: MovementSession, result: ExperienceResult, companion: Companion) -> SessionMemory
}

public struct DeterministicMemoryGenerator: MemoryGenerating {
    public func generateMemory(session: MovementSession, result: ExperienceResult, companion: Companion) -> SessionMemory {
        let dist = Int(session.distanceMeters)
        let text = "We completed a \(session.activityType) of \(dist)m using \(session.experienceID). \(result.memoryText) Bond +\(result.bondDelta)."
        return SessionMemory(id: UUID(), sessionID: session.id, text: text, timestamp: Date())
    }
}

public struct MemoryEngine {
    private let generator: any MemoryGenerating

    public init(generator: (any MemoryGenerating)? = nil) {
        self.generator = generator ?? DeterministicMemoryGenerator()
    }

    public func createMemory(session: MovementSession, result: ExperienceResult, companion: Companion) -> SessionMemory {
        generator.generateMemory(session: session, result: result, companion: companion)
    }
}
