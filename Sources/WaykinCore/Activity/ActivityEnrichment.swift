import Foundation

/// Coarse step intensity — platform adapters map HealthKit (or fakes) into these bands.
public enum StepCadenceBand: String, Codable, CaseIterable, Sendable, Equatable {
    case unknown
    case low
    case moderate
    case high
}

/// Semantic activity enrichment from optional HealthKit (or test fakes).
/// Contains **no** HealthKit types and no personal medical claims.
public struct ActivityEnrichment: Codable, Equatable, Sendable {
    public var stepCadenceBand: StepCadenceBand
    /// Optional step count window (e.g. last hour); nil if unavailable.
    public var stepCountWindow: Int?
    /// Optional walking distance meters for a coarse daily window; nil if unavailable.
    public var walkingDistanceMetersWindow: Double?
    public var authorizationDenied: Bool

    public init(
        stepCadenceBand: StepCadenceBand = .unknown,
        stepCountWindow: Int? = nil,
        walkingDistanceMetersWindow: Double? = nil,
        authorizationDenied: Bool = false
    ) {
        self.stepCadenceBand = stepCadenceBand
        self.stepCountWindow = stepCountWindow.map { max(0, $0) }
        self.walkingDistanceMetersWindow = walkingDistanceMetersWindow.map { max(0, $0.finiteOrZero) }
        self.authorizationDenied = authorizationDenied
    }

    public static let empty = ActivityEnrichment()

    /// Light presentation boost for energy/familiarity — never required for gameplay.
    public var energyHint: Double {
        switch stepCadenceBand {
        case .unknown: return 0
        case .low: return 0.05
        case .moderate: return 0.12
        case .high: return 0.2
        }
    }
}
