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
    private let assetLoader: LiraARAssetLoader
    private let diagnostics: ARDiagnosticRecorder
    private let skeletalPlayer = LiraSkeletalPlayer()

    private(set) var companionState: CompanionPresentationState = .idle
    private(set) var lastCompanionTransition: CompanionStateTransition?
    private var elapsedInCompanionState: TimeInterval = 0
    /// Accumulated time for A2/A3 local loops (breath / sway). Reset on clear.
    private(set) var localMotionElapsed: TimeInterval = 0
    /// Time since last successful companion spawn (A4 coalesce). Reset on clear / replace spawn.
    private(set) var spawnCoalesceElapsed: TimeInterval = 0
    private var isSpawningCoalesce = false

    /// When true (default), install joint-hierarchy skeletal clips on spawn and
    /// drive ambient joints via RealityKit playback instead of pure-function locals.
    /// Hunter echo + spawn scale always remain procedural.
    var skeletalPlaybackEnabled: Bool = true

    /// Cosmetic Lira skin applied on next spawn.
    var companionSkin: LiraSkin {
        get { assetLoader.skin }
        set { assetLoader.skin = newValue }
    }

    /// Runtime LOD source (procedural vs preloaded USDZ).
    var companionLODDescription: String { assetLoader.activeLODDescription }

    /// Whether skeletal AnimationLibrary is installed and driving ambient joints.
    var isSkeletalDriving: Bool { skeletalPlayer.isDriving }

    /// Active skeletal clip id when driving, else nil.
    var activeSkeletalClip: LiraSkeletalAnimationLibrary.ClipID? { skeletalPlayer.activeClip }

    init(
        registry: AREntityRegistry,
        diagnostics: ARDiagnosticRecorder,
        companionFactory: CompanionEntityFactory? = nil,
        assetLoader: LiraARAssetLoader? = nil
    ) {
        self.registry = registry
        self.placementResolver = ARPlacementResolver(registry: registry)
        self.diagnostics = diagnostics
        if let assetLoader {
            self.assetLoader = assetLoader
            if let companionFactory {
                self.assetLoader.skin = companionFactory.skin
            }
        } else {
            let loader = LiraARAssetLoader()
            loader.skin = companionFactory?.skin ?? .dawn
            self.assetLoader = loader
        }
    }

    func render(_ command: ARWorldCommand, in arView: ARView) -> ARCommandResult {
        switch command {
        case .spawnCompanion(let presentation):
            diagnostics.record(.placementAttempted, detail: "companion")
            let entity = assetLoader.makeLira()
            prepareSkeletalPlayback(on: entity)
            let elapsed = CompanionStateReducer.state(for: presentation.behavior) == companionState
                ? elapsedInCompanionState
                : 0
            let transition = CompanionStateReducer.transition(
                current: companionState,
                behavior: presentation.behavior,
                elapsed: elapsed
            )
            // A4: restart coalesce on every successful spawn/replace attempt prep.
            spawnCoalesceElapsed = 0
            isSpawningCoalesce = true
            applyPresentation(for: transition.resolvedState, to: entity)
            let replacing = registry.entity(for: Self.companionID) != nil
            guard placementResolver.place(
                id: Self.companionID,
                intent: presentation.spatialIntent,
                entity: entity,
                in: arView
            ) else {
                diagnostics.record(.placementDeferred, detail: "companion")
                isSpawningCoalesce = false
                skeletalPlayer.clear()
                return .deferred("companion")
            }
            diagnostics.record(replacing ? .entityReplaced : .entityCreated, detail: "companion")
            diagnostics.record(.placementSucceeded, detail: "companion")
            // Ambient skeletal clip for resolved state (spawn scale stays procedural).
            if skeletalPlayer.isDriving {
                skeletalPlayer.play(state: transition.resolvedState, on: entity)
            }
            if replacing {
                accept(transition, elapsed: elapsed)
            } else {
                commit(transition, elapsed: elapsed)
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
                applyPresentation(for: transition.resolvedState, to: companion)
                accept(transition, elapsed: elapsed)
            } else {
                apply(transition, to: companion, elapsed: elapsed)
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

    func render(_ commands: [ARWorldCommand], in arView: ARView) -> [ARCommandResult] {
        commands.map { render($0, in: arView) }
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
            accept(transition, elapsed: elapsedInCompanionState)
            return .accepted("companion:\(transition.resolvedState.rawValue)")
        }
        apply(transition, to: companion)
        return .accepted("companion:\(transition.resolvedState.rawValue)")
    }

    @discardableResult
    func clearSession() -> ARCommandResult {
        skeletalPlayer.clear()
        placementResolver.clear()
        diagnostics.record(.sessionCleared)
        companionState = .idle
        elapsedInCompanionState = 0
        localMotionElapsed = 0
        spawnCoalesceElapsed = 0
        isSpawningCoalesce = false
        lastCompanionTransition = nil
        return .cleared
    }

    /// Advance A2 breath, A3 filament sway / hunter echo, A4 spawn coalesce.
    /// Safe no-op without companion.
    func advanceLocalMotion(by delta: TimeInterval) {
        guard delta.isFinite, delta >= 0 else { return }
        localMotionElapsed += delta
        if isSpawningCoalesce {
            spawnCoalesceElapsed += delta
            let progress = LiraARMotion.spawnCoalesceProgress(
                elapsed: spawnCoalesceElapsed,
                duration: LiraARMotion.spawnCoalesceDuration
            )
            if progress >= 1 {
                isSpawningCoalesce = false
            }
        }
        guard let anchor = registry.entity(for: Self.companionID),
              let companion = anchor.findEntity(named: CompanionEntityFactory.rootName) else {
            return
        }
        if skeletalPlayer.isDriving {
            applyHunterEcho(to: companion, state: companionState, elapsed: localMotionElapsed)
        } else {
            applyLocalMotion(to: companion, state: companionState, elapsed: localMotionElapsed)
        }
        applySpawnCoalesce(to: companion, state: companionState)
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

    private func applyPresentation(for state: CompanionPresentationState, to entity: Entity) {
        let presentation = presentation(for: state)
        entity.position = presentation.position
        entity.orientation = presentation.orientation
        applySpawnCoalesce(to: entity, state: state)

        entity.findEntity(named: "StatusIndicator")?.isEnabled = presentation.indicatorVisible
        entity.findEntity(named: "CoreGlow")?.isEnabled = presentation.coreVisible
        if let indicator = entity.findEntity(named: "StatusIndicator") as? ModelEntity {
            indicator.model?.materials = [
                SimpleMaterial(color: presentation.indicatorColor, isMetallic: false)
            ]
        }
        if skeletalPlayer.isDriving {
            skeletalPlayer.play(state: state, on: entity)
            // Hunter echo remains procedural; ambient joints owned by skeletal clips.
            applyHunterEcho(to: entity, state: state, elapsed: localMotionElapsed)
        } else {
            applyLocalMotion(to: entity, state: state, elapsed: localMotionElapsed)
        }
    }

    private func prepareSkeletalPlayback(on entity: Entity) {
        skeletalPlayer.clear()
        guard skeletalPlaybackEnabled else { return }
        _ = skeletalPlayer.install(on: entity)
    }

    private func applySpawnCoalesce(to entity: Entity, state: CompanionPresentationState) {
        let base = presentation(for: state).scale
        let progress: Float
        if isSpawningCoalesce {
            progress = LiraARMotion.spawnCoalesceProgress(
                elapsed: spawnCoalesceElapsed,
                duration: LiraARMotion.spawnCoalesceDuration
            )
        } else {
            progress = 1
        }
        let factor = LiraARMotion.spawnScaleFactor(progress: progress)
        entity.scale = base * factor
    }

    private func applyLocalMotion(
        to entity: Entity,
        state: CompanionPresentationState,
        elapsed: TimeInterval
    ) {
        if let core = entity.findEntity(named: "CoreGlow"), core.isEnabled {
            let breath = LiraARMotion.coreBreathScale(elapsed: elapsed, state: state)
            core.scale = SIMD3<Float>(repeating: breath)
        }
        if let halo = entity.findEntity(named: "CoreHalo"), halo.isEnabled {
            let breath = LiraARMotion.coreBreathScale(elapsed: elapsed, state: state)
            halo.scale = SIMD3<Float>(repeating: breath * 1.15)
        }

        // A3 filament base + multi-segment wave
        if let filament = entity.findEntity(named: "Filament") {
            filament.orientation = LiraARMotion.filamentOrientation(elapsed: elapsed, state: state)
            if let mid = filament.findEntity(named: LiraARMotion.filamentMidName) {
                let pitch = LiraARMotion.filamentSegmentPitch(elapsed: elapsed, segmentIndex: 1, state: state)
                mid.orientation = simd_quatf(angle: pitch, axis: [1, 0, 0])
            }
            if let tip = filament.findEntity(named: LiraARMotion.filamentTipName) {
                let pitch = LiraARMotion.filamentSegmentPitch(elapsed: elapsed, segmentIndex: 2, state: state)
                tip.orientation = simd_quatf(angle: pitch, axis: [1, 0.05, 0])
            }
        }

        // A1 head attention
        if let head = entity.findEntity(named: "Head") {
            head.orientation = LiraARMotion.headOrientation(elapsed: elapsed, state: state)
        }

        // Ears / tail / body bob
        if let left = entity.findEntity(named: "LeftEar") {
            left.orientation = LiraARMotion.earOrientation(elapsed: elapsed, isLeft: true, state: state)
        }
        if let right = entity.findEntity(named: "RightEar") {
            right.orientation = LiraARMotion.earOrientation(elapsed: elapsed, isLeft: false, state: state)
        }
        if let tail = entity.findEntity(named: "Tail") {
            tail.orientation = LiraARMotion.tailOrientation(elapsed: elapsed, state: state)
        }
        if let body = entity.findEntity(named: "Body") {
            var p = body.position
            p.y = LiraARMotion.bodyPositionY(elapsed: elapsed, state: state)
            body.position = p
        }

        applyHunterEcho(to: entity, state: state, elapsed: elapsed)
    }

    private func applyHunterEcho(
        to entity: Entity,
        state: CompanionPresentationState,
        elapsed: TimeInterval
    ) {
        if let echo = entity.findEntity(named: LiraARMotion.hunterEchoNodeName) {
            let show = LiraARMotion.showsHunterEcho(state: state)
            echo.isEnabled = show
            if show {
                echo.position = LiraARMotion.hunterEchoPosition(elapsed: elapsed)
            }
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
