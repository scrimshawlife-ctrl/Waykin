import CoreLocation
import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class RealMovementSessionTests: XCTestCase {
    func testPermissionRequestDoesNotCreateSessionUntilAuthorized() throws {
        let provider = FakeRealLocationProvider(status: .notDetermined)
        let model = try makeModel(provider: provider)

        model.startRealCompanionWalk()

        XCTAssertEqual(model.realWalkState, .requestingPermission)
        XCTAssertEqual(provider.authorizationRequestCount, 1)
        XCTAssertNil(model.movementEngine.currentSession)

        provider.emitAuthorization(.authorizedWhenInUse)

        XCTAssertEqual(model.realWalkState, .active)
        XCTAssertEqual(model.movementEngine.currentSession?.experienceID, "companion_walk")
        XCTAssertEqual(provider.startCount, 1)
    }

    func testDeniedAuthorizationAndDisabledServicesFailWithoutFakeSession() throws {
        let deniedProvider = FakeRealLocationProvider(status: .denied)
        let deniedModel = try makeModel(provider: deniedProvider)
        deniedModel.startRealCompanionWalk()

        XCTAssertEqual(deniedModel.realWalkState, .failed)
        XCTAssertNil(deniedModel.movementEngine.currentSession)
        XCTAssertTrue(deniedModel.demoMessage.contains("Demo Walk"))

        let disabledProvider = FakeRealLocationProvider(status: .authorizedWhenInUse, servicesEnabled: false)
        let disabledModel = try makeModel(provider: disabledProvider)
        disabledModel.startRealCompanionWalk()

        XCTAssertEqual(disabledModel.realWalkState, .failed)
        XCTAssertNil(disabledModel.movementEngine.currentSession)
    }

    func testConcurrentStartDoesNotCreateSecondSession() throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let model = try makeModel(provider: provider)
        model.startRealCompanionWalk()
        let firstSessionID = model.movementEngine.currentSession?.id

        model.startRealCompanionWalk()

        XCTAssertEqual(model.movementEngine.currentSession?.id, firstSessionID)
        XCTAssertEqual(provider.startCount, 1)
        XCTAssertTrue(model.demoMessage.contains("already"))
    }

    func testRejectedSampleDoesNotReachDownstreamAudioOrMetrics() throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let audio = RealAudioSpy()
        let model = try makeModel(provider: provider, audio: audio)
        var deliveredBatches: [[ARWorldCommand]] = []
        model.attachARWorldCommandHandler { deliveredBatches.append($0) }
        model.startRealCompanionWalk()
        audio.handledCues.removeAll()
        let now = Date().addingTimeInterval(-10)
        provider.emit(sample(at: now))
        let pointsBefore = model.movementEngine.currentSession?.routePoints.count
        let commandBatchCountBeforeRejection = deliveredBatches.count

        provider.emit(sample(at: now.addingTimeInterval(1), northMeters: 100))

        XCTAssertEqual(model.liveRejectedCount, 1)
        XCTAssertEqual(model.movementEngine.currentSession?.routePoints.count, pointsBefore)
        XCTAssertTrue(audio.handledCues.isEmpty)
        XCTAssertEqual(deliveredBatches.count, commandBatchCountBeforeRejection)
    }

    func testBackgroundSuspendsAndForegroundResumeRequiresFreshAnchor() throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let model = try makeModel(provider: provider)
        model.startRealCompanionWalk()
        let now = Date().addingTimeInterval(-10)
        provider.emit(sample(at: now))
        provider.emit(sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1))
        let distanceBeforeBackground = model.movementEngine.currentSession?.distanceMeters

        model.handleScenePhase(.background)
        XCTAssertEqual(model.realWalkState, .paused)
        XCTAssertEqual(provider.stopCount, 1)

        model.handleScenePhase(.active)
        XCTAssertEqual(model.realWalkState, .active)
        XCTAssertEqual(provider.startCount, 2)
        provider.emit(sample(at: now.addingTimeInterval(3), northMeters: 50, speed: 1))

        XCTAssertEqual(model.movementEngine.currentSession?.distanceMeters, distanceBeforeBackground)
        XCTAssertEqual(model.movementEngine.lastDiagnostic?.disposition, .awaitingFreshAnchor)
    }

    func testFatalProviderFailureStopsSessionSafely() throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let audio = RealAudioSpy()
        let model = try makeModel(provider: provider, audio: audio)
        var deliveredBatches: [[ARWorldCommand]] = []
        model.attachARWorldCommandHandler { deliveredBatches.append($0) }
        model.startRealCompanionWalk()

        provider.emitSignal(.failed("internal detail"))

        XCTAssertEqual(model.realWalkState, .failed)
        XCTAssertNil(model.movementEngine.currentSession)
        XCTAssertFalse(model.demoMessage.contains("internal detail"))
        XCTAssertGreaterThanOrEqual(audio.stopCalls, 1)
        XCTAssertEqual(deliveredBatches.last, [.clearSession])
    }

    func testEndingRealWalkStopsAudioAndPersistsExactlyOneMemory() async throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let audio = RealAudioSpy()
        let model = try makeModel(provider: provider, audio: audio)
        var deliveredBatches: [[ARWorldCommand]] = []
        model.attachARWorldCommandHandler { deliveredBatches.append($0) }
        model.startRealCompanionWalk()
        audio.stopCalls = 0
        let startingBond = model.companion.bondLevel

        model.endRealSession()
        model.endRealSession()
        await model.waitForPendingPersistence()

        XCTAssertEqual(model.realWalkState, .completed)
        XCTAssertNil(model.movementEngine.currentSession)
        XCTAssertEqual(audio.stopCalls, 1)
        XCTAssertEqual(model.persistenceMemoryCount, 1)
        XCTAssertEqual(model.companion.bondLevel, startingBond + 1)
        XCTAssertEqual(try model.persistenceStore.loadCompanion()?.bondLevel, startingBond + 1)
        XCTAssertFalse(model.lastSummary?.memory.text.contains("unverified") ?? true)
        XCTAssertEqual(deliveredBatches.last, [.clearSession])
    }

    func testAcceptedRealWalkSamplesAdvancePathProgress() throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let model = try makeModel(provider: provider)
        model.startRealCompanionWalk()
        XCTAssertEqual(model.pathProgress.relation, .establishing)

        // Keep sample timestamps within maximumSampleAge (15s).
        let now = Date().addingTimeInterval(-10)
        provider.emit(sample(at: now))
        provider.emit(sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1))
        provider.emit(sample(at: now.addingTimeInterval(4), northMeters: 4, speed: 1))
        provider.emit(sample(at: now.addingTimeInterval(6), northMeters: 6, speed: 1))

        XCTAssertGreaterThan(model.liveAcceptedCount, 0)
        XCTAssertGreaterThan(model.pathProgress.acceptedSampleCount, 0)
        XCTAssertGreaterThan(model.pathProgress.metersAlongPath, 0)
        XCTAssertTrue(
            model.pathProgress.relation == .onPath
                || model.pathProgress.relation == .establishing
                || model.pathProgress.relation == .recovered
        )
    }

    func testRejectedRealWalkSamplesRaisePathIntegrityPressure() throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let model = try makeModel(provider: provider)
        model.startRealCompanionWalk()
        let now = Date().addingTimeInterval(-10)
        // Establish an accepted path first.
        provider.emit(sample(at: now))
        provider.emit(sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1))
        provider.emit(sample(at: now.addingTimeInterval(4), northMeters: 4, speed: 1))

        // Teleport samples should reject under integrity and strain the path.
        for i in 0..<8 {
            provider.emit(sample(
                at: now.addingTimeInterval(5 + Double(i) * 0.5),
                northMeters: 4 + Double(i + 1) * 100,
                speed: 1
            ))
        }

        XCTAssertGreaterThan(model.liveRejectedCount, 0)
        XCTAssertGreaterThan(model.pathProgress.integrityPressure, 0.3)
        XCTAssertTrue(
            model.pathProgress.relation == .strained || model.pathProgress.relation == .offPath
        )
    }

    func testFakeHealthEnrichmentSurfacesOnRealWalkStart() async throws {
        let provider = FakeRealLocationProvider(status: .authorizedWhenInUse)
        let health = FakeHealthMetricsProvider(
            authorizationState: .requestCompleted,
            enrichment: ActivityEnrichment(
                stepCadenceBand: .high,
                stepCountWindow: 3_000,
                stepVolumeAvailability: .present
            )
        )
        let model = try makeModel(provider: provider, health: health)
        model.startRealCompanionWalk()

        // Allow the fire-and-forget refresh Task to complete.
        let deadline = Date().addingTimeInterval(2)
        while model.activityEnrichment.stepCadenceBand == .unknown, Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTAssertEqual(model.activityEnrichment.stepCadenceBand, .high)
        XCTAssertEqual(model.activityEnrichment.stepVolumeAvailability, .present)
        XCTAssertGreaterThan(health.refreshCount, 0)
        XCTAssertGreaterThan(model.activePresencePresentation.energyHint, 0)
    }

    private func makeModel(
        provider: FakeRealLocationProvider,
        audio: RealAudioSpy? = nil,
        health: (any HealthMetricsProviding)? = nil
    ) throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            audioPlayer: audio ?? RealAudioSpy(),
            movementEngine: MovementEngine(
                integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1)
            ),
            realLocationProvider: provider,
            healthMetricsProvider: health ?? NullHealthMetricsProvider(),
            fieldTestReceiptStore: nil
        )
    }

    private func sample(
        at timestamp: Date,
        northMeters: Double = 0,
        speed: Double = 0
    ) -> LocationSample {
        LocationSample(
            timestamp: timestamp,
            latitude: 37.7749 + northMeters / 111_111,
            longitude: -122.4194,
            altitude: 10,
            horizontalAccuracy: 5,
            reportedSpeedMetersPerSecond: speed
        )
    }
}

