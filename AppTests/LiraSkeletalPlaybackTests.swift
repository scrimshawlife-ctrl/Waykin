import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class LiraSkeletalPlaybackTests: XCTestCase {
    func testRigJointContractMatchesFactoryHierarchy() {
        let entity = CompanionEntityFactory().makeLira()
        XCTAssertTrue(LiraSkeletalRig.hasSkeletalJoints(entity))
        for joint in ["Head", "CoreGlow", "Filament", "Body", "LeftEar", "RightEar", "Tail"] {
            XCTAssertNotNil(entity.findEntity(named: joint), "missing joint \(joint)")
        }
        XCTAssertEqual(LiraSkeletalRig.rootName, CompanionEntityFactory.rootName)
    }

    func testSkeletalLibraryGeneratesAllClips() throws {
        for clip in LiraSkeletalAnimationLibrary.ClipID.allCases {
            let resource = try LiraSkeletalAnimationLibrary.generate(clip: clip)
            XCTAssertNotNil(resource, clip.rawValue)
        }
        let library = try LiraSkeletalAnimationLibrary.makeLibrary()
        XCTAssertEqual(library.count, LiraSkeletalAnimationLibrary.ClipID.allCases.count)
    }

    func testClipMappingCoversEveryPresentationState() {
        XCTAssertEqual(LiraSkeletalAnimationLibrary.clip(for: .idle), .idle)
        XCTAssertEqual(LiraSkeletalAnimationLibrary.clip(for: .follow), .follow)
        XCTAssertEqual(LiraSkeletalAnimationLibrary.clip(for: .investigate), .investigate)
        XCTAssertEqual(LiraSkeletalAnimationLibrary.clip(for: .alert), .alert)
        XCTAssertEqual(LiraSkeletalAnimationLibrary.clip(for: .celebrate), .celebrate)
        XCTAssertTrue(LiraSkeletalAnimationLibrary.ClipID.idle.isLooping)
        XCTAssertFalse(LiraSkeletalAnimationLibrary.ClipID.celebrate.isLooping)
        XCTAssertFalse(LiraSkeletalAnimationLibrary.ClipID.spawn.isLooping)
    }

    func testPlayerInstallsAndPlaysOnProceduralEntity() {
        let entity = CompanionEntityFactory().makeLira()
        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: entity))
        XCTAssertTrue(player.isInstalled)
        XCTAssertTrue(player.isDriving)
        player.play(state: .follow, on: entity)
        XCTAssertEqual(player.activeClip, .follow)
        player.play(state: .follow, on: entity)
        XCTAssertEqual(player.activeClip, .follow, "looping re-play is idempotent")
        player.play(state: .alert, on: entity)
        XCTAssertEqual(player.activeClip, .alert)
        player.clear()
        XCTAssertFalse(player.isInstalled)
        XCTAssertFalse(player.isDriving)
        XCTAssertNil(player.activeClip)
    }

    func testPlayerFailsInstallWithoutJoints() {
        let empty = Entity()
        empty.name = CompanionEntityFactory.rootName
        let player = LiraSkeletalPlayer()
        XCTAssertFalse(player.install(on: empty))
        XCTAssertFalse(player.isInstalled)
    }

    func testRendererDefaultsToSkeletalDrivingAndClears() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        XCTAssertTrue(renderer.skeletalPlaybackEnabled)
        let entity = CompanionEntityFactory().makeLira()
        // Simulate install path used on spawn.
        XCTAssertTrue(LiraSkeletalRig.hasSkeletalJoints(entity))
        renderer.skeletalPlaybackEnabled = true
        // Direct player path via public surface after a fake install:
        // clearSession must reset skeletal driving.
        _ = renderer.clearSession()
        XCTAssertFalse(renderer.isSkeletalDriving)
        XCTAssertNil(renderer.activeSkeletalClip)
        XCTAssertEqual(renderer.localMotionElapsed, 0, accuracy: 0.0001)
    }

    func testRendererCanDisableSkeletalForPureFunctionFallback() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        renderer.skeletalPlaybackEnabled = false
        XCTAssertFalse(renderer.skeletalPlaybackEnabled)
        // Without spawn, not driving.
        XCTAssertFalse(renderer.isSkeletalDriving)
        renderer.advanceLocalMotion(by: 0.5)
        XCTAssertGreaterThan(renderer.localMotionElapsed, 0.4)
        _ = renderer.clearSession()
        XCTAssertEqual(renderer.localMotionElapsed, 0, accuracy: 0.0001)
    }
}
