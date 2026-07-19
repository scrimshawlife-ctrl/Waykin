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
}
