import CoreLocation
import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class FieldTestReceiptIntegrationTests: XCTestCase {
    func testDemoReceiptIsDeterministicAndDoesNotChangeGameplayOutcome() throws {
        let enabledStore = ReceiptCaptureStore()
        let enabledClock = ReceiptTestClock(now: Date(timeIntervalSince1970: 1_000))
        let disabledClock = ReceiptTestClock(now: enabledClock.now)
        let enabledAudio = ReceiptAudioSpy()
        let disabledAudio = ReceiptAudioSpy()
        let enabled = try makeModel(clock: enabledClock, audio: enabledAudio, receiptStore: enabledStore)
        let disabled = try makeModel(clock: disabledClock, audio: disabledAudio, receiptStore: nil)

        enabled.startDemo(.calmDayWalk)
        disabled.startDemo(.calmDayWalk)
        XCTAssertEqual(enabled.activePresencePresentation.phrase, "Lira is listening.")
        XCTAssertEqual(disabled.activePresencePresentation.phrase, "Lira is listening.")
        enabled.runDemoToEnd()
        disabled.runDemoToEnd()
        enabledClock.now = enabledClock.now.addingTimeInterval(280)
        disabledClock.now = disabledClock.now.addingTimeInterval(280)
        enabled.endDemo()
        disabled.endDemo()

        XCTAssertEqual(enabled.lastSummary?.duration, disabled.lastSummary?.duration)
        XCTAssertEqual(enabled.lastSummary?.activeTime, disabled.lastSummary?.activeTime)
        XCTAssertEqual(enabled.lastSummary?.distanceMeters, disabled.lastSummary?.distanceMeters)
        XCTAssertEqual(enabled.lastSummary?.outcome, disabled.lastSummary?.outcome)
        XCTAssertEqual(enabled.lastSummary?.bondDelta, disabled.lastSummary?.bondDelta)
        XCTAssertEqual(enabled.lastSummary?.memory.text, disabled.lastSummary?.memory.text)
        XCTAssertEqual(enabled.persistenceMemoryCount, disabled.persistenceMemoryCount)
        XCTAssertEqual(enabledAudio.handledCues.map(\.kind), disabledAudio.handledCues.map(\.kind))

        let receipt = try XCTUnwrap(enabledStore.receipts.single)
        XCTAssertEqual(receipt.mode, .demo)
        XCTAssertEqual(receipt.outcome, .completed)
        XCTAssertEqual(receipt.persistence, .succeeded)
        XCTAssertEqual(receipt.summary.durationSeconds, 280)
        XCTAssertEqual(receipt.summary.bondDelta, enabled.lastSummary?.bondDelta)
        XCTAssertTrue(receipt.summary.memoryWritten)
        XCTAssertEqual(
            receipt.timeline
                .filter { $0.category == .worldEventEmitted }
                .map(\.code),
            [
                WorldEventKind.companionObserves.rawValue,
                WorldEventKind.companionDrawsNear.rawValue,
                WorldEventKind.distantPresence.rawValue,
                WorldEventKind.pursuitBegins.rawValue,
                WorldEventKind.pursuitIntensifies.rawValue,
                WorldEventKind.pursuitFades.rawValue,
                WorldEventKind.bondMoment.rawValue
            ]
        )
        XCTAssertTrue(receipt.summary.worldEventCounts.values.allSatisfy { $0 == 1 })
        XCTAssertEqual(
            receipt.timeline
                .filter { $0.category == .audioCueRequested }
                .map(\.code),
            [
                AudioCueKind.quietShift.rawValue,
                AudioCueKind.companionNear.rawValue,
                AudioCueKind.distantFootsteps.rawValue,
                AudioCueKind.distantFootsteps.rawValue,
                AudioCueKind.pursuitPressure.rawValue,
                AudioCueKind.pursuitRelease.rawValue,
                AudioCueKind.bondMotif.rawValue
            ]
        )
        XCTAssertEqual(
            enabled.lastSummary?.memory.text,
            "Lira watched the path, drew close when a distant presence appeared, and stayed beside you until it faded."
        )
        XCTAssertEqual(receipt.timeline.last?.category, .sessionCompleted)
        XCTAssertTrue(receipt.timeline.contains { $0.category == .audioLifecycleAction && $0.code == "stop" })
    }

    func testDemoAndPhysicalPathsExposeTheSamePresenceContract() throws {
        let clock = ReceiptTestClock(now: Date(timeIntervalSince1970: 1_500))
        let demo = try makeModel(clock: clock, receiptStore: nil)
        let physical = try makeModel(
            clock: clock,
            provider: ReceiptLocationProvider(status: .authorizedWhenInUse),
            receiptStore: nil
        )

        demo.startDemo(.calmDayWalk)
        physical.startRealCompanionWalk()

        let demoPresence = demo.activePresencePresentation
        let physicalPresence = physical.activePresencePresentation
        XCTAssertEqual(demoPresence.companionName, physicalPresence.companionName)
        XCTAssertEqual(demoPresence.behavior.rawValue, physicalPresence.behavior.rawValue)
        XCTAssertEqual(demoPresence.pursuitState, physicalPresence.pursuitState)
        XCTAssertEqual(demoPresence.phrase, physicalPresence.phrase)
    }

    func testPhysicalReceiptAggregatesAcceptedAndRejectedSamples() throws {
        let store = ReceiptCaptureStore()
        let clock = ReceiptTestClock(now: Date(timeIntervalSince1970: 2_000))
        let provider = ReceiptLocationProvider(status: .authorizedWhenInUse)
        let model = try makeModel(clock: clock, provider: provider, receiptStore: store)

        model.startRealCompanionWalk()
        provider.emit(sample(at: clock.now))
        clock.now = clock.now.addingTimeInterval(2)
        provider.emit(sample(at: clock.now, northMeters: 2, speed: 1))
        clock.now = clock.now.addingTimeInterval(1)
        provider.emit(sample(at: clock.now, northMeters: 102, speed: 100))
        clock.now = clock.now.addingTimeInterval(7)
        model.endRealSession()
        model.endRealSession()

        let receipt = try XCTUnwrap(store.receipts.single)
        XCTAssertEqual(store.receipts.count, 1)
        XCTAssertEqual(receipt.mode, .physical)
        XCTAssertEqual(receipt.outcome, .userEnded)
        XCTAssertEqual(receipt.summary.acceptedSampleCount, 2)
        XCTAssertEqual(receipt.summary.rejectedSampleCount, 1)
        XCTAssertEqual(receipt.summary.memoryWritten, true)
        XCTAssertEqual(receipt.summary.bondDelta, 1)
        XCTAssertEqual(model.persistenceMemoryCount, 1)
    }

    func testProviderFailureUsesTypedCategoryWithoutRawDetail() throws {
        let store = ReceiptCaptureStore()
        let clock = ReceiptTestClock(now: Date(timeIntervalSince1970: 3_000))
        let provider = ReceiptLocationProvider(status: .authorizedWhenInUse)
        let model = try makeModel(clock: clock, provider: provider, receiptStore: store)

        model.startRealCompanionWalk()
        provider.emitSignal(.failed("private provider detail"))

        let receipt = try XCTUnwrap(store.receipts.single)
        XCTAssertEqual(receipt.outcome, .providerFailed)
        XCTAssertEqual(receipt.summary.finalErrorCategory, .providerUnavailable)
        let json = String(decoding: try JSONEncoder().encode(receipt), as: UTF8.self)
        XCTAssertFalse(json.contains("private provider detail"))
    }

    func testReceiptWriteFailureIsExplicitAndDoesNotUndoMemory() throws {
        let store = ReceiptCaptureStore(error: .writeFailed)
        let clock = ReceiptTestClock(now: Date(timeIntervalSince1970: 4_000))
        let model = try makeModel(clock: clock, receiptStore: store)

        model.startDemo(.calmDayWalk)
        model.runDemoToEnd()
        clock.now = clock.now.addingTimeInterval(96)
        model.endDemo()

        XCTAssertEqual(model.fieldTestReceiptError, .writeFailed)
        XCTAssertEqual(model.persistenceMemoryCount, 1)
        XCTAssertNotNil(model.lastSummary)
    }

    private func makeModel(
        clock: ReceiptTestClock,
        audio: ReceiptAudioSpy? = nil,
        provider: ReceiptLocationProvider = ReceiptLocationProvider(status: .authorizedWhenInUse),
        receiptStore: (any FieldTestReceiptStoring)?
    ) throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            audioPlayer: audio ?? ReceiptAudioSpy(),
            movementEngine: MovementEngine(
                clock: clock,
                integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1)
            ),
            realLocationProvider: provider,
            fieldTestReceiptStore: receiptStore,
            fieldTestNow: { clock.now }
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

