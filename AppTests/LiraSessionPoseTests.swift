import WaykinCore
import XCTest
@testable import WaykinApp

final class LiraSessionPoseTests: XCTestCase {
    func testOpeningMapsToManifesting() {
        let p = makePresentation(isOpening: true)
        XCTAssertEqual(LiraSessionPose.resolve(from: p), .manifesting)
    }

    func testStrongPursuitMapsToHunter() {
        XCTAssertEqual(LiraSessionPose.resolve(from: makePresentation(pursuit: .close)), .hunter)
        XCTAssertEqual(LiraSessionPose.resolve(from: makePresentation(pursuit: .approaching)), .hunter)
    }

    func testLeadBehaviorMapsToGuide() {
        let p = makePresentation(behavior: .lead, pursuit: .inactive)
        XCTAssertEqual(LiraSessionPose.resolve(from: p), .guide)
    }

    func testRestMapsToSanctuary() {
        let p = makePresentation(behavior: .rest, pursuit: .inactive)
        XCTAssertEqual(LiraSessionPose.resolve(from: p), .sanctuary)
    }

    func testBondEventMapsToBond() {
        let p = makePresentation(pursuit: .inactive, event: .bondMoment)
        XCTAssertEqual(LiraSessionPose.resolve(from: p), .bond)
    }

    func testFadingPursuitMapsToSanctuary() {
        let p = makePresentation(pursuit: .fading)
        XCTAssertEqual(LiraSessionPose.resolve(from: p), .sanctuary)
    }

    func testHunterPoseRequiresEchoSilhouette() {
        XCTAssertTrue(LiraSessionPose.hunter.showsEchoSilhouette)
        XCTAssertFalse(LiraSessionPose.guide.showsEchoSilhouette)
    }

    func testHunterIsMoreCrouchedThanGuide() {
        XCTAssertGreaterThan(LiraSessionPose.hunter.crouch, LiraSessionPose.guide.crouch)
    }

    func testAllPosesHaveAccessibilityCopy() {
        for pose in LiraSessionPose.allCases {
            XCTAssertFalse(pose.accessibilityDescription.isEmpty)
        }
    }

    // Mirrors CompanionPresencePresentationTests helper surface
    private func makePresentation(
        behavior: CompanionBehaviorState = .follow,
        pursuit: PursuitState = .inactive,
        event: WorldEventKind? = nil,
        isOpening: Bool = false,
        isPaused: Bool = false
    ) -> CompanionPresencePresentation {
        CompanionPresencePresentation(
            companionName: "Lira",
            bondLevel: 3,
            behavior: behavior,
            pursuitState: pursuit,
            eventKind: event,
            audioCueKind: nil,
            elapsedSeconds: 30,
            distanceMeters: 40,
            isPaused: isPaused,
            isOpening: isOpening,
            latitude: nil,
            longitude: nil
        )
    }
}
