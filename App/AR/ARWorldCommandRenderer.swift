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
    private let registry: AREntityRegistry
    private let placementResolver: ARPlacementResolver
    private let companionFactory: CompanionEntityFactory
    private let diagnostics: ARDiagnosticRecorder

    private(set) var companionState: CompanionPresentationState = .idle
    private var companionRegistryID: String?

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
            let registryID = presentation.id.uuidString
            let replacing = registry.entity(for: registryID) != nil
            guard placementResolver.place(
                id: registryID,
                intent: presentation.spatialIntent,
                entity: entity,
                in: arView
            ) else {
                diagnostics.record(.placementDeferred, detail: "companion")
                return .deferred("companion")
            }
            if let previousID = companionRegistryID, previousID != registryID {
                placementResolver.remove(id: previousID)
            }
            companionRegistryID = registryID
            diagnostics.record(replacing ? .entityReplaced : .entityCreated, detail: "companion")
            diagnostics.record(.placementSucceeded, detail: "companion")
            return .accepted("companion")

        case .updateCompanion(let presentation):
            let registryID = presentation.id.uuidString
            guard let anchor = registry.entity(for: registryID),
                  let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
                return .deferred("companion missing")
            }
            companionRegistryID = registryID
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

        case .spawnThreat(let presentation):
            let registryID = presentation.id.uuidString
            let placed = placementResolver.placePlaceholder(
                id: registryID,
                intent: presentation.spatialIntent,
                in: arView
            )
            if placed, let anchor = registry.entity(for: registryID) {
                applyThreatIntensity(presentation.intensity, to: anchor)
            }
            diagnostics.record(placed ? .entityCreated : .placementDeferred, detail: "threat")
            return placed ? .accepted("threat") : .deferred("threat")

        case .updateThreat(let presentation):
            let registryID = presentation.id.uuidString
            guard let anchor = registry.entity(for: registryID) else {
                return .deferred("threat missing")
            }
            applyThreatIntensity(presentation.intensity, to: anchor)
            diagnostics.record(.stateChanged, detail: "threat")
            return .accepted("threat:update")

        case .removeEntity(let id):
            placementResolver.remove(id: id.uuidString)
            diagnostics.record(.entityRemoved, detail: id.uuidString)
            return .removed(id.uuidString)

        case .clearSession:
            placementResolver.clear()
            diagnostics.record(.sessionCleared)
            companionState = .idle
            companionRegistryID = nil
            return .cleared
        }
    }

    func setCompanionState(_ state: CompanionPresentationState) -> ARCommandResult {
        guard let companionRegistryID,
              let anchor = registry.entity(for: companionRegistryID),
              let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
            return .deferred("companion missing")
        }
        apply(state: state, to: companion)
        return .accepted("companion:\(state.rawValue)")
    }

    private func applyThreatIntensity(_ intensity: Double, to anchor: Entity) {
        guard let threat = anchor.children.first else { return }
        let bounded = Float(min(max(intensity, 0), 1))
        threat.scale = SIMD3<Float>(repeating: 0.8 + (bounded * 0.4))
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
