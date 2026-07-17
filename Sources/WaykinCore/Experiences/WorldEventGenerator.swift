import Foundation

// World-event system ported from the sibling implementation's
// WorldEventGenerator, adapted to this architecture: cooldowns run on
// session-elapsed time (not wall clock) so the whole system stays
// deterministic, and familiarity comes from LocationMemory visit history.

public enum WorldEventKind: String, Codable, CaseIterable, Equatable {
    case companionDrawsNear
    case companionMovesAhead
    case companionObserves
    case distantPresence
    case pursuitBegins
    case pursuitIntensifies
    case pursuitFades
    case familiarPlaceStirs
    case quietInterval
    case bondMoment
}

public struct WorldEvent: Codable, Equatable {
    public let kind: WorldEventKind
    public let atElapsedSeconds: TimeInterval
    public let intensity: Double

    public init(kind: WorldEventKind, atElapsedSeconds: TimeInterval, intensity: Double) {
        self.kind = kind
        self.atElapsedSeconds = atElapsedSeconds
        self.intensity = min(1, max(0, intensity))
    }
}

/// The generator's view of the moment: everything normalized to 0…1.
public struct WorldSnapshot: Equatable {
    /// How vigorously the user is moving (speed + sustained-effort bonus).
    public var energy: Double
    /// Ambient narrative tension; raised/lowered by pursuit events.
    public var pressure: Double
    /// How well the companion knows this place (visit history).
    public var familiarity: Double
    public var bondPoints: Int
    public var isMoving: Bool

    public init(energy: Double, pressure: Double, familiarity: Double,
                bondPoints: Int, isMoving: Bool) {
        self.energy = min(1, max(0, energy))
        self.pressure = min(1, max(0, pressure))
        self.familiarity = min(1, max(0, familiarity))
        self.bondPoints = max(0, bondPoints)
        self.isMoving = isMoving
    }
}

public struct WorldEventRule: Codable, Equatable {
    public let kind: WorldEventKind
    public let minimumEnergy: Double
    public let minimumPressure: Double
    public let maximumPressure: Double
    public let minimumFamiliarity: Double
    public let minimumBondPoints: Int
    public let weight: UInt64
    public let cooldown: TimeInterval

    public init(kind: WorldEventKind, minimumEnergy: Double = 0,
                minimumPressure: Double = 0, maximumPressure: Double = 1,
                minimumFamiliarity: Double = 0, minimumBondPoints: Int = 0,
                weight: UInt64 = 1, cooldown: TimeInterval = 20) {
        self.kind = kind
        self.minimumEnergy = minimumEnergy
        self.minimumPressure = minimumPressure
        self.maximumPressure = maximumPressure
        self.minimumFamiliarity = minimumFamiliarity
        self.minimumBondPoints = max(0, minimumBondPoints)
        self.weight = max(1, weight)
        self.cooldown = max(0, cooldown)
    }

    /// Threshold eligibility only — cooldowns are enforced per-kind by the
    /// generator (a refinement over the original, where every rule's
    /// cooldown compared against the shared last-event time).
    public func isEligible(for snapshot: WorldSnapshot) -> Bool {
        if snapshot.energy < minimumEnergy { return false }
        if snapshot.pressure < minimumPressure { return false }
        if snapshot.pressure > maximumPressure { return false }
        if snapshot.familiarity < minimumFamiliarity { return false }
        if snapshot.bondPoints < minimumBondPoints { return false }
        return true
    }
}

public struct WorldEventConfiguration: Equatable {
    public let minimumTickSpacing: TimeInterval
    public let rules: [WorldEventRule]

    public init(minimumTickSpacing: TimeInterval = 40,
                rules: [WorldEventRule] = WorldEventConfiguration.defaultRules) {
        self.minimumTickSpacing = max(0, minimumTickSpacing)
        self.rules = rules
    }

    /// Rule table carried over unchanged from the original implementation.
    public static let defaultRules: [WorldEventRule] = [
        WorldEventRule(kind: .quietInterval, maximumPressure: 0.25, weight: 4, cooldown: 24),
        WorldEventRule(kind: .companionDrawsNear, minimumEnergy: 0.05, maximumPressure: 0.45, weight: 6, cooldown: 28),
        WorldEventRule(kind: .companionMovesAhead, minimumEnergy: 0.45, maximumPressure: 0.6, weight: 4, cooldown: 32),
        WorldEventRule(kind: .companionObserves, minimumPressure: 0.05, maximumPressure: 0.55, weight: 3, cooldown: 24),
        WorldEventRule(kind: .distantPresence, minimumPressure: 0.22, maximumPressure: 0.7, weight: 4, cooldown: 40),
        WorldEventRule(kind: .pursuitBegins, minimumEnergy: 0.25, minimumPressure: 0.32, maximumPressure: 0.78, weight: 3, cooldown: 60),
        WorldEventRule(kind: .pursuitIntensifies, minimumPressure: 0.55, weight: 3, cooldown: 45),
        WorldEventRule(kind: .pursuitFades, minimumEnergy: 0.55, minimumPressure: 0.2, maximumPressure: 0.5, weight: 2, cooldown: 42),
        WorldEventRule(kind: .familiarPlaceStirs, minimumFamiliarity: 0.35, weight: 2, cooldown: 55),
        WorldEventRule(kind: .bondMoment, minimumEnergy: 0.25, minimumBondPoints: 10, weight: 2, cooldown: 70),
    ]
}

/// SplitMix64 — deterministic RNG so a given seed replays the same walk.
public struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Weighted, cooldown-gated event picker.
public struct WorldEventGenerator {
    private var rng: SeededRandomNumberGenerator
    private let configuration: WorldEventConfiguration
    private var lastGeneratedAtElapsed: TimeInterval?
    private var lastFiredByKind: [WorldEventKind: TimeInterval] = [:]

    public init(seed: UInt64, configuration: WorldEventConfiguration = WorldEventConfiguration()) {
        rng = SeededRandomNumberGenerator(seed: seed)
        self.configuration = configuration
    }

    public mutating func evaluate(_ snapshot: WorldSnapshot, elapsed: TimeInterval) -> WorldEvent? {
        if let last = lastGeneratedAtElapsed, elapsed - last < configuration.minimumTickSpacing {
            return nil
        }

        let eligible = configuration.rules.filter { rule in
            if let lastFired = lastFiredByKind[rule.kind], elapsed - lastFired < rule.cooldown {
                return false
            }
            return rule.isEligible(for: snapshot)
        }
        guard !eligible.isEmpty else { return nil }

        let totalWeight = eligible.reduce(UInt64(0)) { $0 + $1.weight }
        let pick = rng.next() % totalWeight
        var cursor: UInt64 = 0
        let selected = eligible.first { rule in
            cursor += rule.weight
            return pick < cursor
        } ?? eligible[0]

        lastGeneratedAtElapsed = elapsed
        lastFiredByKind[selected.kind] = elapsed
        return WorldEvent(kind: selected.kind,
                          atElapsedSeconds: elapsed,
                          intensity: max(snapshot.energy, snapshot.pressure))
    }
}
