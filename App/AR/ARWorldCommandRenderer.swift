import RealityKit
import WaykinCore

@MainActor
enum ARCommandResult: Equatable, Sendable {
    case accepted(String)
    case deferred(String)
    case removed(String)
    case cleared
}

@MainActor
final class ARWorldCommandRenderer {
    static let companionID = "waykin.companion.lira"

    private let registry: AREntityRegistry
    private let placementResolver: ARPlacementResolver
    private let companionFactory: CompanionEntityFactory
    private let diagnostics: ARDiagnosticRecorder

    private(set) var companionState: CompanionPresentationState = .idle

    init(
        registry: AREntityRegistry,
        diagnostics: ARDiagnosticRecorder,
        companionFactory: CompanionEntityFactory? = nil
    ) {
        self.registry = registry
        self.placementResolver = ARPlacementResolver(registry: registry)
        self.diagnostics = diagnostics
        self.companionFactory = companionFactory ?? CompanionEntityFactory()
    }

    func render(_ command: ARWorldCommand, in arView: ARView) -> ARCommandResult {
        switch command {
        case .spawnCompanion(let presentation):
            diagnostics.record(.placementAttempted, detail: "companion")
            let entity = companionFactory.makeLira()
            apply(state: CompanionStateReducer.state(for: presentation.behavior), to: entity)
            let replacing = registry.entity(for: Self.companionID) != nil
            guard placementResolver.place(
                id: Self.companionID,
                intent: presentation.spatialIntent,
                entity: entity,
                in: arView
            ) else {
                diagnostics.record(.placementDeferred, detail: "companion")
                return .deferred("companion")
            }
            diagnostics.record(replacing ? .entityReplaced : .entityCreated, detail: "companion")
            diagnostics.record(.placementSucceeded, detail: "companion")
            return .accepted("companion")

        case .updateCompanion(let presentation):
            guard let anchor = registry.entity(for: Self.companionID),
                  let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
                return .deferred("companion missing")
            }
            let next = CompanionStateReducer.state(for: presentation.behavior)
            apply(state: next, to: companion)
            return .accepted("companion:\(next.rawValue)")

        case .spawnDiscovery(let presentation):
            let placed = placementResolver.placePlaceholder(
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
            diagnostics.record(placed ? .entityCreated : .placementDeferred, detail: "discovery")
            return placed ? .accepted("discovery") : .deferred("discovery")

        case .spawnThreat(let presentation), .updateThreat(let presentation):
            let placed = placementResolver.placePlaceholder(
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
            diagnostics.record(placed ? .entityCreated : .placementDeferred, detail: "threat")
            return placed ? .accepted("threat") : .deferred("threat")

        case .removeEntity(let id):
            placementResolver.remove(id: id.uuidString)
            diagnostics.record(.entityRemoved, detail: id.uuidString)
            return .removed(id.uuidString)

        case .clearSession:
            placementResolver.clear()
            diagnostics.record(.sessionCleared)
            companionState = .idle
            return .cleared
        }
    }

    func setCompanionState(_ state: CompanionPresentationState) -> ARCommandResult {
        guard let anchor = registry.entity(for: Self.companionID),
              let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
            return .deferred("companion missing")
        }
        apply(state: state, to: companion)
        return .accepted("companion:\(state.rawValue)")
    }

    private func apply(state: CompanionPresentationState, to entity: Entity) {
        companionState = state
        diagnostics.record(.stateChanged, detail: state.rawValue)
        switch state {
        case .idle:
            entity.scale = SIMD3<Float>(repeating: 1)
            entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        case .follow:
            entity.scale = SIMD3<Float>(1.02, 1.02, 1.02)
            entity.orientation = simd_quatf(angle: 0.18, axis: [0, 1, 0])
        case .investigate:
            entity.scale = SIMD3<Float>(1.0, 0.92, 1.08)
            entity.orientation = simd_quatf(angle: -0.22, axis: [1, 0, 0])
        case .alert:
            entity.scale = SIMD3<Float>(1.05, 1.14, 0.96)
            entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        case .celebrate:
            entity.scale = SIMD3<Float>(1.12, 1.12, 1.12)
            entity.orientation = simd_quatf(angle: .pi / 5, axis: [0, 1, 0])
        }
    }
}
