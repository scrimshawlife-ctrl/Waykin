import Foundation
import WaykinCore

/// Authorization / request surface for optional HealthKit enrichment.
/// HealthKit cannot prove definitive **read** access after a successful prompt;
/// `requestCompleted` means only that the system request finished.
enum HealthAuthorizationState: String, Equatable, Sendable {
    case unavailable
    case notDetermined
    /// System authorization request finished without throwing.
    /// Does **not** prove samples are readable.
    case requestCompleted
    /// Authorization request failed (or test/fixture marked denied).
    case denied
}

/// App-layer protocol: never imported by WaykinCore.
@MainActor
protocol HealthMetricsProviding: AnyObject {
    var authorizationState: HealthAuthorizationState { get }
    /// Non-blocking preference: may no-op when unavailable or already decided.
    func requestAuthorizationIfNeeded() async
    /// Best-effort sample; empty/unknown when denied/unavailable/error/no data.
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
        switch authorizationState {
        case .denied:
            return ActivityEnrichment(
                authorizationDenied: true,
                stepVolumeAvailability: .denied,
                walkingDistanceAvailability: .denied
            )
        case .unavailable:
            return ActivityEnrichment(
                stepVolumeAvailability: .unavailable,
                walkingDistanceAvailability: .unavailable
            )
        case .notDetermined, .requestCompleted:
            return .empty
        }
    }
}

/// Deterministic enrichment for app tests — never talks to HealthKit.
@MainActor
final class FakeHealthMetricsProvider: HealthMetricsProviding {
    private(set) var authorizationState: HealthAuthorizationState
    var enrichment: ActivityEnrichment
    private(set) var authorizationRequestCount = 0
    private(set) var refreshCount = 0
    /// Simulated delay so tests can assert ordering.
    var refreshDelayNanoseconds: UInt64 = 0
    /// When true, concurrent refresh calls while one is in-flight return empty-failed.
    private var refreshInFlight = false
    private(set) var concurrentRefreshAttempts = 0

    init(
        authorizationState: HealthAuthorizationState = .requestCompleted,
        enrichment: ActivityEnrichment = ActivityEnrichment(
            stepCadenceBand: .moderate,
            stepCountWindow: 800,
            stepVolumeAvailability: .present,
            walkingDistanceAvailability: .noData
        )
    ) {
        self.authorizationState = authorizationState
        self.enrichment = enrichment
    }

    func requestAuthorizationIfNeeded() async {
        authorizationRequestCount += 1
        if authorizationState == .notDetermined {
            authorizationState = .requestCompleted
        }
    }

    func refreshEnrichment() async -> ActivityEnrichment {
        if refreshInFlight {
            concurrentRefreshAttempts += 1
            return ActivityEnrichment(
                stepVolumeAvailability: .failed,
                walkingDistanceAvailability: .failed
            )
        }
        refreshInFlight = true
        defer { refreshInFlight = false }
        refreshCount += 1
        if refreshDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: refreshDelayNanoseconds)
        }
        if authorizationState == .denied {
            return ActivityEnrichment(
                authorizationDenied: true,
                stepVolumeAvailability: .denied,
                walkingDistanceAvailability: .denied
            )
        }
        if authorizationState == .unavailable {
            return ActivityEnrichment(
                stepVolumeAvailability: .unavailable,
                walkingDistanceAvailability: .unavailable
            )
        }
        if authorizationState == .notDetermined {
            return ActivityEnrichment(
                stepVolumeAvailability: .unknown,
                walkingDistanceAvailability: .unknown
            )
        }
        return enrichment
    }
}
