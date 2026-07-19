import Foundation
import HealthKit
import WaykinCore

/// Optional HealthKit adapter. Failures degrade to empty enrichment — never blocks Demo Mode.
@MainActor
final class HealthKitMetricsProvider: HealthMetricsProviding {
    private let store: HKHealthStore?
    private(set) var authorizationState: HealthAuthorizationState

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
            // HealthKit does not expose definitive read authorization; treat request completion as authorized path.
            authorizationState = .authorized
        } catch {
            authorizationState = .denied
        }
    }

    func refreshEnrichment() async -> ActivityEnrichment {
        guard let store, authorizationState != .unavailable else {
            return .empty
        }
        if authorizationState == .denied {
            return ActivityEnrichment(authorizationDenied: true)
        }

        let now = Date()
        let hourAgo = now.addingTimeInterval(-3_600)
        let dayStart = Calendar.current.startOfDay(for: now)

        async let steps = sumQuantity(
            store: store,
            identifier: .stepCount,
            unit: .count(),
            start: hourAgo,
            end: now
        )
        async let distance = sumQuantity(
            store: store,
            identifier: .distanceWalkingRunning,
            unit: .meter(),
            start: dayStart,
            end: now
        )

        let stepCount = await steps
        let walkingMeters = await distance
        let band = Self.cadenceBand(stepsLastHour: stepCount)
        return ActivityEnrichment(
            stepCadenceBand: band,
            stepCountWindow: stepCount.map { Int($0.rounded()) },
            walkingDistanceMetersWindow: walkingMeters,
            authorizationDenied: false
        )
    }

    static func cadenceBand(stepsLastHour: Double?) -> StepCadenceBand {
        guard let steps = stepsLastHour, steps.isFinite else { return .unknown }
        switch steps {
        case ..<200: return .low
        case 200..<2_000: return .moderate
        default: return .high
        }
    }

    private func sumQuantity(
        store: HKHealthStore,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
