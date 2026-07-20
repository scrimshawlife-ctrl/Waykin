import Foundation
import WaykinCore

struct CanonicalARWorldCommandMapper {
    // Stable per-session entity identities keep discovery and pursuit updates
    // replaceable without creating parallel presentation owners.
    static let discoveryID = UUID(uuidString: "00000000-0000-0000-0000-00000000D15C")!
    static let threatID = UUID(uuidString: "00000000-0000-0000-0000-000000007A11")!

    let companionID: UUID
    let companionName: String

    func spawn(companionRuntime: CompanionRuntime) -> [ARWorldCommand] {
        [.spawnCompanion(companionPresentation(
            for: companionRuntime,
            event: nil,
            pursuitState: .inactive,
            pathRelation: .establishing,
            pathIntegrityPressure: 0
        ))]
    }

    func snapshot(
        companionRuntime: CompanionRuntime,
        pursuitState: PursuitState,
        lastEvent: WorldEvent?,
        pathRelation: PathRelation = .establishing,
        pathIntegrityPressure: Double = 0
    ) -> [ARWorldCommand] {
        var commands: [ARWorldCommand] = [
            .spawnCompanion(companionPresentation(
                for: companionRuntime,
                event: lastEvent,
                pursuitState: pursuitState,
                pathRelation: pathRelation,
                pathIntegrityPressure: pathIntegrityPressure
            ))
        ]
        switch pursuitState {
        case .noticed:
            commands.append(.spawnDiscovery(discoveryPresentation(kind: WorldEventKind.distantPresence.rawValue)))
        case .approaching, .close:
            let pursuitEvent = lastEvent.flatMap { event -> WorldEvent? in
                switch event.kind {
                case .pursuitBegins, .pursuitIntensifies: return event
                default: return nil
                }
            }
            commands.append(.spawnThreat(threatPresentation(
                kind: pursuitEvent?.kind.rawValue ?? threatKind(for: pursuitState),
                intensity: pursuitEvent?.intensity ?? threatIntensity(for: pursuitState)
            )))
        case .inactive, .fading:
            break
        }
        return commands
    }

    func update(
        companionRuntime: CompanionRuntime,
        event: WorldEvent?,
        pursuitState: PursuitState = .inactive,
        pathRelation: PathRelation = .establishing,
        pathIntegrityPressure: Double = 0
    ) -> [ARWorldCommand] {
        var commands: [ARWorldCommand] = [
            .updateCompanion(companionPresentation(
                for: companionRuntime,
                event: event,
                pursuitState: pursuitState,
                pathRelation: pathRelation,
                pathIntegrityPressure: pathIntegrityPressure
            ))
        ]

        guard let event else {
            commands.append(.removeEntity(Self.discoveryID))
            return commands
        }
        switch event.kind {
        case .distantPresence, .familiarPlaceStirs:
            commands.append(.spawnDiscovery(discoveryPresentation(for: event)))
        case .pursuitBegins:
            commands.append(.removeEntity(Self.discoveryID))
            commands.append(.spawnThreat(threatPresentation(for: event)))
        case .pursuitIntensifies:
            commands.append(.removeEntity(Self.discoveryID))
            commands.append(.updateThreat(threatPresentation(for: event)))
        case .pursuitFades:
            commands.append(.removeEntity(Self.discoveryID))
            commands.append(.removeEntity(Self.threatID))
        case .companionDrawsNear, .companionMovesAhead, .companionObserves,
             .quietInterval, .bondMoment:
            commands.append(.removeEntity(Self.discoveryID))
        }
        return commands
    }

    func clear() -> [ARWorldCommand] {
        [.clearSession]
    }

    private func companionPresentation(
        for runtime: CompanionRuntime,
        event: WorldEvent?,
        pursuitState: PursuitState,
        pathRelation: PathRelation,
        pathIntegrityPressure: Double
    ) -> CompanionPresentation {
        CompanionPresentation(
            id: companionID,
            name: companionName,
            behavior: CompanionPresentationMatrix.arBehaviorString(
                state: runtime.state,
                event: event?.kind,
                pursuitState: pursuitState,
                pathRelation: pathRelation,
                pathIntegrityPressure: pathIntegrityPressure
            ),
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: distanceBand(for: runtime.relativeDistance),
                bearing: bearing(for: runtime.state),
                scaleClass: .companion,
                persistence: .session
            )
        )
    }

    private func discoveryPresentation(for event: WorldEvent) -> DiscoveryPresentation {
        discoveryPresentation(kind: event.kind.rawValue)
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
                persistence: .transient
            )
        )
    }

    private func threatPresentation(for event: WorldEvent) -> ThreatPresentation {
        threatPresentation(kind: event.kind.rawValue, intensity: event.intensity)
    }

    private func threatPresentation(kind: String, intensity: Double) -> ThreatPresentation {
        ThreatPresentation(
            id: Self.threatID,
            kind: kind,
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

    private func threatIntensity(for state: PursuitState) -> Double {
        switch state {
        case .noticed: return 0.35
        case .approaching: return 0.65
        case .close: return 1
        case .inactive, .fading: return 0
        }
    }

    private func threatKind(for state: PursuitState) -> String {
        state == .close
            ? WorldEventKind.pursuitIntensifies.rawValue
            : WorldEventKind.pursuitBegins.rawValue
    }

    private func distanceBand(for distance: Double) -> SpatialDistanceBand {
        // These are the frozen M4 presentation distances. Invalid,
        // non-finite, and nonpositive values use the conservative near band.
        guard distance.isFinite, distance > 0 else { return .near }
        switch distance {
        case ...0.75: return .immediate
        case ...1.25: return .near
        case ...2.0: return .medium
        default: return .far
        }
    }

    private func bearing(for state: CompanionBehaviorState) -> SpatialBearingIntent {
        switch state {
        case .lead:
            return .ahead
        case .observe:
            return .contextual
        case .idle, .follow, .celebrate, .drawNear, .rest:
            return .beside
        }
    }
}
