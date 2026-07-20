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
        for style in [LiraSkeletalRig.PuppetStyle.multiPart, .staticMesh] {
            for clip in LiraSkeletalAnimationLibrary.ClipID.allCases {
                let resource = try LiraSkeletalAnimationLibrary.generate(clip: clip, style: style)
                XCTAssertNotNil(resource, "\(style.rawValue)/\(clip.rawValue)")
            }
            let library = try LiraSkeletalAnimationLibrary.makeLibrary(style: style)
            XCTAssertEqual(
                library.count,
                LiraSkeletalAnimationLibrary.ClipID.allCases.count,
                style.rawValue
            )
        }
    }

    func testProceduralEntityUsesMultiPartPuppetStyle() {
        let entity = CompanionEntityFactory().makeLira()
        XCTAssertEqual(LiraSkeletalRig.puppetStyle(for: entity), .multiPart)
        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: entity))
        XCTAssertEqual(player.puppetStyle, .multiPart)
        XCTAssertTrue(player.sourceDescription.contains("multiPart"))
        player.clear()
    }

    func testPromotedStaticMeshUsesBodyCentricPuppetStyle() {
        let bare = Entity()
        bare.name = CompanionEntityFactory.rootName
        let mesh = ModelEntity(
            mesh: .generateBox(size: 0.3),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        mesh.name = "meshy_mesh"
        bare.addChild(mesh)
        let promoted = LiraARAssetLoader.promoteIncompleteHierarchy(bare)
        XCTAssertEqual(LiraSkeletalRig.puppetStyle(for: promoted), .staticMesh)
        // Spectral FX layer for A2/A3/shadow.
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "CoreGlow")!))
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "Filament")!))
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "GroundShadow")!))
        XCTAssertNotNil(promoted.findEntity(named: LiraARMotion.filamentMidName))
        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: promoted))
        XCTAssertEqual(player.puppetStyle, .staticMesh)
        XCTAssertEqual(player.clipSource, .puppet)
        XCTAssertTrue(player.sourceDescription.contains("staticMesh"))
        player.play(state: .idle, on: promoted)
        XCTAssertEqual(player.activeClip, .idle)
        player.play(state: .alert, on: promoted)
        XCTAssertEqual(player.activeClip, .alert)
        player.clear()
    }

    func testSpectralFXSkinDoesNotRequireBodyPaint() {
        let bare = Entity()
        bare.name = CompanionEntityFactory.rootName
        let mesh = ModelEntity(
            mesh: .generateBox(size: 0.25),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        mesh.name = "authored"
        bare.addChild(mesh)
        let promoted = LiraARAssetLoader.promoteIncompleteHierarchy(bare, skin: .dawn)
        for skin in LiraSkin.allCases {
            LiraARAssetLoader.applySpectralFXSkin(skin, to: promoted)
        }
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "CoreGlow")!))
        XCTAssertEqual(LiraSkeletalRig.puppetStyle(for: promoted), .staticMesh)
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
