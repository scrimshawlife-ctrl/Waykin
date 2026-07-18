import RealityKit
import XCTest
@testable import WaykinApp

@MainActor
final class ARCompanionEmbodimentTests: XCTestCase {
    func testVisualConfigurationClampsUnsafeValues() {
        let configuration = CompanionVisualConfiguration(
            companionHeightMeters: 20,
            groundOffsetMeters: -4,
            glowIntensity: .infinity
        )

        XCTAssertEqual(configuration.companionHeightMeters, 1.5)
        XCTAssertEqual(configuration.groundOffsetMeters, 0)
        XCTAssertEqual(configuration.glowIntensity, 1)
    }

    func testFactoryProducesStableSemanticHierarchy() {
        let entity = CompanionEntityFactory().makeLira()

        XCTAssertEqual(entity.name, CompanionEntityFactory.rootName)
        for name in [
            "Body", "Head", "LeftEar", "RightEar", "Tail",
            "CoreGlow", "GroundShadow", "StatusIndicator"
        ] {
            XCTAssertNotNil(entity.findEntity(named: name), "Missing \(name)")
        }
    }

    func testFactoryProducesIndependentEntities() {
        let factory = CompanionEntityFactory()
        let first = factory.makeLira()
        let second = factory.makeLira()

        XCTAssertFalse(first === second)
        XCTAssertNil(first.parent)
        XCTAssertNil(second.parent)
    }

    func testGlowIntensityChangesCorePresentation() {
        let factory = CompanionEntityFactory()
        let dim = factory.makeLira(configuration: CompanionVisualConfiguration(glowIntensity: 0))
        let bright = factory.makeLira(configuration: CompanionVisualConfiguration(glowIntensity: 1))

        let dimCore = dim.findEntity(named: "CoreGlow")
        let brightCore = bright.findEntity(named: "CoreGlow")
        XCTAssertNotNil(dimCore)
        XCTAssertNotNil(brightCore)
        XCTAssertGreaterThan(brightCore?.scale.x ?? 0, dimCore?.scale.x ?? 0)
    }

    func testReducerMapsKnownAndUnknownBehaviorsDeterministically() {
        XCTAssertEqual(CompanionStateReducer.state(for: "follow"), .follow)
        XCTAssertEqual(CompanionStateReducer.state(for: "observe"), .investigate)
        XCTAssertEqual(CompanionStateReducer.state(for: "threat"), .alert)
        XCTAssertEqual(CompanionStateReducer.state(for: "bondMoment"), .celebrate)
        XCTAssertEqual(CompanionStateReducer.state(for: "unknown"), .idle)
    }

    func testCelebrateReturnsToIdleAfterBoundedDuration() {
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(
                current: .celebrate,
                requested: .celebrate,
                elapsed: 1.6
            ),
            .idle
        )
    }

    func testDiagnosticsBuildPrivacyFilteredSummary() throws {
        let recorder = ARDiagnosticRecorder()
        recorder.record(.sessionStarted)
        recorder.record(.trackingNormal)
        recorder.record(.entityCreated, detail: "companion")
        recorder.record(.stateChanged, detail: "idle")
        recorder.record(.entityReplaced, detail: "companion")
        recorder.record(.sessionCleared)

        let receipt = recorder.summary
        XCTAssertTrue(receipt.sessionStarted)
        XCTAssertTrue(receipt.trackingNormalReached)
        XCTAssertTrue(receipt.companionPlaced)
        XCTAssertEqual(receipt.replacementCount, 1)
        XCTAssertEqual(receipt.stateTransitions, ["idle"])
        XCTAssertTrue(receipt.cleanupSucceeded)

        let encoded = try JSONEncoder().encode(receipt)
        let text = String(decoding: encoded, as: UTF8.self)
        XCTAssertFalse(text.localizedCaseInsensitiveContains("latitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("longitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("image"))
    }
}
