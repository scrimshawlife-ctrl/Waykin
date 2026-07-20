import RealityKit
import XCTest
@testable import WaykinApp

/// Hard asserts on packaged ARTIST_BLEND_SKINNED_MID_LOD (not soft procedural fallback).
@MainActor
final class LiraSkinnedUSDZTests: XCTestCase {
    func testPackagedEvidenceClassIsSkinnedMidLOD() {
        XCTAssertEqual(LiraARAssetCatalog.packagedEvidenceClass, "ARTIST_BLEND_SKINNED_MID_LOD")
        XCTAssertTrue(LiraARAssetCatalog.packagedLODHint.contains("ARTIST_BLEND_SKINNED_MID_LOD"))
        XCTAssertTrue(LiraARAssetCatalog.hasPackagedUSDZ)
    }

    func testPackagedUSDZLoadsHierarchyAndAcceptsSkeletalInstall() async throws {
        guard let url = LiraARAssetCatalog.baseUSDZURL else {
            throw XCTSkip("Packaged Lira_AR_Base.usdz not in test host bundle")
        }
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle(usdzURL: url)
        guard case .usdz(let name) = loader.source else {
            XCTFail("Expected packaged USDZ load, got \(loader.activeLODDescription)")
            return
        }
        XCTAssertEqual(name, "Lira_AR_Base.usdz")
        XCTAssertTrue(loader.loadNote.contains("skinned") || loader.loadNote.contains("artist_blend"))
        XCTAssertTrue(loader.activeLODDescription.contains("artist_blend_usdz"))

        let entity = loader.makeLira()
        XCTAssertEqual(entity.name, CompanionEntityFactory.rootName)
        for node in CompanionEntityFactory.requiredNodeNames {
            XCTAssertNotNil(entity.findEntity(named: node), "missing \(node)")
        }
        XCTAssertTrue(LiraSkeletalRig.hasSkeletalJoints(entity))

        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: entity))
        player.play(state: .idle, on: entity)
        XCTAssertEqual(player.activeClip, .idle)
        player.play(state: .alert, on: entity)
        XCTAssertEqual(player.activeClip, .alert)
        player.clear()
        XCTAssertFalse(player.isDriving)
    }

    func testApplySkinAllFormsOnPackagedClone() async throws {
        guard let url = LiraARAssetCatalog.baseUSDZURL else {
            throw XCTSkip("Packaged Lira_AR_Base.usdz not in test host bundle")
        }
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle(usdzURL: url)
        guard case .usdz = loader.source else {
            XCTFail("USDZ required for skin remap test: \(loader.activeLODDescription)")
            return
        }
        for skin in LiraSkin.allCases {
            loader.skin = skin
            let entity = loader.makeLira()
            XCTAssertTrue(LiraARAssetLoader.hasRequiredNodes(entity), "skin \(skin.rawValue)")
            // Live re-paint path
            LiraARAssetLoader.applySkin(.dawn, to: entity)
            LiraARAssetLoader.applySkin(skin, to: entity)
            XCTAssertNotNil(entity.findEntity(named: "CoreGlow"))
        }
    }

    func testRendererReduceMotionStopsSkeletalDriving() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        XCTAssertFalse(renderer.reduceMotionEnabled)
        renderer.reduceMotionEnabled = true
        XCTAssertFalse(renderer.isSkeletalDriving)
        XCTAssertTrue(renderer.motionDiagnosticsLine.contains("reduce_motion")
            || renderer.motionDiagnosticsLine.contains("skel_off"))
        renderer.reduceMotionEnabled = false
        // No companion planted — still skel_off until install.
        XCTAssertFalse(renderer.isSkeletalDriving)
    }

    func testRendererLiveSkinSetterDoesNotCrashWithoutCompanion() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        renderer.companionSkin = .veil
        XCTAssertEqual(renderer.companionSkin, .veil)
        renderer.companionSkin = .rupture
        XCTAssertEqual(renderer.companionSkin, .rupture)
        renderer.reapplySkinToLiveCompanion()
    }
}
