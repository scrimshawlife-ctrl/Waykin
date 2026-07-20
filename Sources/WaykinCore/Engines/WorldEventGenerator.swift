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
        guard meetsThresholds(for: state) else { return false }
        if let last = state.lastEventAt, now.timeIntervalSince(last) < cooldown { return false }
        return state.movementState == .moving || state.movementState == .paused
    }

    func isEligible(
        for state: WorldState,
        elapsed: TimeInterval,
        lastFiredAtElapsed: TimeInterval?
    ) -> Bool {
        guard meetsThresholds(for: state) else { return false }
        if let lastFiredAtElapsed, elapsed - lastFiredAtElapsed < cooldown { return false }
        return state.movementState == .moving || state.movementState == .paused
    }

    private func meetsThresholds(for state: WorldState) -> Bool {
        if state.energy < minimumEnergy { return false }
        if state.pressure < minimumPressure { return false }
        if state.pressure > maximumPressure { return false }
        if state.familiarity < minimumFamiliarity { return false }
        if state.bondLevel < minimumBondLevel { return false }
        return true
    }
}

public struct WorldEventGeneratorConfiguration: Codable, Equatable, Sendable {
    public let minimumTickSpacing: TimeInterval
    public let rules: [WorldEventRule]

    /// Global floor between any two generated events (seconds of session active time).
    /// Kept near 40 so walks feel sparse; do not drop below ~30 without outdoor evidence.
    public init(minimumTickSpacing: TimeInterval = 40, rules: [WorldEventRule] = WorldEventGeneratorConfiguration.defaultRules) {
        self.minimumTickSpacing = max(0, minimumTickSpacing)
        self.rules = rules
    }

    /// Companion-first light tune (v1.1).
    ///
    /// Intent (bounded pursuit safety preserved):
    /// - **More Lira**: drawsNear / observes / movesAhead slightly favored and cooler cooldowns
    /// - **Quieter path**: quietInterval less dominant when other companion cues are eligible
    /// - **Rarer sharp pursuit**: higher entry pressure/energy, lower weight, longer begin cooldown
    /// - **Easier release**: pursuitFades slightly more available after pressure
    /// - **Bond/familiar earlier**: mild threshold relief so return-walk reward can appear sooner
    ///
    /// Demo Mode schedules its arc explicitly and is unaffected by these weights.
    /// Outdoor calibration may revise values; do not invent new event kinds here.
    public static let defaultRules: [WorldEventRule] = [
        WorldEventRule(kind: .quietInterval, minimumEnergy: 0, maximumPressure: 0.25, weight: 3, cooldown: 28),
        WorldEventRule(kind: .companionDrawsNear, minimumEnergy: 0.05, maximumPressure: 0.48, weight: 7, cooldown: 24),
        WorldEventRule(kind: .companionMovesAhead, minimumEnergy: 0.40, maximumPressure: 0.62, weight: 4, cooldown: 30),
        WorldEventRule(kind: .companionObserves, minimumEnergy: 0, minimumPressure: 0.04, maximumPressure: 0.55, weight: 4, cooldown: 22),
        WorldEventRule(kind: .distantPresence, minimumPressure: 0.24, maximumPressure: 0.70, weight: 3, cooldown: 44),
        WorldEventRule(kind: .pursuitBegins, minimumEnergy: 0.28, minimumPressure: 0.36, maximumPressure: 0.78, weight: 2, cooldown: 70),
        WorldEventRule(kind: .pursuitIntensifies, minimumPressure: 0.55, maximumPressure: 1, weight: 3, cooldown: 48),
        WorldEventRule(kind: .pursuitFades, minimumEnergy: 0.50, minimumPressure: 0.18, maximumPressure: 0.55, weight: 3, cooldown: 38),
        WorldEventRule(kind: .familiarPlaceStirs, minimumFamiliarity: 0.30, weight: 3, cooldown: 50),
        WorldEventRule(kind: .bondMoment, minimumEnergy: 0.20, minimumBondLevel: 8, weight: 3, cooldown: 60)
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
    private var lastGeneratedAtElapsed: TimeInterval?
    private var lastFiredAtElapsedByKind: [WorldEventKind: TimeInterval] = [:]

    public init(seed: UInt64, configuration: WorldEventGeneratorConfiguration = WorldEventGeneratorConfiguration()) {
        self.rng = SeededRandomNumberGenerator(seed: seed)
        self.configuration = configuration
    }

    public mutating func evaluate(
        state: WorldState,
        now: Date,
        elapsed: TimeInterval? = nil,
        lastGeneratedAtElapsed externalLastGeneratedAtElapsed: TimeInterval? = nil,
        lastFiredAtElapsedByKind externalLastFiredAtElapsedByKind: [WorldEventKind: TimeInterval] = [:],
        allowedKinds: Set<WorldEventKind>? = nil
    ) -> WorldEvent? {
        let elapsed = max(0, (elapsed ?? state.activeTime).finiteOrZero)
        let lastGenerated = [lastGeneratedAtElapsed, externalLastGeneratedAtElapsed]
            .compactMap { $0 }
            .max()
        if let lastGenerated, elapsed - lastGenerated < configuration.minimumTickSpacing {
            return nil
        }

        let eligible = configuration.rules.filter { rule in
            if let allowedKinds, !allowedKinds.contains(rule.kind) {
                return false
            }
            let lastFired = [
                lastFiredAtElapsedByKind[rule.kind],
                externalLastFiredAtElapsedByKind[rule.kind]
            ]
                .compactMap { $0 }
                .max()
            return rule.isEligible(
                for: state,
                elapsed: elapsed,
                lastFiredAtElapsed: lastFired
            )
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
        lastFiredAtElapsedByKind[selected.kind] = elapsed
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
