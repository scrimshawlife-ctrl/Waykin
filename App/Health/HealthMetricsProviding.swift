import Foundation
import WaykinCore

/// Authorization surface for optional HealthKit enrichment.
enum HealthAuthorizationState: String, Equatable, Sendable {
    case unavailable
    case notDetermined
    case denied
    case authorized
}

/// App-layer protocol: never imported by WaykinCore.
@MainActor
protocol HealthMetricsProviding: AnyObject {
    var authorizationState: HealthAuthorizationState { get }
    /// Non-blocking preference: may no-op when unavailable or already decided.
    func requestAuthorizationIfNeeded() async
    /// Best-effort sample; empty when denied/unavailable/error.
    func refreshEnrichment() async -> ActivityEnrichment
}

/// Always-empty provider for Demo Mode, UI tests, and simulators without HealthKit.
@MainActor
final class NullHealthMetricsProvider: HealthMetricsProviding {
    private(set) var authorizationState: HealthAuthorizationState = .unavailable

    init(authorizationState: HealthAuthorizationState = .unavailable) {
        self.authorizationState = authorizationState
    }

    func requestAuthorizationIfNeeded() async {}

    func refreshEnrichment() async -> ActivityEnrichment {
        if authorizationState == .denied {
            return ActivityEnrichment(authorizationDenied: true)
        }
        return .empty
    }
}

/// Deterministic enrichment for app tests — never talks to HealthKit.
@MainActor
final class FakeHealthMetricsProvider: HealthMetricsProviding {
    private(set) var authorizationState: HealthAuthorizationState
    var enrichment: ActivityEnrichment
    private(set) var authorizationRequestCount = 0
    private(set) var refreshCount = 0

    init(
        authorizationState: HealthAuthorizationState = .authorized,
        enrichment: ActivityEnrichment = ActivityEnrichment(stepCadenceBand: .moderate, stepCountWindow: 800)
    ) {
        self.authorizationState = authorizationState
        self.enrichment = enrichment
    }

    func requestAuthorizationIfNeeded() async {
        authorizationRequestCount += 1
        if authorizationState == .notDetermined {
            authorizationState = .authorized
        }
    }

    func refreshEnrichment() async -> ActivityEnrichment {
        refreshCount += 1
        if authorizationState == .denied {
            return ActivityEnrichment(authorizationDenied: true)
        }
        if authorizationState == .unavailable {
            return .empty
        }
        return enrichment
    }
}
