import XCTest
@testable import WaykinCore

final class DiagnosticsTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func makeSession() -> MovementSession {
        MovementSession(activity: .walking, startedAt: start,
                        endedAt: start.addingTimeInterval(600),
                        distanceMeters: 900,
                        route: [MovementSample(coordinate: .init(latitude: 37, longitude: -122),
                                               timestamp: start)])
    }

    func makeOutcome() -> ExperienceOutcome {
        ExperienceOutcome(succeeded: true, bondDelta: 8,
                          memorySeed: "outran an orc warband",
                          summaryLine: "You escaped.")
    }

    func testReceiptBuilderCountsEventsAndTracksPeaks() {
        let builder = SessionReceiptBuilder(mode: .simulated)
        builder.record([.dialogue("Run!"), .threatLevel(0.2), .companionBehavior(.run)])
        builder.record([.threatLevel(0.8), .threatLevel(0.5), .milestone("Escaped"),
                        .audio(.victory), .companionBehavior(.run)])

        let receipt = builder.finalize(session: makeSession(), outcome: makeOutcome(),
                                       companionName: "Ember",
                                       experienceID: "orc-pursuit", experienceName: "Orc Pursuit",
                                       locationName: "Shoreline Park",
                                       memory: Memory(date: start, locationName: "Shoreline Park",
                                                      durationSeconds: 600, distanceMeters: 900,
                                                      experienceID: "orc-pursuit",
                                                      experienceName: "Orc Pursuit",
                                                      bondGained: 8, text: "We outran a warband."))
        XCTAssertEqual(receipt.eventCounts["dialogue"], 1)
        XCTAssertEqual(receipt.eventCounts["behavior.run"], 2)
        XCTAssertEqual(receipt.eventCounts["milestone"], 1)
        XCTAssertEqual(receipt.eventCounts["audio.victory"], 1)
        XCTAssertEqual(receipt.peakThreat, 0.8)
        XCTAssertNil(receipt.maxGhostGapMeters)
        XCTAssertTrue(receipt.memoryWritten)
        XCTAssertEqual(receipt.sampleCount, 1)
        XCTAssertEqual(receipt.mode, .simulated)
    }

    func testFileReceiptStoreRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("waykin-receipts-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileReceiptStore(directory: directory)
        let builder = SessionReceiptBuilder(mode: .physical)
        builder.record([.ghostDistance(40), .ghostDistance(55), .ghostDistance(-2)])
        let receipt = builder.finalize(session: makeSession(), outcome: makeOutcome(),
                                       companionName: "Ember",
                                       experienceID: "future-self", experienceName: "Future Self",
                                       locationName: "Shoreline Park", memory: nil)
        let url = try store.save(receipt)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let loaded = store.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first, receipt)
        XCTAssertEqual(loaded.first?.maxGhostGapMeters, 55)
        XCTAssertFalse(loaded.first!.memoryWritten)
    }

    func testPresenceNarratorPhrases() {
        // Threat channel dominates.
        XCTAssertEqual(PresenceNarrator.phrase(companionName: "Ember", behavior: .run, threat: 0.9),
                       "The pressure is close.")
        XCTAssertEqual(PresenceNarrator.phrase(companionName: "Ember", behavior: .run, threat: 0.5),
                       "Something is keeping pace.")
        // Ghost channel next.
        XCTAssertEqual(PresenceNarrator.phrase(companionName: "Ember", behavior: .walk, ghostGapMeters: -1),
                       "Ember shares the moment.")
        XCTAssertEqual(PresenceNarrator.phrase(companionName: "Ember", behavior: .walk, ghostGapMeters: 10),
                       "The shimmer is almost in reach.")
        // Behavior fallback.
        XCTAssertEqual(PresenceNarrator.phrase(companionName: "Ember", behavior: .idle, isMoving: false),
                       "Ember rests beside you.")
        XCTAssertEqual(PresenceNarrator.phrase(companionName: "Ember", behavior: .celebrate),
                       "Ember shares the moment.")
        // Closing lines.
        XCTAssertEqual(PresenceNarrator.closingPhrase(companionName: "Ember", outcome: makeOutcome()),
                       "Ember stayed with you.")
    }
}
