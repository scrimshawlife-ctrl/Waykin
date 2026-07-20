import Foundation

/// Coarse **recent step-volume** band (previous hour), not live cadence.
/// Platform adapters map HealthKit (or fakes) into these bands.
public enum StepCadenceBand: String, Codable, CaseIterable, Sendable, Equatable {
    case unknown
    case low
    case moderate
    case high
}

/// Internal provenance for a single optional activity metric.
/// Never write raw HealthKit sample IDs or medical claims into receipts.
public enum ActivityMetricAvailability: String, Codable, CaseIterable, Sendable, Equatable {
    /// Not yet queried or not applicable.
    case unknown
    /// Health data service unavailable on this device.
    case unavailable
    /// Authorization request failed or caller marked denied.
    case denied
    /// Query completed; no samples / nil sum for the window.
    case noData
    /// Query failed (error path).
    case failed
    /// Query completed with a finite value.
    case present
}

/// Semantic activity enrichment from optional HealthKit (or test fakes).
/// Contains **no** HealthKit types and no personal medical claims.
public struct ActivityEnrichment: Codable, Equatable, Sendable {
    /// Recent-hour step **volume** band (name retained for Codable stability).
    public var stepCadenceBand: StepCadenceBand
    /// Optional step count window (e.g. last hour); nil if unavailable.
    public var stepCountWindow: Int?
    /// Optional walking distance meters for today's window; presentation-only effort context.
    public var walkingDistanceMetersWindow: Double?
    /// True when the caller treated authorization as denied (not definitive HealthKit read proof).
    public var authorizationDenied: Bool
    public var stepVolumeAvailability: ActivityMetricAvailability
    public var walkingDistanceAvailability: ActivityMetricAvailability

    public init(
        stepCadenceBand: StepCadenceBand = .unknown,
        stepCountWindow: Int? = nil,
        walkingDistanceMetersWindow: Double? = nil,
        authorizationDenied: Bool = false,
        stepVolumeAvailability: ActivityMetricAvailability = .unknown,
        walkingDistanceAvailability: ActivityMetricAvailability = .unknown
    ) {
        self.stepCadenceBand = stepCadenceBand
        self.stepCountWindow = stepCountWindow.map { max(0, $0) }
        self.walkingDistanceMetersWindow = walkingDistanceMetersWindow.map { max(0, $0.finiteOrZero) }
        self.authorizationDenied = authorizationDenied
        self.stepVolumeAvailability = stepVolumeAvailability
        self.walkingDistanceAvailability = walkingDistanceAvailability
    }

    public static let empty = ActivityEnrichment()

    /// Light presentation boost — never required for gameplay.
    /// Prefers step-volume band; falls back to coarse daily distance when steps unknown.
    public var energyHint: Double {
        switch stepCadenceBand {
        case .low: return 0.05
        case .moderate: return 0.12
        case .high: return 0.2
        case .unknown:
            break
        }
        // Daily walking distance is effort context only (not movement authority).
        guard walkingDistanceAvailability == .present,
              let meters = walkingDistanceMetersWindow else { return 0 }
        switch meters {
        case ..<500: return 0.03
        case 500..<2_000: return 0.08
        default: return 0.12
        }
    }
}
