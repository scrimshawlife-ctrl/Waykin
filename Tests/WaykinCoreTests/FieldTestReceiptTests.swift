import XCTest
@testable import WaykinCore

final class FieldTestReceiptTests: XCTestCase {
    private let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
    private let receiptID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let sessionID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    func testSchemaRoundTripAndStableEnumEncoding() throws {
        let receipt = completedReceipt()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(receipt)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        XCTAssertEqual(try decoder.decode(FieldTestReceipt.self, from: data), receipt)
        XCTAssertEqual(receipt.schemaVersion, FieldTestReceipt.currentSchemaVersion)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"mode\":\"demo\""))
        XCTAssertTrue(json.contains("\"outcome\":\"completed\""))
        XCTAssertTrue(json.contains("\"persistence\":\"succeeded\""))
    }

    func testSerializedReceiptContainsNoProhibitedPrivateData() throws {
        let data = try JSONEncoder().encode(completedReceipt())
        let json = try XCTUnwrap(String(data: data, encoding: .utf8)).lowercased()
        let prohibitedTerms = [
            "latitude", "longitude", "altitude", "coordinate", "cllocation",
            "routepoints", "address", "street", "landmark", "personaltext"
        ]

        for term in prohibitedTerms {
            XCTAssertFalse(json.contains(term), "Receipt unexpectedly contains \(term)")
        }
    }

    func testAggregationCountsMovementEventsAudioLifecycleAndBond() {
        let builder = makeBuilder()
        builder.recordMovement(diagnostic(.accepted, speed: 1.2, accumulated: true))
        builder.recordMovement(diagnostic(.awaitingFreshAnchor))
        builder.recordMovement(diagnostic(.rejectedAccuracy))
        builder.recordMovement(diagnostic(.rejectedAccuracy))
        builder.recordMovement(diagnostic(.rejectedDuplicate))
        builder.recordWorldEvent(event(.companionDrawsNear, offset: 3))
        builder.recordWorldEvent(event(.companionDrawsNear, offset: 3))
        builder.recordAudioCue(cue(.companionNear), at: startedAt.addingTimeInterval(3))
        builder.recordAudioSuppression("duplicate", at: startedAt.addingTimeInterval(4))
        builder.recordInterruption("began", at: startedAt.addingTimeInterval(5))
        builder.recordLifecycle("background", at: startedAt.addingTimeInterval(6))
        let receipt = builder.finish(
            session: session(),
            outcome: .completed,
            endingBond: 14,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20)
        )

        XCTAssertEqual(receipt.summary.acceptedSampleCount, 2)
        XCTAssertEqual(receipt.summary.rejectedSampleCount, 3)
        XCTAssertEqual(receipt.summary.rejectionCounts[MovementSampleDisposition.rejectedAccuracy.rawValue], 2)
        XCTAssertEqual(receipt.summary.rejectionCounts[MovementSampleDisposition.rejectedDuplicate.rawValue], 1)
        XCTAssertEqual(receipt.summary.freshAnchorResetCount, 1)
        XCTAssertEqual(receipt.summary.worldEventCounts[WorldEventKind.companionDrawsNear.rawValue], 1)
        XCTAssertEqual(receipt.summary.semanticAudioCueCounts[AudioCueKind.companionNear.rawValue], 1)
        XCTAssertEqual(receipt.summary.audioSuppressionCount, 1)
        XCTAssertEqual(receipt.summary.interruptionCount, 1)
        XCTAssertEqual(receipt.summary.lifecycleTransitionCount, 1)
        XCTAssertEqual(receipt.summary.bondDelta, 2)
        XCTAssertTrue(receipt.summary.memoryWritten)
    }

    func testDurationDistanceAndSpeedSummaryRemainFinite() {
        let builder = makeBuilder()
        builder.recordMovementSnapshot(MovementSnapshot(timestamp: startedAt, speed: 1.2, distanceDelta: 2, isMoving: true))
        builder.recordMovementSnapshot(MovementSnapshot(timestamp: startedAt, speed: 1.8, distanceDelta: 3, isMoving: true))
        var invalidSession = session()
        invalidSession.elapsedTime = .infinity
        invalidSession.activeTime = .nan
        invalidSession.distanceMeters = -.infinity
        let receipt = builder.finish(
            session: invalidSession,
            outcome: .completed,
            endingBond: 12,
            memoryWritten: false,
            persistence: .notAttempted,
            endedAt: startedAt.addingTimeInterval(20)
        )

        XCTAssertEqual(receipt.summary.durationSeconds, 0)
        XCTAssertEqual(receipt.summary.activeDurationSeconds, 0)
        XCTAssertEqual(receipt.summary.accumulatedDistanceMeters, 0)
        XCTAssertEqual(receipt.summary.maximumStabilizedSpeedMetersPerSecond, 1.8)
        XCTAssertEqual(receipt.summary.averageStabilizedSpeedMetersPerSecond, 1.5, accuracy: 0.001)
    }

    func testPauseDurationAndTimelineOrderAreStable() {
        let builder = makeBuilder()
        builder.recordSessionTransition(from: .active, to: .paused, at: startedAt.addingTimeInterval(5))
        builder.recordSessionTransition(from: .paused, to: .active, at: startedAt.addingTimeInterval(9))
        builder.recordWorldEvent(event(.quietInterval, offset: 10))
        builder.recordAudioCue(cue(.quietShift), at: startedAt.addingTimeInterval(10))
        let receipt = builder.finish(
            session: session(),
            outcome: .userEnded,
            endingBond: 12,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(20)
        )

        XCTAssertEqual(receipt.summary.pausedDurationSeconds, 4)
        XCTAssertEqual(receipt.timeline.map(\.category).prefix(4), [
            .sessionStateTransition, .sessionStateTransition, .worldEventEmitted, .audioCueRequested
        ])
    }

    func testAcceptedSamplesDoNotCreateUnboundedTimeline() {
        let builder = makeBuilder()
        for index in 0..<1_000 {
            builder.recordMovement(diagnostic(.accepted, offset: TimeInterval(index), speed: 1.1, accumulated: true))
        }
        for index in 0..<500 {
            builder.recordMovement(diagnostic(.rejectedAccuracy, offset: TimeInterval(index)))
        }

        XCTAssertEqual(builder.receipt.summary.acceptedSampleCount, 1_000)
        XCTAssertEqual(builder.receipt.summary.rejectedSampleCount, 500)
        XCTAssertEqual(builder.receipt.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)

        let finished = builder.finish(
            session: nil,
            outcome: .completed,
            endingBond: 12,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: startedAt.addingTimeInterval(30)
        )
        XCTAssertEqual(finished.timeline.count, FieldTestReceiptBuilder.maximumTimelineEntries)
        XCTAssertEqual(finished.timeline.suffix(2).map(\.category), [.memoryWriteResult, .sessionCompleted])
    }

    func testStoreWritesAtomicallyAndReadsLatest() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileFieldTestReceiptStore(directoryURL: directory)
        let older = completedReceipt(offset: 0)
        let newer = completedReceipt(offset: 60, receiptID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!)

        let url = try store.save(older)
        _ = try store.save(newer)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(try store.loadLatest(), newer)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(names.filter { $0.hasSuffix(".tmp") }.count, 0)
    }

    func testStoreSurfacesWriteFailure() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let fileURL = root.appendingPathComponent("not-a-directory")
        try Data("x".utf8).write(to: fileURL)
        let store = FileFieldTestReceiptStore(directoryURL: fileURL)

        XCTAssertThrowsError(try store.save(completedReceipt())) { error in
            XCTAssertEqual(error as? FieldTestReceiptStoreError, .createDirectoryFailed)
        }
    }

    func testRetentionKeepsTwentyNewestReceipts() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileFieldTestReceiptStore(directoryURL: directory)

        for index in 0..<22 {
            _ = try store.save(completedReceipt(
                offset: TimeInterval(index),
                receiptID: UUID()
            ))
        }

        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        XCTAssertEqual(files.count, 20)
        XCTAssertEqual(try store.loadLatest()?.startedAt, startedAt.addingTimeInterval(21))
    }

    func testReceiptRotationDoesNotTouchNormalMemories() throws {
        let memoryStore = PersistenceStore()
        let memory = SessionMemory(sessionID: UUID(), text: "Existing canonical memory")
        try memoryStore.saveMemory(memory)
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let receiptStore = FileFieldTestReceiptStore(directoryURL: directory, retentionLimit: 1)

        _ = try receiptStore.save(completedReceipt(offset: 0))
        _ = try receiptStore.save(completedReceipt(offset: 1, receiptID: UUID()))

        XCTAssertEqual(try memoryStore.memoryCount(), 1)
        XCTAssertEqual(try memoryStore.loadMemories().first?.id, memory.id)
    }

    private func makeBuilder() -> FieldTestReceiptBuilder {
        FieldTestReceiptBuilder(
            receiptID: receiptID,
            sessionID: sessionID,
            mode: .demo,
            startedAt: startedAt,
            startingBond: 12
        )
    }

    private func completedReceipt(
        offset: TimeInterval = 0,
        receiptID: UUID? = nil
    ) -> FieldTestReceipt {
        let start = startedAt.addingTimeInterval(offset)
        let builder = FieldTestReceiptBuilder(
            receiptID: receiptID ?? self.receiptID,
            sessionID: sessionID,
            mode: .demo,
            startedAt: start,
            startingBond: 12
        )
        builder.recordAudioLifecycle("stop", at: start.addingTimeInterval(20))
        return builder.finish(
            session: session(startedAt: start),
            outcome: .completed,
            endingBond: 13,
            memoryWritten: true,
            persistence: .succeeded,
            endedAt: start.addingTimeInterval(20)
        )
    }

    private func session(startedAt: Date? = nil) -> MovementSession {
        var session = MovementSession(
            id: sessionID,
            activityType: .walk,
            experienceID: "companion_walk",
            startedAt: startedAt ?? self.startedAt
        )
        session.endedAt = (startedAt ?? self.startedAt).addingTimeInterval(20)
        session.elapsedTime = 20
        session.activeTime = 16
        session.distanceMeters = 24
        session.currentSpeedMetersPerSecond = 0
        session.averageSpeedMetersPerSecond = 1.5
        session.movementState = .stopped
        return session
    }

    private func diagnostic(
        _ disposition: MovementSampleDisposition,
        offset: TimeInterval = 0,
        speed: Double = 0,
        accumulated: Bool = false
    ) -> MovementSampleDiagnostic {
        MovementSampleDiagnostic(
            timestamp: startedAt.addingTimeInterval(offset),
            disposition: disposition,
            accuracyBucket: .usable,
            derivedSpeedMetersPerSecond: speed,
            accumulatedDistance: accumulated
        )
    }

    private func event(_ kind: WorldEventKind, offset: TimeInterval) -> WorldEvent {
        WorldEvent(kind: kind, occurredAt: startedAt.addingTimeInterval(offset), intensity: 0.5, debugLabel: kind.rawValue)
    }

    private func cue(_ kind: AudioCueKind) -> AudioCue {
        AudioCue(
            kind: kind,
            intensity: 0.5,
            priority: 1,
            cooldownGroup: kind.rawValue,
            shouldFade: true,
            debugLabel: kind.rawValue
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("waykin-receipt-\(UUID().uuidString)", isDirectory: true)
    }
}