private final class ReceiptTestClock: ClockProviding {
    var now: Date
    init(now: Date) { self.now = now }
}

private final class ReceiptCaptureStore: FieldTestReceiptStoring {
    private(set) var receipts: [FieldTestReceipt] = []
    let error: FieldTestReceiptStoreError?

    init(error: FieldTestReceiptStoreError? = nil) {
        self.error = error
    }

    func save(_ receipt: FieldTestReceipt) throws -> URL {
        if let error { throw error }
        receipts.append(receipt)
        return URL(fileURLWithPath: "/tmp/\(receipt.receiptID.uuidString).json")
    }

    func loadLatest() throws -> FieldTestReceipt? { receipts.last }
}

private final class ReceiptLocationProvider: RealLocationProviding {
    var onLocationSample: ((LocationSample) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onSignalStateChange: ((LiveLocationSignalState) -> Void)?
    var authorizationStatus: CLAuthorizationStatus
    var locationServicesEnabled = true

    init(status: CLAuthorizationStatus) {
        authorizationStatus = status
    }

    func requestAuthorization() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
    func emit(_ sample: LocationSample) { onLocationSample?(sample) }
    func emitSignal(_ state: LiveLocationSignalState) { onSignalStateChange?(state) }
}

@MainActor
private final class ReceiptAudioSpy: AudioCuePlaying {
    var handledCues: [AudioCue] = []
    func handle(_ cues: [AudioCue]) { handledCues.append(contentsOf: cues) }
    func pauseAll() {}
    func resumeAll() {}
    func stopAll(fadeOut: Bool) {}
}

private extension Array {
    var single: Element? { count == 1 ? first : nil }
}
