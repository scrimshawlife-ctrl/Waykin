import RealityKit
import WaykinCore

@MainActor
final class ARWorldCommandRenderer {
    enum Result: String, Equatable, Sendable {
        case accepted
        case deferred
        case removed
        case cleared
    }

    private let registry: AREntityRegistry
    private let placementResolver: ARPlacementResolver
    private let animator = CompanionAnimator()
    private let diagnostics: ARDiagnosticRecorder

    init(registry: AREntityRegistry, diagnostics: ARDiagnosticRecorder) {
        self.registry = registry
        self.placementResolver = ARPlacementResolver(registry: registry)
        self.diagnostics = diagnostics
    }

    @discardableResult
    func render(_ command: ARWorldCommand, in arView: ARView) -> Result {
        switch command {
        case .spawnCompanion(let presentation):
            let id = presentation.id.uuidString
            let replacing = registry.entity(for: id) != nil
            diagnostics.record(.placementAttempted, detail: "companion")
            let lira = CompanionEntityFactory.makeLira()
            let state = CompanionStateReducer.state(for: presentation.behavior)
            animator.apply(state, to: lira, animated: false)
            guard placementResolver.place(entity: lira, id: id, intent: presentation.spatialIntent, in: arView) else {
                diagnostics.record(.placementFailed, detail: "companion")
                return .deferred
            }
            diagnostics.record(replacing ? .entityReplaced : .entityCreated, detail: "companion")
            diagnostics.record(.placementSucceeded, detail: "companion")
            diagnostics.record(.stateChanged, detail: state.rawValue)
            return .accepted

        case .updateCompanion(let presentation):
            let id = presentation.id.uuidString
            guard let anchor = registry.entity(for: id), let lira = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
                return render(.spawnCompanion(presentation), in: arView)
            }
            let state = CompanionStateReducer.state(for: presentation.behavior)
            animator.apply(state, to: lira)
            diagnostics.record(.stateChanged, detail: state.rawValue)
            return .accepted

        case .spawnDiscovery(let presentation):
            diagnostics.record(.placementAttempted, detail: "discovery")
            let success = placementResolver.placePlaceholder(
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
            diagnostics.record(success ? .placementSucceeded : .placementFailed, detail: "discovery")
            return success ? .accepted : .deferred

        case .spawnThreat(let presentation), .updateThreat(let presentation):
            diagnostics.record(.placementAttempted, detail: "threat")
            let success = placementResolver.placePlaceholder(
                id: presentation.id.uuidString,
                intent: presentation.spatialIntent,
                in: arView
            )
            diagnostics.record(success ? .placementSucceeded : .placementFailed, detail: "threat")
            return success ? .accepted : .deferred

        case .removeEntity(let id):
            placementResolver.remove(id: id.uuidString)
            diagnostics.record(.entityRemoved, detail: id.uuidString)
            return .removed

        case .clearSession:
            placementResolver.clear()
            diagnostics.record(.sessionCleared)
            return .cleared
        }
    }
}
