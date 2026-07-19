import Foundation
import RealityKit
import WaykinCore

// WAYKIN-42: canonical Companion Walk runtime -> AR presentation bridge.
//
//   canonical companion/event state
//     -> existing ARWorldCommand values (spawnCompanion / updateCompanion /
//        clearSession — no new command shapes)
//     -> merged ARWorldCommandRenderer (sole presentation owner, PR #40)
//
// The bridge is a pure projector plus a thin dispatcher. It never stores
// presentation state of its own (spawn-vs-update derives from the entity
// registry), never mutates canonical values (inputs arrive as value
// copies), and never feeds anything back into gameplay. AR stays optional
// and presentation-only.
@MainActor
final class CanonicalCompanionARBridge {
    /// One Lira identity: a fixed presentation id, paired with the
    /// renderer's fixed registry key. Fixed (not random) so identical
    /// canonical sequences produce identical command values.
    static let liraPresentationID = UUID(uuidString: "6C1FA9E2-35B7-4A3D-9B41-000000000042")!
    static let companionName = "Lira"

    private let renderer: ARWorldCommandRenderer
    private let registry: AREntityRegistry

    private(set) var lastCommand: ARWorldCommand?
    private(set) var lastResult: ARCommandResult?

    init(renderer: ARWorldCommandRenderer, registry: AREntityRegistry) {
        self.renderer = renderer
        self.registry = registry
    }

    // MARK: Pure projection (canonical vocabulary -> presentation vocabulary)

    /// Deterministic projection of canonical companion behavior (7 states)
    /// onto the merged presentation vocabulary (5 states). Every canonical
    /// state maps to a native presentation raw value on purpose — the
    /// reducer's unknown-input fallback stays reserved for genuinely
    /// unknown inputs, and canonical `lead`/`rest` are deliberate mappings,
    /// not accidents:
    ///   idle -> idle, follow -> follow, drawNear -> follow (approach),
    ///   lead -> follow (locomotion presentation), observe -> investigate,
    ///   rest -> idle (settled presentation), celebrate -> celebrate.
    ///
    /// Pursuit-class and bond events override the companion state for the
    /// presentation only — the canonical event model already exists; this
    /// adds no event semantics.
    static func presentationBehavior(
        for state: CompanionBehaviorState,
        lastEvent: WorldEventKind? = nil
    ) -> String {
        switch lastEvent {
        case .pursuitBegins, .pursuitIntensifies:
            return CompanionPresentationState.alert.rawValue
        case .bondMoment:
            return CompanionPresentationState.celebrate.rawValue
        default:
            break
        }

        switch state {
        case .idle, .rest: return CompanionPresentationState.idle.rawValue
        case .follow, .drawNear, .lead: return CompanionPresentationState.follow.rawValue
        case .observe: return CompanionPresentationState.investigate.rawValue
        case .celebrate: return CompanionPresentationState.celebrate.rawValue
        }
    }

    /// Canonical relative distance (meters) -> existing spatial band.
    /// Total and deterministic: NaN lands on the default band; infinities
    /// flow through the range logic (+inf -> far).
    static func distanceBand(forRelativeDistance distance: Double) -> SpatialDistanceBand {
        guard !distance.isNaN else { return .near }
        switch distance {
        case ..<1.0: return .immediate
        case ..<2.0: return .near
        case ..<4.0: return .medium
        default: return .far
        }
    }

    static func presentation(
        state: CompanionBehaviorState,
        lastEvent: WorldEventKind?,
        relativeDistance: Double
    ) -> CompanionPresentation {
        CompanionPresentation(
            id: liraPresentationID,
            name: companionName,
            behavior: presentationBehavior(for: state, lastEvent: lastEvent),
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: distanceBand(forRelativeDistance: relativeDistance),
                bearing: .ahead,
                scaleClass: .companion,
                persistence: .session
            )
        )
    }

    // MARK: Dispatch (existing commands, existing renderer)

    /// Project the canonical runtime into one ARWorldCommand and route it
    /// through the merged renderer. Spawns when no Lira is placed yet
    /// (or after a clear), updates otherwise. Returns the renderer's result
    /// verbatim; a deferred spawn simply retries on the next sync.
    @discardableResult
    func sync(
        companion runtime: CompanionRuntime,
        lastEvent: WorldEvent? = nil,
        in arView: ARView
    ) -> ARCommandResult {
        let presentation = Self.presentation(
            state: runtime.state,
            lastEvent: lastEvent?.kind,
            relativeDistance: runtime.relativeDistance
        )
        let liraIsPlaced = registry.entity(for: ARWorldCommandRenderer.companionID) != nil
        let command: ARWorldCommand = liraIsPlaced
            ? .updateCompanion(presentation)
            : .spawnCompanion(presentation)
        let result = renderer.render(command, in: arView)
        lastCommand = command
        lastResult = result
        return result
    }

    /// Clearing goes through the renderer's own cleanup path so entity
    /// removal, diagnostics, and presentation reset stay single-owner.
    @discardableResult
    func clear() -> ARCommandResult {
        let result = renderer.clearSession()
        lastCommand = .clearSession
        lastResult = result
        return result
    }
}
