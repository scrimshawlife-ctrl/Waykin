import RealityKit
import XCTest
@testable import WaykinApp

/// Hard asserts on packaged MESHY_TEXTURED_STATIC_V1 (not soft procedural fallback).
@MainActor
final class LiraHeroDCCUSDZTests: XCTestCase {
    func testPackagedEvidenceClassIsMeshyTexturedStatic() {
        XCTAssertEqual(LiraARAssetCatalog.packagedEvidenceClass, "MESHY_TEXTURED_STATIC_V1")
        XCTAssertTrue(LiraARAssetCatalog.packagedLODHint.contains("MESHY_TEXTURED_STATIC_V1"))
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
        XCTAssertTrue(
            loader.loadNote.contains("meshy_textured")
                || loader.loadNote.contains("artist_blend")
                || loader.loadNote.contains("skinned")
        )
        XCTAssertTrue(
            loader.activeLODDescription.contains("meshy_usdz")
                || loader.activeLODDescription.contains("artist_blend_usdz")
        )

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

    func testSkeletalPlayerReportsClipSource() async throws {
        guard let url = LiraARAssetCatalog.baseUSDZURL else {
            throw XCTSkip("no package")
        }
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle(usdzURL: url)
        guard case .usdz = loader.source else {
            XCTFail(loader.activeLODDescription)
            return
        }
        let entity = loader.makeLira()
        XCTAssertEqual(
            LiraSkeletalRig.puppetStyle(for: entity),
            .staticMesh,
            "Meshy package should detect static-mesh puppet style"
        )
        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: entity))
        // Meshy static has no DCC clips → body-centric puppet fill.
        XCTAssertEqual(player.clipSource, .puppet)
        XCTAssertEqual(player.puppetStyle, .staticMesh)
        XCTAssertTrue(player.sourceDescription.contains("staticMesh"))
        player.play(state: .follow, on: entity)
        XCTAssertEqual(player.activeClip, .follow)
        player.clear()
    }

    func testPromoteIncompleteHierarchyAddsRequiredNodes() {
        let bare = Entity()
        bare.name = "Root"
        let mesh = ModelEntity(
            mesh: .generateBox(size: 0.2),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        mesh.name = "mesh1"
        bare.addChild(mesh)
        let promoted = LiraARAssetLoader.promoteIncompleteHierarchy(
            LiraARAssetLoader.normalizeRoot(bare)
        )
        XCTAssertTrue(LiraARAssetLoader.hasRequiredNodes(promoted))
        XCTAssertNotNil(promoted.findEntity(named: "Body"))
        XCTAssertNotNil(promoted.findEntity(named: "mesh1"))
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
            // Live re-paint path still safe on marker nodes / optional remaps
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
