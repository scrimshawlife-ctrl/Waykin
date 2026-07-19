import SwiftData
import XCTest
import WaykinCore
@testable import WaykinApp

@MainActor
final class PathProgressIntegrationTests: XCTestCase {
    func testDemoWalkAdvancesPathProgressWithoutHealthKit() throws {
        let model = try makeModel(health: NullHealthMetricsProvider())
        model.startDemo(.calmDayWalk)
        XCTAssertEqual(model.pathProgress.relation, .establishing)
        XCTAssertEqual(model.activityEnrichment.stepCadenceBand, .unknown)

        model.advanceDemo()
        model.advanceDemo()
        XCTAssertGreaterThan(model.pathProgress.acceptedSampleCount, 0)
        XCTAssertGreaterThanOrEqual(model.pathProgress.metersAlongPath, 0)
        // Demo never requires Health authorization.
        XCTAssertFalse(model.activityEnrichment.authorizationDenied)
    }

    func testDemoEndSurfacesPathOnSessionSummary() throws {
        let model = try makeModel(health: NullHealthMetricsProvider())
        model.startDemo(.calmDayWalk)
        model.runDemoToEnd()
        model.endDemo()

        let summary = try XCTUnwrap(model.lastSummary)
        XCTAssertNotNil(summary.pathRelation)
        XCTAssertNotNil(summary.pathPresentationLine)
        XCTAssertTrue(summary.memory.text.contains("path") || summary.pathRelation == PathRelation.establishing.rawValue)
    }

    func testNullHealthProviderDeniedSurfacesFlag() async {
        let provider = NullHealthMetricsProvider(authorizationState: .denied)
        let enrichment = await provider.refreshEnrichment()
        XCTAssertTrue(enrichment.authorizationDenied)
        XCTAssertEqual(enrichment.stepCadenceBand, .unknown)
    }

    func testFakeHealthProviderReturnsDeterministicEnrichment() async {
        let provider = FakeHealthMetricsProvider(
            authorizationState: .authorized,
            enrichment: ActivityEnrichment(stepCadenceBand: .moderate, stepCountWindow: 900)
        )
        await provider.requestAuthorizationIfNeeded()
        let enrichment = await provider.refreshEnrichment()
        XCTAssertEqual(enrichment.stepCadenceBand, .moderate)
        XCTAssertEqual(enrichment.stepCountWindow, 900)
        XCTAssertEqual(provider.authorizationRequestCount, 1)
        XCTAssertEqual(provider.refreshCount, 1)
        XCTAssertGreaterThan(enrichment.energyHint, 0)
    }

    func testHealthKitCadenceBands() {
        XCTAssertEqual(HealthKitMetricsProvider.cadenceBand(stepsLastHour: nil), .unknown)
        XCTAssertEqual(HealthKitMetricsProvider.cadenceBand(stepsLastHour: 50), .low)
        XCTAssertEqual(HealthKitMetricsProvider.cadenceBand(stepsLastHour: 500), .moderate)
        XCTAssertEqual(HealthKitMetricsProvider.cadenceBand(stepsLastHour: 5_000), .high)
    }

    private func makeModel(health: any HealthMetricsProviding) throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            healthMetricsProvider: health,
            fieldTestReceiptStore: nil
        )
    }
}
