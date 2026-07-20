import XCTest
@testable import WaykinApp

final class LiraSessionMotionTests: XCTestCase {
    func testPoseCrossfadeDurationsHonorReduceMotionContract() {
        XCTAssertEqual(LiraSessionMotion.poseCrossfadeDuration(reduceMotion: true), 0.08, accuracy: 0.001)
        XCTAssertEqual(LiraSessionMotion.poseCrossfadeDuration(reduceMotion: false), 0.22, accuracy: 0.001)
        XCTAssertLessThanOrEqual(LiraSessionMotion.poseCrossfadeDuration(reduceMotion: true), 0.08)
    }

    func testIdlePulseDisabledUnderReduceMotion() {
        XCTAssertFalse(LiraSessionMotion.allowsIdlePulse(reduceMotion: true))
        XCTAssertTrue(LiraSessionMotion.allowsIdlePulse(reduceMotion: false))
        XCTAssertNil(LiraSessionMotion.idlePulseDuration(reduceMotion: true))
        XCTAssertNotNil(LiraSessionMotion.idlePulseDuration(reduceMotion: false))
    }

    func testHunterEchoContract() {
        XCTAssertTrue(LiraSessionMotion.showsHunterEcho(pose: .hunter))
        XCTAssertFalse(LiraSessionMotion.showsHunterEcho(pose: .guide))
        XCTAssertLessThan(
            LiraSessionMotion.hunterEchoOpacity(reduceMotion: true),
            LiraSessionMotion.hunterEchoOpacity(reduceMotion: false)
        )
        XCTAssertGreaterThan(LiraSessionMotion.hunterEchoOpacity(reduceMotion: false), 0.1)
        XCTAssertLessThan(LiraSessionMotion.hunterEchoOpacity(reduceMotion: false), 0.4)
    }

    func testManifestingFadeLongerThanDefaultCrossfade() {
        XCTAssertEqual(LiraSessionMotion.manifestingFadeDuration(reduceMotion: false), 0.70, accuracy: 0.001)
        XCTAssertEqual(LiraSessionMotion.manifestingFadeDuration(reduceMotion: true), 0.12, accuracy: 0.001)
        XCTAssertGreaterThan(
            LiraSessionMotion.poseCrossfadeDuration(reduceMotion: false, incomingPose: .manifesting),
            LiraSessionMotion.poseCrossfadeDuration(reduceMotion: false, incomingPose: .guide)
        )
        XCTAssertEqual(
            LiraSessionMotion.poseCrossfadeDuration(reduceMotion: true, incomingPose: .manifesting),
            0.12,
            accuracy: 0.001
        )
        XCTAssertEqual(LiraSessionMotion.manifestingStartScale, 0.92, accuracy: 0.001)
    }

    func testBondOrbitTiming() {
        let period = LiraSessionMotion.bondOrbitPeriod(reduceMotion: false)
        XCTAssertNotNil(period)
        XCTAssertEqual(period!, 1.2, accuracy: 0.001)
        XCTAssertNil(LiraSessionMotion.bondOrbitPeriod(reduceMotion: true))
        let bondTrim = LiraSessionMotion.bondOrbitTrim(pose: .bond)
        let guideTrim = LiraSessionMotion.bondOrbitTrim(pose: .guide)
        XCTAssertLessThan(bondTrim.from, guideTrim.from)
        XCTAssertGreaterThan(bondTrim.to, guideTrim.to)
        XCTAssertEqual(LiraSessionMotion.bondOrbitLineWidth(pose: .bond), 6)
        XCTAssertEqual(LiraSessionMotion.bondOrbitLineWidth(pose: .guide), 5)
    }

    func testCorePulseAndFilamentDriftHelpers() {
        let core = LiraSessionMotion.corePulsePeriod(reduceMotion: false)
        XCTAssertNotNil(core)
        XCTAssertEqual(core!, 1.6, accuracy: 0.001)
        XCTAssertNil(LiraSessionMotion.corePulsePeriod(reduceMotion: true))
        let drift = LiraSessionMotion.filamentDriftPeriod(reduceMotion: false)
        XCTAssertNotNil(drift)
        XCTAssertEqual(drift!, 2.4, accuracy: 0.001)
        XCTAssertNil(LiraSessionMotion.filamentDriftPeriod(reduceMotion: true))
        XCTAssertEqual(LiraSessionMotion.filamentDriftOffsetX(progress: 0, reduceMotion: true), 0, accuracy: 0.001)
        XCTAssertNotEqual(LiraSessionMotion.filamentDriftOffsetX(progress: 0.25, reduceMotion: false), 0)
    }
}