final class FakeRealLocationProvider: RealLocationProviding {
    var onLocationSample: ((LocationSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onSignalStateChange: ((LiveLocationSignalState) -> Void)?
    var authorizationStatus: CLAuthorizationStatus
    var locationServicesEnabled: Bool
    var authorizationRequestCount = 0
    var startCount = 0
    var stopCount = 0

    init(status: CLAuthorizationStatus, servicesEnabled: Bool = true) {
        authorizationStatus = status
        locationServicesEnabled = servicesEnabled
    }

    func requestAuthorization() { authorizationRequestCount += 1 }
    func startUpdatingLocation() { startCount += 1 }
    func stopUpdatingLocation() { stopCount += 1 }

    func emitAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        onAuthorizationChange?(status)
    }

    func emit(_ sample: LocationSample) {
        onLocationSample?(sample)
    }

    func emitSignal(_ state: LiveLocationSignalState) {
        onSignalStateChange?(state)
    }
}

@MainActor
private final class RealAudioSpy: AudioCuePlaying {
    var handledCues: [AudioCue] = []
    var pauseCalls = 0
    var resumeCalls = 0
    var stopCalls = 0

    func handle(_ cues: [AudioCue]) { handledCues.append(contentsOf: cues) }
    func pauseAll() { pauseCalls += 1 }
    func resumeAll() { resumeCalls += 1 }
    func stopAll(fadeOut: Bool) { stopCalls += 1 }
}
