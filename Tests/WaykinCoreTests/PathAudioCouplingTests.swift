import XCTest
@testable import WaykinCore

final class PathAudioCouplingTests: XCTestCase {
    func testStrainedAndOffPathMapToQuietShift() {
        let strained = PathAudioCoupling.cue(
            from: .onPath,
            to: .strained,
            pursuitState: .inactive
        )
        XCTAssertEqual(strained?.kind, .quietShift)
        XCTAssertEqual(strained?.debugLabel, "path:strained")

        let off = PathAudioCoupling.cue(
            from: .strained,
            to: .offPath,
            pursuitState: .inactive
        )
        XCTAssertEqual(off?.kind, .quietShift)
        XCTAssertEqual(off?.debugLabel, "path:offPath")
    }

    func testRecoveredMapsToPursuitRelease() {
        let cue = PathAudioCoupling.cue(
            from: .offPath,
            to: .recovered,
            pursuitState: .fading
        )
        XCTAssertEqual(cue?.kind, .pursuitRelease)
        XCTAssertEqual(cue?.debugLabel, "path:recovered")
    }

    func testNoCueWhenUnchangedOrEstablishingOnPath() {
        XCTAssertNil(PathAudioCoupling.cue(from: .onPath, to: .onPath, pursuitState: .inactive))
        XCTAssertNil(PathAudioCoupling.cue(from: .establishing, to: .onPath, pursuitState: .inactive))
    }

    func testSuppressedDuringActivePursuit() {
        XCTAssertNil(PathAudioCoupling.cue(
            from: .onPath,
            to: .strained,
            pursuitState: .approaching
        ))
        XCTAssertNil(PathAudioCoupling.cue(
            from: .onPath,
            to: .offPath,
            pursuitState: .close
        ))
    }

    func testCooldown() {
        let first = PathAudioCoupling.cue(
            from: .onPath,
            to: .strained,
            pursuitState: .inactive,
            sessionElapsed: 20,
            lastPathAudioElapsed: nil
        )
        XCTAssertNotNil(first)
        XCTAssertNil(PathAudioCoupling.cue(
            from: .strained,
            to: .offPath,
            pursuitState: .inactive,
            sessionElapsed: 25,
            lastPathAudioElapsed: 20
        ))
        let after = PathAudioCoupling.cue(
            from: .strained,
            to: .offPath,
            pursuitState: .inactive,
            sessionElapsed: 20 + PathAudioCoupling.cooldownSeconds,
            lastPathAudioElapsed: 20
        )
        XCTAssertEqual(after?.debugLabel, "path:offPath")
    }
}
