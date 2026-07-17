import Foundation
import WaykinCore

struct ARCompanionRuntimeAdapter {
    static let companionID = UUID(uuidString: "8D67F970-A1B0-4C36-9EA1-92D8A97F7630")!
    static let discoveryID = UUID(uuidString: "A32856C4-C46B-45F4-AEF0-2BC9E030E09A")!
    static let threatID = UUID(uuidString: "DFA4F49C-7EEB-4CB5-9627-28EFC30C6690")!

    func companionCommand(
        runtime: CompanionRuntime,
        event: WorldEvent?,
        replacingExisting: Bool
    ) -> ARWorldCommand {
        let presentation = CompanionPresentation(
            id: Self.companionID,
            name: "Lira",
            behavior: presentationState(runtime: runtime, event: event).rawValue,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: distanceBand(for: runtime.relativeDistance),
                bearing: bearing(for: runtime.state, event: event),
                scaleClass: .companion,
                persistence: .session
            )
        )
        return replacingExisting ? .updateCompanion(presentation) : .spawnCompanion(presentation)
    }

    func eventCommands(for event: WorldEvent?) -> [ARWorldCommand] {
        guard let event else { return [] }
        switch event.kind {
        case .companionObserves, .familiarPlaceStirs, .quietInterval:
            return [.spawnDiscovery(discoveryPresentation(kind: event.kind.rawValue))]
        case .distantPresence, .pursuitBegins, .pursuitIntensifies:
            return [.spawnThreat(threatPresentation(for: event.kind))]
        case .pursuitFades:
            return [.removeEntity(Self.threatID)]
        case .companionDrawsNear, .companionMovesAhead, .bondMoment:
            return []
        }
    }

    func presentationState(for state: CompanionBehaviorState) -> CompanionPresentationState {
        switch state {
        case .idle, .rest:
            return .idle
        case .follow, .lead:
            return .follow
        case .observe:
            return .investigate
        case .drawNear:
            return .alert
        case .celebrate:
            return .celebrate
        }
    }

    func presentationState(
        runtime: CompanionRuntime,
        event: WorldEvent?
    ) -> CompanionPresentationState {
        guard let event else { return presentationState(for: runtime.state) }
        switch event.kind {
        case .companionObserves, .familiarPlaceStirs, .quietInterval, .distantPresence:
            return .investigate
        case .companionDrawsNear:
            return .alert
        case .companionMovesAhead, .pursuitFades:
            return .follow
        case .pursuitBegins, .pursuitIntensifies:
            return .alert
        case .bondMoment:
            return .celebrate
        }
    }

    private func distanceBand(for relativeDistance: Double) -> SpatialDistanceBand {
        switch relativeDistance {
        case ..<1.5: return .immediate
        case ..<3.0: return .near
        case ..<5.0: return .medium
        default: return .far
        }
    }

    private func bearing(for state: CompanionBehaviorState, event: WorldEvent?) -> SpatialBearingIntent {
        if event?.kind == .pursuitBegins || event?.kind == .pursuitIntensifies {
            return .ahead
        }
        switch state {
        case .lead: return .ahead
        case .drawNear: return .beside
        case .idle, .follow, .celebrate, .observe, .rest: return .contextual
        }
    }

    private func discoveryPresentation(kind: String) -> DiscoveryPresentation {
        DiscoveryPresentation(
            id: Self.discoveryID,
            kind: kind,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .contextual,
                scaleClass: .discovery,
                persistence: .encounter
            )
        )
    }

    private func threatPresentation(for kind: WorldEventKind) -> ThreatPresentation {
        let intensity: Double = kind == .pursuitIntensifies ? 0.85 : 0.55
        return ThreatPresentation(
            id: Self.threatID,
            kind: kind.rawValue,
            intensity: intensity,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .medium,
                bearing: .ahead,
                scaleClass: .threat,
                persistence: .encounter
            )
        )
    }
}
