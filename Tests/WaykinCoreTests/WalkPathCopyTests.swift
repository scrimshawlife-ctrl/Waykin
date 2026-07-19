import XCTest
@testable import WaykinCore

final class WalkPathCopyTests: XCTestCase {
    func testPathLinesAreHumanAndMetered() {
        XCTAssertEqual(
            WalkPathCopy.pathLine(relation: .onPath, metersAlongPath: 42.7),
            "Path held steady · 42 m along the path"
        )
        XCTAssertEqual(
            WalkPathCopy.pathLine(relation: .strained, metersAlongPath: 10),
            "Path felt strained · 10 m along the path"
        )
        XCTAssertEqual(
            WalkPathCopy.pathLine(relation: .establishing, metersAlongPath: 0),
            "Path establishing"
        )
    }

    func testCadenceLinesHideUnknown() {
        XCTAssertNil(WalkPathCopy.cadenceLine(band: .unknown))
        XCTAssertEqual(WalkPathCopy.cadenceLine(band: .moderate), "Steps felt steady")
        XCTAssertEqual(WalkPathCopy.cadenceLine(band: .high), "Steps felt strong")
    }

    func testMemorySuffixAppendsDistinctPathClause() {
        let base = "Lira stayed close during a quiet 20m walk."
        let withPath = WalkPathCopy.appendingMemorySuffix(to: base, relation: .onPath)
        XCTAssertTrue(withPath.contains("the path held steady"))
        XCTAssertTrue(withPath.hasSuffix("."))
        XCTAssertEqual(
            WalkPathCopy.appendingMemorySuffix(to: base, relation: .establishing),
            base
        )
    }

    func testSessionSummarySurfacingPresentationLines() {
        let summary = SessionSummary(
            id: UUID(),
            sessionID: UUID(),
            activity: .walk,
            experience: "companion_walk",
            variant: "day",
            duration: 60,
            activeTime: 50,
            distanceMeters: 40,
            averageSpeed: 1.2,
            outcome: "COMPLETED",
            bondDelta: 1,
            memory: SessionMemory(sessionID: UUID(), text: "Quiet walk.")
        )
        let path = PathProgressSnapshot(
            metersAlongPath: 38,
            relation: .recovered,
            integrityPressure: 0.2,
            acceptedSampleCount: 12
        )
        let enrichment = ActivityEnrichment(stepCadenceBand: .high, stepCountWindow: 2500)
        let surfaced = summary.withWalkSurfacing(path: path, enrichment: enrichment)
        XCTAssertEqual(surfaced.pathRelation, PathRelation.recovered.rawValue)
        XCTAssertEqual(surfaced.pathPresentationLine, "Path found again · 38 m along the path")
        XCTAssertEqual(surfaced.cadencePresentationLine, "Steps felt strong")
        // Privacy: presentation lines must not include raw step counts.
        XCTAssertFalse(surfaced.cadencePresentationLine?.contains("2500") ?? true)
    }
}
