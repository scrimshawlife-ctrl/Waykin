import Foundation

/// Single source of truth for companion-visible presentation (#139, #142).
/// Aligns experience commands, runtime event apply, AR mapper inputs, and tests.
public enum CompanionPresentationMatrix {
    public struct Resolved: Equatable, Sendable {
        public let behavior: CompanionBehaviorState
        public let relativeDistance: Double

        public init(behavior: CompanionBehaviorState, relativeDistance: Double) {
            self.behavior = behavior
            self.relativeDistance = relativeDistance
        }
    }

    /// Resolve behavior + relative distance for a walk tick.
    public static func resolve(event: WorldEvent?, moving: Bool) -> Resolved {
        guard let event else {
            return moving
                ? Resolved(behavior: .follow, relativeDistance: 1.8)
                : Resolved(behavior: .observe, relativeDistance: 2.5)
        }
        return resolve(eventKind: event.kind)
    }

    public static func resolve(eventKind: WorldEventKind) -> Resolved {
        switch eventKind {
        case .companionDrawsNear, .bondMoment:
            return Resolved(behavior: .drawNear, relativeDistance: 1.2)
        case .companionMovesAhead, .pursuitFades:
            return Resolved(behavior: .lead, relativeDistance: 4.0)
        case .quietInterval:
            // Settled presence — must agree across experience + runtime (#139).
            return Resolved(behavior: .rest, relativeDistance: 2.0)
        case .companionObserves, .familiarPlaceStirs, .distantPresence:
            return Resolved(behavior: .observe, relativeDistance: 2.5)
        case .pursuitBegins, .pursuitIntensifies:
            return Resolved(behavior: .follow, relativeDistance: 1.8)
        }
    }

    /// AR presentation string (renderer vocabulary). Spatial distance/bearing carry lead/rest.
    public static func arBehaviorString(
        state: CompanionBehaviorState,
        event: WorldEventKind?,
        pursuitState: PursuitState = .inactive,
        pathRelation: PathRelation = .establishing,
        pathIntegrityPressure: Double = 0
    ) -> String {
        // High-priority event overlays first.
        switch event {
        case .bondMoment:
            return "celebrate"
        case .pursuitBegins, .pursuitIntensifies:
            return "alert"
        case .quietInterval:
            // Settled / sanctuary lean — not investigate (#139).
            return "idle"
        case .companionObserves, .distantPresence, .familiarPlaceStirs:
            return "investigate"
        case .companionDrawsNear:
            return "follow"
        case .companionMovesAhead, .pursuitFades:
            // Lead/far conveyed by distance band + ahead bearing, not a separate AR enum.
            return "follow"
        case nil:
            break
        }

        // Path integrity soft bias when pursuit is quiet — presentation only (#141).
        if pursuitState == .inactive || pursuitState == .fading {
            if pathRelation == .offPath || pathIntegrityPressure >= 0.7 {
                return "alert"
            }
            if pathRelation == .strained || pathIntegrityPressure >= 0.4 {
                return "investigate"
            }
        }

        switch state {
        case .idle, .rest:
            return "idle"
        case .follow, .lead, .drawNear:
            return "follow"
        case .observe:
            return "investigate"
        case .celebrate:
            return "celebrate"
        }
    }
}
