import Foundation

public struct WorldEventRule: Codable, Equatable, Sendable {
    public let kind: WorldEventKind
    public let minimumEnergy: Double
    public let minimumPressure: Double
    public let maximumPressure: Double
    public let minimumFamiliarity: Double
    public let minimumBondLevel: Int
    public let weight: UInt64
    public let cooldown: TimeInterval

    public init(
        kind: WorldEventKind,
        minimumEnergy: Double = 0,
        minimumPressure: Double = 0,
        maximumPressure: Double = 1,
        minimumFamiliarity: Double = 0,
        minimumBondLevel: Int = 0,
        weight: UInt64 = 1,
        cooldown: TimeInterval = 20
    ) {
        self.kind = kind
        self.minimumEnergy = minimumEnergy.clamped01
        self.minimumPressure = minimumPressure.clamped01
        self.maximumPressure = maximumPressure.clamped01
        self.minimumFamiliarity = minimumFamiliarity.clamped01
        self.minimumBondLevel = max(0, minimumBondLevel)
        self.weight = max(1, weight)
        self.cooldown = max(0, cooldown)
    }

    public func isEligible(for state: WorldState, now: Date) -> Bool {
        if state.energy < minimumEnergy { return false }
        if state.pressure < minimumPressure { return false }
        if state.pressure > maximumPressure { return false }
        if state.familiarity < minimumFamiliarity { return false }
        if state.bondLevel < minimumBondLevel { return false }
        if let last = state.lastEventAt, now.timeIntervalSince(last) < cooldown { return false }
        return state.movementState == .moving || state.movementState == .paused
    }
}

public struct WorldEventGeneratorConfiguration: Codable, Equatable, Sendable {
    public let minimumTickSpacing: TimeInterval
    public let rules: [WorldEventRule]

    public init(minimumTickSpacing: TimeInterval = 40, rules: [WorldEventRule] = WorldEventGeneratorConfiguration.defaultRules) {
        self.minimumTickSpacing = max(0, minimumTickSpacing)
        self.rules = rules
    }

    public static let defaultRules: [WorldEventRule] = [
        WorldEventRule(kind: .quietInterval, minimumEnergy: 0, maximumPressure: 0.25, weight: 4, cooldown: 24),
        WorldEventRule(kind: .companionDrawsNear, minimumEnergy: 0.05, maximumPressure: 0.45, weight: 6, cooldown: 28),
        WorldEventRule(kind: .companionMovesAhead, minimumEnergy: 0.45, maximumPressure: 0.6, weight: 4, cooldown: 32),
        WorldEventRule(kind: .companionObserves, minimumEnergy: 0, minimumPressure: 0.05, maximumPressure: 0.55, weight: 3, cooldown: 24),
        WorldEventRule(kind: .distantPresence, minimumPressure: 0.22, maximumPressure: 0.7, weight: 4, cooldown: 40),
        WorldEventRule(kind: .pursuitBegins, minimumEnergy: 0.25, minimumPressure: 0.32, maximumPressure: 0.78, weight: 3, cooldown: 60),
        WorldEventRule(kind: .pursuitIntensifies, minimumPressure: 0.55, maximumPressure: 1, weight: 3, cooldown: 45),
        WorldEventRule(kind: .pursuitFades, minimumEnergy: 0.55, minimumPressure: 0.2, maximumPressure: 0.5, weight: 2, cooldown: 42),
        WorldEventRule(kind: .familiarPlaceStirs, minimumFamiliarity: 0.35, weight: 2, cooldown: 55),
        WorldEventRule(kind: .bondMoment, minimumEnergy: 0.25, minimumBondLevel: 10, weight: 2, cooldown: 70)
    ]
}

public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public struct WorldEventGenerator: Sendable {
    private var rng: SeededRandomNumberGenerator
    private let configuration: WorldEventGeneratorConfiguration
    private var lastGeneratedAt: Date?

    public init(seed: UInt64, configuration: WorldEventGeneratorConfiguration = WorldEventGeneratorConfiguration()) {
        self.rng = SeededRandomNumberGenerator(seed: seed)
        self.configuration = configuration
    }

    public mutating func evaluate(state: WorldState, now: Date) -> WorldEvent? {
        if let lastGeneratedAt, now.timeIntervalSince(lastGeneratedAt) < configuration.minimumTickSpacing {
            return nil
        }

        let eligible = configuration.rules.filter { $0.isEligible(for: state, now: now) }
        guard !eligible.isEmpty else { return nil }

        let totalWeight = eligible.reduce(UInt64(0)) { $0 + $1.weight }
        let pick = rng.next() % totalWeight
        var cursor: UInt64 = 0
        let selected = eligible.first { rule in
            cursor += rule.weight
            return pick < cursor
        } ?? eligible[0]

        lastGeneratedAt = now
        return WorldEvent(
            kind: selected.kind,
            occurredAt: now,
            intensity: max(state.energy, state.pressure),
            debugLabel: selected.kind.rawValue
        )
    }
}

extension Double {
    var clamped01: Double {
        guard isFinite else { return 0 }
        return min(1, max(0, self))
    }

    var finiteOrZero: Double {
        isFinite ? self : 0
    }
}
