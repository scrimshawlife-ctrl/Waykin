import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class SessionElapsedPresentationTests: XCTestCase {
    func testPresentationElapsedUsesWallClockOnActiveRealWalk() throws {
        let location = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let clock = MutableClock(Date(timeIntervalSince1970: 1_700_000_000))
        let model = try makeModel(location: location, now: { clock.now })
        model.startRealCompanionWalk()
        XCTAssertEqual(model.realWalkState, .active)

        XCTAssertEqual(model.presentationElapsedSeconds(now: clock.now), 0, accuracy: 0.05)

        clock.now = clock.now.addingTimeInterval(5)
        XCTAssertEqual(model.presentationElapsedSeconds(now: clock.now), 5, accuracy: 0.05)

        // Sample-driven core elapsed can still be 0 without GPS samples.
        XCTAssertEqual(model.movementEngine.currentSession?.elapsedTime ?? -1, 0, accuracy: 0.001)

        // HUD presentation should use wall clock, not sample sum.
        XCTAssertEqual(
            model.activePresencePresentation.elapsedSeconds,
            model.presentationElapsedSeconds(now: clock.now),
            accuracy: 0.05
        )
    }

    func testPresentationElapsedFreezesAcrossPause() throws {
        let location = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let clock = MutableClock(Date(timeIntervalSince1970: 1_700_000_100))
        let model = try makeModel(location: location, now: { clock.now })
        model.startRealCompanionWalk()
        XCTAssertEqual(model.realWalkState, .active)

        clock.now = clock.now.addingTimeInterval(10)
        XCTAssertEqual(model.presentationElapsedSeconds(now: clock.now), 10, accuracy: 0.05)

        model.pauseRealSession()
        XCTAssertEqual(model.realWalkState, .paused)
        clock.now = clock.now.addingTimeInterval(30)
        XCTAssertEqual(model.presentationElapsedSeconds(now: clock.now), 10, accuracy: 0.1)

        model.resumeRealSession()
        clock.now = clock.now.addingTimeInterval(4)
        XCTAssertEqual(model.presentationElapsedSeconds(now: clock.now), 14, accuracy: 0.1)
    }

    func testDemoElapsedStillUsesSessionTickTime() throws {
        let location = FakeRealLocationProvider(status: .denied)
        let model = try makeModel(location: location)
        model.startDemo(.calmDayWalk)
        let before = model.activePresencePresentation.elapsedSeconds
        model.advanceDemo()
        let after = model.activePresencePresentation.elapsedSeconds
        XCTAssertGreaterThanOrEqual(after, before)
    }

    private func makeModel(
        location: FakeRealLocationProvider,
        now: (@MainActor () -> Date)? = nil
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
            healthMetricsProvider: NullHealthMetricsProvider(),
            fieldTestReceiptStore: nil,
            fieldTestNow: now ?? Date.init
        )
    }
}

@MainActor
private final class MutableClock {
    var now: Date
    init(_ now: Date) { self.now = now }
}
