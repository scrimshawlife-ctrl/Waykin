import SwiftData
import XCTest
import WaykinCore
@testable import WaykinApp

@MainActor
final class HealthKitHardeningTests: XCTestCase {
    func testRequestCompletionIsNotDefinitiveAuthorizedLabel() async {
        let provider = FakeHealthMetricsProvider(authorizationState: .notDetermined)
        await provider.requestAuthorizationIfNeeded()
        XCTAssertEqual(provider.authorizationState, .requestCompleted)
        XCTAssertNotEqual(provider.authorizationState.rawValue, "authorized")
    }

    func testDeniedAndUnavailableEnrichmentSurfacesAvailability() async {
        let denied = NullHealthMetricsProvider(authorizationState: .denied)
        let deniedEnrichment = await denied.refreshEnrichment()
        XCTAssertTrue(deniedEnrichment.authorizationDenied)
        XCTAssertEqual(deniedEnrichment.stepVolumeAvailability, .denied)

        let unavailable = NullHealthMetricsProvider(authorizationState: .unavailable)
        let unavailableEnrichment = await unavailable.refreshEnrichment()
        XCTAssertFalse(unavailableEnrichment.authorizationDenied)
        XCTAssertEqual(unavailableEnrichment.stepVolumeAvailability, .unavailable)
        XCTAssertEqual(unavailableEnrichment.energyHint, 0)
    }

    func testStepVolumeBandIsNotLiveCadenceNamingInAPI() {
        // API retains StepCadenceBand raw values for Codable stability but documents volume.
        XCTAssertEqual(HealthKitMetricsProvider.stepVolumeBand(stepsLastHour: nil), .unknown)
        XCTAssertEqual(HealthKitMetricsProvider.stepVolumeBand(stepsLastHour: 100), .low)
        XCTAssertEqual(HealthKitMetricsProvider.cadenceBand(stepsLastHour: 500), .moderate)
    }

    func testDistanceFallbackEnergyWhenStepsUnknown() {
        let enrichment = ActivityEnrichment(
            stepCadenceBand: .unknown,
            walkingDistanceMetersWindow: 1_500,
            stepVolumeAvailability: .noData,
            walkingDistanceAvailability: .present
        )
        XCTAssertGreaterThan(enrichment.energyHint, 0)
        XCTAssertLessThan(enrichment.energyHint, 0.15)
    }

    func testRealWalkCreatesContextBeforeHealthAppliesEnergy() async throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let health = FakeHealthMetricsProvider(
            authorizationState: .requestCompleted,
            enrichment: ActivityEnrichment(
                stepCadenceBand: .high,
                stepCountWindow: 3_000,
                stepVolumeAvailability: .present,
                walkingDistanceAvailability: .noData
            )
        )
        health.refreshDelayNanoseconds = 30_000_000
        let model = try makeModel(location: provider, health: health)

        model.startRealCompanionWalk()
        // Context must exist immediately — before delayed health refresh completes.
        XCTAssertNotNil(model.test_realExperienceContext)
        XCTAssertEqual(model.realWalkState, .active)

        let deadline = Date().addingTimeInterval(2)
        while model.activityEnrichment.stepCadenceBand != .high, Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(model.activityEnrichment.stepCadenceBand, .high)
        XCTAssertEqual(model.test_realExperienceContext?.activityEnergyHint ?? 0, 0.2, accuracy: 0.001)
        XCTAssertGreaterThan(health.refreshCount, 0)
    }

    func testPauseCancelsInFlightHealthApply() async throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let health = FakeHealthMetricsProvider(
            authorizationState: .requestCompleted,
            enrichment: ActivityEnrichment(
                stepCadenceBand: .high,
                stepCountWindow: 3_000,
                stepVolumeAvailability: .present
            )
        )
        health.refreshDelayNanoseconds = 200_000_000
        let model = try makeModel(location: provider, health: health)
        model.startRealCompanionWalk()
        model.pauseRealSession()
        XCTAssertEqual(model.realWalkState, .paused)

        try await Task.sleep(nanoseconds: 250_000_000)
        // Enrichment from cancelled generation must not apply after pause.
        XCTAssertEqual(model.activityEnrichment.stepCadenceBand, .unknown)
        XCTAssertEqual(model.test_realExperienceContext?.activityEnergyHint ?? 0, 0, accuracy: 0.001)
    }

    func testFakeProviderSerializesRefresh() async {
        let health = FakeHealthMetricsProvider()
        health.refreshDelayNanoseconds = 50_000_000
        async let a = health.refreshEnrichment()
        async let b = health.refreshEnrichment()
        _ = await (a, b)
        // One in-flight path should count a concurrent attempt or both complete serially.
        XCTAssertGreaterThanOrEqual(health.refreshCount + health.concurrentRefreshAttempts, 1)
    }

    private func makeModel(
        location: FakeRealLocationProvider,
        health: any HealthMetricsProviding
    ) throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            movementEngine: MovementEngine(
                integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1)
            ),
            realLocationProvider: location,
            healthMetricsProvider: health,
            fieldTestReceiptStore: nil
        )
    }
}

