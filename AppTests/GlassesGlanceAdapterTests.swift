import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class GlassesGlanceAdapterTests: XCTestCase {
    func testSnapshotOmitsCoordinatesAndUsesPresentationFields() {
        let presentation = CompanionPresencePresentation(
            companionName: "Lira",
            bondLevel: 12,
            behavior: .follow,
            pursuitState: .close,
            eventKind: .pursuitIntensifies,
            audioCueKind: .pursuitPressure,
            elapsedSeconds: 125,
            distanceMeters: 340,
            isPaused: false,
            isOpening: false,
            latitude: 37.77,
            longitude: -122.42,
            pathRelation: .onPath,
            pathIntegrityPressure: 0.4
        )
        let snap = GlassesGlanceSnapshot.from(presentation)
        XCTAssertEqual(snap.companionName, "Lira")
        XCTAssertEqual(snap.presencePhrase, presentation.phrase)
        XCTAssertEqual(snap.pathPressureStatus, presentation.pressureLabel)
        XCTAssertEqual(snap.elapsedText, "2:05")
        XCTAssertEqual(snap.distanceText, "340 m")
        XCTAssertTrue(snap.audioActive)
        XCTAssertFalse(snap.isPaused)
        // Privacy: snapshot type has no lat/lon fields; HUD lines must not embed raw coords.
        let joined = snap.hudLines.joined(separator: " ")
        XCTAssertFalse(joined.contains("37.77"))
        XCTAssertFalse(joined.contains("-122.42"))
    }

    func testNullAdapterIsNoOpWhenDisabled() async {
        let adapter = NullGlassesGlanceAdapter()
        XCTAssertFalse(adapter.isEnabled)
        XCTAssertEqual(adapter.connectionState, .disabled)
        await adapter.startSession()
        adapter.publish(
            GlassesGlanceSnapshot(
                companionName: "Lira",
                presencePhrase: "test",
                pathPressureStatus: "Path quiet",
                elapsedText: "0:00",
                distanceText: "0 m",
                isPaused: false,
                isOpening: true,
                audioActive: false
            )
        )
        XCTAssertNil(adapter.lastSnapshot)
        adapter.endSession()
    }

    func testMockTransportAdapterPublishesWhenEnabled() async {
        let transport = MockGlassesHUDTransport()
        let adapter = DefaultGlassesGlanceAdapter(transport: transport, enabled: true)
        await adapter.startSession()
        XCTAssertEqual(transport.connectionState, .connected)
        XCTAssertEqual(adapter.connectionState, .connected)

        let snap = GlassesGlanceSnapshot(
            companionName: "Lira",
            presencePhrase: "Lira stays close.",
            pathPressureStatus: "Path steady",
            elapsedText: "1:00",
            distanceText: "50 m",
            isPaused: false,
            isOpening: false,
            audioActive: false
        )
        adapter.publish(snap)
        XCTAssertEqual(adapter.lastSnapshot, snap)
        XCTAssertEqual(transport.pushedLineSets.count, 1)
        XCTAssertEqual(transport.pushedLineSets[0], snap.hudLines)

        adapter.endSession()
        XCTAssertEqual(transport.disconnectCount, 1)
        XCTAssertNil(adapter.lastSnapshot)
    }

    func testFactoryDefaultOffReturnsNull() {
        let adapter = GlassesGlanceAdapterFactory.make(enabled: false)
        XCTAssertFalse(adapter.isEnabled)
        XCTAssertTrue(adapter is NullGlassesGlanceAdapter)
    }

    func testFactoryEnabledPrefersMockWhenRequested() {
        let adapter = GlassesGlanceAdapterFactory.make(enabled: true, preferMockTransport: true)
        XCTAssertTrue(adapter.isEnabled)
        XCTAssertTrue(adapter is DefaultGlassesGlanceAdapter)
    }

    func testDisabledDefaultAdapterDoesNotConnect() async {
        let transport = MockGlassesHUDTransport()
        let adapter = DefaultGlassesGlanceAdapter(transport: transport, enabled: false)
        await adapter.startSession()
        XCTAssertEqual(transport.connectCount, 0)
        adapter.publish(
            GlassesGlanceSnapshot(
                companionName: "Lira",
                presencePhrase: "x",
                pathPressureStatus: "y",
                elapsedText: "0:00",
                distanceText: "0 m",
                isPaused: false,
                isOpening: false,
                audioActive: false
            )
        )
        XCTAssertEqual(transport.pushedLineSets.count, 0)
    }

    func testAppModelPublishesOnDemoAdvanceWhenGlanceEnabled() async throws {
        let transport = MockGlassesHUDTransport()
        let adapter = DefaultGlassesGlanceAdapter(transport: transport, enabled: true)
        let model = try makeModel(adapter: adapter)
        model.startDemo(.calmDayWalk)
        // Explicit connect for deterministic test (model also Tasks start on demo start).
        await adapter.startSession()
        XCTAssertEqual(transport.connectionState, .connected)

        model.advanceDemo()
        XCTAssertNotNil(adapter.lastSnapshot)
        XCTAssertFalse(transport.pushedLineSets.isEmpty)
        XCTAssertEqual(adapter.lastSnapshot?.companionName, "Lira")

        model.endDemo()
        XCTAssertNil(adapter.lastSnapshot)
        XCTAssertGreaterThanOrEqual(transport.disconnectCount, 1)
    }

    func testAppModelDoesNotPublishWhenGlanceDisabled() throws {
        let transport = MockGlassesHUDTransport()
        let adapter = DefaultGlassesGlanceAdapter(transport: transport, enabled: false)
        let model = try makeModel(adapter: adapter)
        model.startDemo(.calmDayWalk)
        model.advanceDemo()
        XCTAssertEqual(transport.connectCount, 0)
        XCTAssertEqual(transport.pushedLineSets.count, 0)
        model.endDemo()
    }

    func testMetaTransportUnavailableWithoutPartnerSDK() async {
        let meta = MetaWearablesHUDTransport(useMockFallbackInLab: false)
        await meta.connect()
        XCTAssertEqual(meta.connectionState, .unavailable)
        meta.push(lines: ["should not crash"])
        meta.disconnect()
        XCTAssertEqual(meta.connectionState, .idle)
    }

    private func makeModel(adapter: any GlassesGlanceAdapter) throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            movementEngine: MovementEngine(
                integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1)
            ),
            glassesGlanceAdapter: adapter,
            fieldTestReceiptStore: nil
        )
    }
}
