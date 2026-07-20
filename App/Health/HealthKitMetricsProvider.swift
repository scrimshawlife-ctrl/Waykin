import Foundation
import HealthKit
import WaykinCore

/// Optional HealthKit adapter. Failures degrade to empty enrichment — never blocks Demo Mode.
@MainActor
final class HealthKitMetricsProvider: HealthMetricsProviding {
    private let store: HKHealthStore?
    private(set) var authorizationState: HealthAuthorizationState
    /// At most one statistics refresh in flight (issue #104).
    private var refreshInFlight = false

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            store = HKHealthStore()
            authorizationState = .notDetermined
        } else {
            store = nil
            authorizationState = .unavailable
        }
    }

    func requestAuthorizationIfNeeded() async {
        guard let store else {
            authorizationState = .unavailable
            return
        }
        guard authorizationState == .notDetermined else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            // HealthKit does not expose definitive read authorization.
            authorizationState = .requestCompleted
        } catch {
            authorizationState = .denied
        }
    }

    func refreshEnrichment() async -> ActivityEnrichment {
        guard let store else {
            return ActivityEnrichment(
                stepVolumeAvailability: .unavailable,
                walkingDistanceAvailability: .unavailable
            )
        }
        if authorizationState == .unavailable {
            return ActivityEnrichment(
                stepVolumeAvailability: .unavailable,
                walkingDistanceAvailability: .unavailable
            )
        }
        if authorizationState == .denied {
            return ActivityEnrichment(
                authorizationDenied: true,
                stepVolumeAvailability: .denied,
                walkingDistanceAvailability: .denied
            )
        }
        if authorizationState == .notDetermined {
            return ActivityEnrichment(
                stepVolumeAvailability: .unknown,
                walkingDistanceAvailability: .unknown
            )
        }
        // requestCompleted: still best-effort; empty/failed are normal.

        if refreshInFlight {
            return ActivityEnrichment(
                stepVolumeAvailability: .failed,
                walkingDistanceAvailability: .failed
            )
        }
        refreshInFlight = true
        defer { refreshInFlight = false }

        let now = Date()
        let hourAgo = now.addingTimeInterval(-3_600)
        let dayStart = Calendar.current.startOfDay(for: now)

        async let stepsResult = sumQuantity(
            store: store,
            identifier: .stepCount,
            unit: .count(),
            start: hourAgo,
            end: now
        )
        async let distanceResult = sumQuantity(
            store: store,
            identifier: .distanceWalkingRunning,
            unit: .meter(),
            start: dayStart,
            end: now
        )

        let steps = await stepsResult
        let distance = await distanceResult
        let stepAvailability = Self.availability(for: steps)
        let distanceAvailability = Self.availability(for: distance)
        let stepCount = steps.value
        let band = Self.stepVolumeBand(stepsLastHour: stepCount)

        return ActivityEnrichment(
            stepCadenceBand: band,
            stepCountWindow: stepCount.map { Int($0.rounded()) },
            walkingDistanceMetersWindow: distance.value,
            authorizationDenied: false,
            stepVolumeAvailability: stepAvailability,
            walkingDistanceAvailability: distanceAvailability
        )
    }

    /// Recent-hour step **volume** band (not live steps/minute cadence).
    static func stepVolumeBand(stepsLastHour: Double?) -> StepCadenceBand {
        guard let steps = stepsLastHour, steps.isFinite else { return .unknown }
        switch steps {
        case ..<200: return .low
        case 200..<2_000: return .moderate
        default: return .high
        }
    }

    /// Backward-compatible alias used by existing tests.
    static func cadenceBand(stepsLastHour: Double?) -> StepCadenceBand {
        stepVolumeBand(stepsLastHour: stepsLastHour)
    }

    private static func availability(for result: QuantityQueryResult) -> ActivityMetricAvailability {
        switch result {
        case .present: return .present
        case .noData: return .noData
        case .failed: return .failed
        }
    }

    private enum QuantityQueryResult: Sendable {
        case present(Double)
        case noData
        case failed

        var value: Double? {
            if case .present(let value) = self { return value }
            return nil
        }
    }

    private func sumQuantity(
        store: HKHealthStore,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> QuantityQueryResult {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return .failed
        }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if error != nil {
                    continuation.resume(returning: .failed)
                    return
                }
                guard let quantity = statistics?.sumQuantity() else {
                    continuation.resume(returning: .noData)
                    return
                }
                let value = quantity.doubleValue(for: unit)
                if value.isFinite {
                    continuation.resume(returning: .present(value))
                } else {
                    continuation.resume(returning: .failed)
                }
            }
            store.execute(query)
        }
    }
}
