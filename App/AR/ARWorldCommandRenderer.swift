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

    // Animation state for follow only. Loaded on demand, never restarts on repeated follow updates.
    private var walkingAnimation: AnimationResource?
    private var walkController: AnimationPlaybackController?

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

    func render(_ command: ARWorldCommand, in arView: ARView) async -> ARCommandResult {
        switch command {
        case .spawnCompanion(let presentation):
            diagnostics.record(.placementAttempted, detail: "companion")
            guard let entity = await companionFactory.makeLira() else {
                diagnostics.record(.placementDeferred, detail: "companion-static-asset-unavailable")
                return .deferred("companion-static-asset-unavailable")
            }

            // Ensure walking animation is available at spawn time for full asset contract.
            // Missing walking asset or clip defers safely (no gameplay mutation).
            if walkingAnimation == nil {
                walkingAnimation = await companionFactory.loadWalkingAnimation()
            }
            if walkingAnimation == nil {
                diagnostics.record(.placementDeferred, detail: "companion-walking-animation-unavailable")
                return .deferred("companion-walking-animation-unavailable")
            }

            let elapsed = CompanionStateReducer.state(for: presentation.behavior) == companionState
                ? elapsedInCompanionState
                : 0
            let transition = CompanionStateReducer.transition(
                current: companionState,
                behavior: presentation.behavior,
                elapsed: elapsed
            )
            await applyPresentation(for: transition.resolvedState, to: entity)
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
            if replacing {
                accept(transition, elapsed: elapsed)
            } else {
                commit(transition, elapsed: elapsed)
            }
            // Ensure anim state matches resolved (in case spawn starts in follow)
            if transition.resolvedState == .follow {
                await playWalkingIfNeeded(on: entity)
            } else {
                stopWalking()
            }
            return .accepted("companion")

        case .updateCompanion(let presentation):
            guard let anchor = registry.entity(for: Self.companionID),
                  let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
                return .deferred("companion missing")
            }
            let elapsed = CompanionStateReducer.state(for: presentation.behavior) == companionState
                ? elapsedInCompanionState
                : 0
            let transition = CompanionStateReducer.transition(
                current: companionState,
                behavior: presentation.behavior,
                elapsed: elapsed
            )
            if transition.outcome == .unchanged || transition.outcome == .celebrationInProgress {
                await applyPresentation(for: transition.resolvedState, to: companion)
                accept(transition, elapsed: elapsed)
            } else {
                await apply(transition, to: companion, elapsed: elapsed)
            }
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

    func render(_ commands: [ARWorldCommand], in arView: ARView) async -> [ARCommandResult] {
        var results: [ARCommandResult] = []
        for command in commands {
            let r = await render(command, in: arView)
            results.append(r)
        }
        return results
    }

    func setCompanionState(_ state: CompanionPresentationState) async -> ARCommandResult {
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
            await applyPresentation(for: transition.resolvedState, to: companion)
            accept(transition, elapsed: elapsedInCompanionState)
            return .accepted("companion:\(transition.resolvedState.rawValue)")
        }
        await apply(transition, to: companion)
        return .accepted("companion:\(transition.resolvedState.rawValue)")
    }

    @discardableResult
    func clearSession() -> ARCommandResult {
        placementResolver.clear()
        diagnostics.record(.sessionCleared)
        companionState = .idle
        elapsedInCompanionState = 0
        lastCompanionTransition = nil
        stopWalking()
        walkingAnimation = nil
        walkController = nil
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
            // sync apply ok here as no anim
            applyPresentationSync(for: transition.resolvedState, to: companion)
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

        applyPresentationSync(for: transition.resolvedState, to: companion)
        commit(transition, elapsed: elapsed)
        return transition
    }

    private func apply(
        _ transition: CompanionStateTransition,
        to entity: Entity,
        elapsed: TimeInterval = 0
    ) async {
        await applyPresentation(for: transition.resolvedState, to: entity)
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

    private func accept(
        _ transition: CompanionStateTransition,
        elapsed: TimeInterval
    ) {
        guard transition.outcome == .unchanged || transition.outcome == .celebrationInProgress else {
            commit(transition, elapsed: elapsed)
            return
        }
        lastCompanionTransition = transition
        elapsedInCompanionState = transition.resolvedState == .celebrate && elapsed.isFinite
            ? max(0, elapsed)
            : 0
    }

    // Async presentation that also manages animation.
    private func applyPresentation(for state: CompanionPresentationState, to entity: Entity) async {
        let presentation = presentation(for: state)
        entity.position = presentation.position
        entity.orientation = presentation.orientation
        // IMPORTANT: Never overwrite the imported mesh's base scale applied once after load in factory.
        // State adjustments are position/orientation only (within bounded limits).

        entity.findEntity(named: "StatusIndicator")?.isEnabled = presentation.indicatorVisible
        entity.findEntity(named: "CoreGlow")?.isEnabled = presentation.coreVisible
        if let indicator = entity.findEntity(named: "StatusIndicator") as? ModelEntity {
            indicator.model?.materials = [
                SimpleMaterial(color: presentation.indicatorColor, isMetallic: false)
            ]
        }

        // Animation: walking clip ONLY for follow; loop while active; stop when leaving.
        // Repeated follow updates must not restart the animation.
        if state == .follow {
            await playWalkingIfNeeded(on: entity)
        } else {
            stopWalking()
        }
    }

    // Sync variant for time-advance paths (no animation side effects needed for celebrate/idle).
    private func applyPresentationSync(for state: CompanionPresentationState, to entity: Entity) {
        let presentation = presentation(for: state)
        entity.position = presentation.position
        entity.orientation = presentation.orientation
        // Do not touch scale.

        entity.findEntity(named: "StatusIndicator")?.isEnabled = presentation.indicatorVisible
        entity.findEntity(named: "CoreGlow")?.isEnabled = presentation.coreVisible
        if let indicator = entity.findEntity(named: "StatusIndicator") as? ModelEntity {
            indicator.model?.materials = [
                SimpleMaterial(color: presentation.indicatorColor, isMetallic: false)
            ]
        }
        // No animation management in sync advance (celebrate path).
    }

    private func playWalkingIfNeeded(on entity: Entity) async {
        // Avoid restarting when repeated follow updates arrive.
        if let ctrl = walkController, ctrl.isPlaying {
            return
        }
        if walkingAnimation == nil {
            walkingAnimation = await companionFactory.loadWalkingAnimation()
        }
        guard let anim = walkingAnimation else {
            diagnostics.record(.error, detail: "companion-animation-unavailable")
            return
        }
        stopWalking()
        walkController = entity.playAnimation(anim, transitionDuration: 0.15)
    }

    private func stopWalking() {
        walkController?.stop()
        walkController = nil
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
