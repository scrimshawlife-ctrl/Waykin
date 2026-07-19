import RealityKit
import UIKit
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
    private(set) var lastCompanionTransition: CompanionStateTransition?
    private var elapsedInCompanionState: TimeInterval = 0

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
            let transition = CompanionStateReducer.transition(
                current: companionState,
                behavior: presentation.behavior,
                elapsed: 0
            )
            applyPresentation(for: transition.resolvedState, to: entity)
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
            commit(transition)
            return .accepted("companion")

        case .updateCompanion(let presentation):
            guard let anchor = registry.entity(for: Self.companionID),
                  let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
                return .deferred("companion missing")
            }
            let transition = CompanionStateReducer.transition(
                current: companionState,
                behavior: presentation.behavior,
                elapsed: 0
            )
            apply(transition, to: companion)
            return .accepted("companion:\(transition.resolvedState.rawValue)")

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
            return clearSession()
        }
    }

    func setCompanionState(_ state: CompanionPresentationState) -> ARCommandResult {
        guard let anchor = registry.entity(for: Self.companionID),
              let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
            return .deferred("companion missing")
        }
        let transition = CompanionStateReducer.transition(
            current: companionState,
            requested: state,
            elapsed: state == companionState ? elapsedInCompanionState : 0
        )
        if transition.outcome == .unchanged || transition.outcome == .celebrationInProgress {
            applyPresentation(for: transition.resolvedState, to: companion)
            lastCompanionTransition = transition
            return .accepted("companion:\(transition.resolvedState.rawValue)")
        }
        apply(transition, to: companion)
        return .accepted("companion:\(transition.resolvedState.rawValue)")
    }

    @discardableResult
    func clearSession() -> ARCommandResult {
        placementResolver.clear()
        diagnostics.record(.sessionCleared)
        companionState = .idle
        elapsedInCompanionState = 0
        lastCompanionTransition = nil
        return .cleared
    }

    @discardableResult
    func advanceCompanionPresentation(by delta: TimeInterval) -> CompanionStateTransition? {
        guard companionState == .celebrate else { return nil }
        guard let anchor = registry.entity(for: Self.companionID),
              let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
            return nil
        }

        guard delta.isFinite, delta >= 0 else {
            let transition = CompanionStateReducer.transition(
                current: companionState,
                requested: companionState,
                elapsed: delta
            )
            apply(transition, to: companion)
            return transition
        }

        let elapsed = elapsedInCompanionState + delta
        let transition = CompanionStateReducer.transition(
            current: companionState,
            requested: companionState,
            elapsed: elapsed
        )

        if transition.outcome == .celebrationInProgress {
            lastCompanionTransition = transition
            elapsedInCompanionState = elapsed
            return transition
        }

        apply(transition, to: companion, elapsed: elapsed)
        return transition
    }

    private func apply(
        _ transition: CompanionStateTransition,
        to entity: Entity,
        elapsed: TimeInterval = 0
    ) {
        applyPresentation(for: transition.resolvedState, to: entity)
        commit(transition, elapsed: elapsed)
    }

    private func commit(
        _ transition: CompanionStateTransition,
        elapsed: TimeInterval = 0
    ) {
        lastCompanionTransition = transition
        companionState = transition.resolvedState
        elapsedInCompanionState = transition.resolvedState == transition.previousState
            && elapsed.isFinite
            ? max(0, elapsed)
            : 0
        diagnostics.record(.stateChanged, detail: transition.resolvedState.rawValue)
    }

    private func applyPresentation(for state: CompanionPresentationState, to entity: Entity) {
        let presentation = presentation(for: state)
        entity.position = presentation.position
        entity.scale = presentation.scale
        entity.orientation = presentation.orientation

        entity.findEntity(named: "StatusIndicator")?.isEnabled = presentation.indicatorVisible
        entity.findEntity(named: "CoreGlow")?.isEnabled = presentation.coreVisible
        if let indicator = entity.findEntity(named: "StatusIndicator") as? ModelEntity {
            indicator.model?.materials = [
                SimpleMaterial(color: presentation.indicatorColor, isMetallic: false)
            ]
        }
    }

    private func presentation(for state: CompanionPresentationState) -> Presentation {
        switch state {
        case .idle:
            Presentation(
                position: [0, 0, 0],
                scale: SIMD3<Float>(repeating: 1),
                orientation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                indicatorVisible: false,
                coreVisible: true,
                indicatorColor: .white
            )
        case .follow:
            Presentation(
                position: [0, 0, 0.12],
                scale: SIMD3<Float>(repeating: 1.02),
                orientation: simd_quatf(angle: 0.18, axis: [0, 1, 0]),
                indicatorVisible: false,
                coreVisible: true,
                indicatorColor: .systemBlue
            )
        case .investigate:
            Presentation(
                position: [-0.08, 0, 0],
                scale: SIMD3<Float>(1, 0.92, 1.08),
                orientation: simd_quatf(angle: -0.22, axis: [1, 0, 0]),
                indicatorVisible: true,
                coreVisible: true,
                indicatorColor: .systemYellow
            )
        case .alert:
            Presentation(
                position: [0, 0, -0.10],
                scale: SIMD3<Float>(1.05, 1.14, 0.96),
                orientation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                indicatorVisible: true,
                coreVisible: true,
                indicatorColor: .systemRed
            )
        case .celebrate:
            Presentation(
                position: [0, 0.10, 0],
                scale: SIMD3<Float>(repeating: 1.12),
                orientation: simd_quatf(angle: .pi / 5, axis: [0, 1, 0]),
                indicatorVisible: true,
                coreVisible: true,
                indicatorColor: .systemGreen
            )
        }
    }

    private struct Presentation {
        let position: SIMD3<Float>
        let scale: SIMD3<Float>
        let orientation: simd_quatf
        let indicatorVisible: Bool
        let coreVisible: Bool
        let indicatorColor: UIColor
    }
}
