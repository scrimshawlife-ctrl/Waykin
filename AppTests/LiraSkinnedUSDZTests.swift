import RealityKit
import XCTest
@testable import WaykinApp

/// Hard asserts on packaged ARTIST_BLEND_HERO_DCC_MID_LOD (not soft procedural fallback).
@MainActor
final class LiraHeroDCCUSDZTests: XCTestCase {
    func testPackagedEvidenceClassIsArtistBlendHeroDCCMidLOD() {
        XCTAssertEqual(LiraARAssetCatalog.packagedEvidenceClass, "ARTIST_BLEND_HERO_DCC_MID_LOD")
        XCTAssertTrue(LiraARAssetCatalog.packagedLODHint.contains("ARTIST_BLEND_HERO_DCC_MID_LOD"))
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
        let style = LiraSkeletalRig.puppetStyle(for: entity)
        // Artist multi-part mid-LOD → multiPart; Meshy single-mesh interim → staticMesh.
        XCTAssertTrue(
            style == .multiPart || style == .staticMesh,
            "unexpected puppet style \(style) for \(loader.activeLODDescription)"
        )
        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: entity))
        XCTAssertEqual(player.puppetStyle, style)
        // Artist package may bind DCC clips; Meshy static uses puppet fill.
        XCTAssertTrue(
            player.clipSource == .puppet || player.clipSource == .dcc || player.clipSource == .hybrid,
            "unexpected clipSource \(player.clipSource) desc=\(player.sourceDescription)"
        )
        XCTAssertTrue(
            player.sourceDescription.contains(style.rawValue)
                || player.sourceDescription.contains("multiPart")
                || player.sourceDescription.contains("staticMesh")
                || player.sourceDescription.contains("dcc")
                || player.sourceDescription.contains("hybrid")
                || player.sourceDescription.contains("puppet"),
            "sourceDescription=\(player.sourceDescription)"
        )
        player.play(state: .follow, on: entity)
        XCTAssertEqual(player.activeClip, .follow)
        player.clear()
    }

    /// Sim-only binding report for the artist package (not outdoor #41).
    ///
    /// Documents whether RealityKit surfaces DCC clips from the runtime USDZ.
    /// Sidecar clip USDs in the archive do not automatically appear as
    /// `availableAnimations` until packaging composes them — expect puppet fill today.
    func testArtistPackageAnimationBindingReport() async throws {
        guard let url = LiraARAssetCatalog.baseUSDZURL else {
            throw XCTSkip("Packaged Lira_AR_Base.usdz not in test host bundle")
        }
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle(usdzURL: url)
        guard case .usdz = loader.source else {
            XCTFail("expected usdz load: \(loader.activeLODDescription)")
            return
        }

        XCTAssertFalse(
            loader.hasAuthoredAnimation,
            "artist multi-part package must not take hierarchy-less single-clip path"
        )
        XCTAssertTrue(
            loader.loadNote.contains("artist_blend"),
            "loadNote=\(loader.loadNote)"
        )

        let entity = loader.makeLira()
        let clipCount = LiraARAssetLoader.animationClipCount(entity)
        let dccMapped = LiraSkeletalPlayer.mapDCCAnimations(from: entity)
        let style = LiraSkeletalRig.puppetStyle(for: entity)
        let player = LiraSkeletalPlayer()
        XCTAssertTrue(player.install(on: entity), "skeletal install should succeed")

        // OBSERVED (sim): publish binding facts for receipts / follow-up packaging work.
        let report = [
            "loadNote=\(loader.loadNote)",
            "lod=\(loader.activeLODDescription)",
            "puppetStyle=\(style.rawValue)",
            "availableAnimations=\(clipCount)",
            "dccMapped=\(dccMapped.count)",
            "dccKeys=\(dccMapped.keys.map(\.rawValue).sorted().joined(separator: ","))",
            "clipSource=\(player.clipSource.rawValue)",
            "sourceDescription=\(player.sourceDescription)",
            "hasAuthoredAnimation=\(loader.hasAuthoredAnimation)",
        ].joined(separator: " | ")
        XCTContext.runActivity(named: "artist_usdz_animation_binding") { _ in
            XCTAssertTrue(true, report)
        }
        print("WAYKIN_SIM_ANIM_BINDING: \(report)")

        XCTAssertEqual(style, .multiPart, "artist mid-LOD should be multiPart")
        // Until composition_followup lands, RealityKit may expose 0 DCC clips on the
        // default layer — puppet library still drives state clips.
        if clipCount == 0 {
            XCTAssertEqual(player.clipSource, .puppet, report)
        } else {
            XCTAssertTrue(
                player.clipSource == .dcc || player.clipSource == .hybrid || player.clipSource == .puppet,
                report
            )
        }
        player.play(state: .idle, on: entity)
        XCTAssertEqual(player.activeClip, .idle)
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
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "CoreGlow")!))
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "Filament")!))
        XCTAssertTrue(LiraARAssetLoader.hasModelGeometry(promoted.findEntity(named: "GroundShadow")!))
        XCTAssertEqual(LiraSkeletalRig.puppetStyle(for: promoted), .staticMesh)
    }

    func testLayoutSpectralFXAnchorsPlacesCoreAboveGround() {
        let bare = Entity()
        bare.name = CompanionEntityFactory.rootName
        // Tall box so bounds are well-defined.
        let mesh = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.3, 0.6, 0.25)),
            materials: [SimpleMaterial(color: .gray, isMetallic: false)]
        )
        mesh.name = "body_mesh"
        bare.addChild(mesh)
        let promoted = LiraARAssetLoader.promoteIncompleteHierarchy(bare)
        LiraARAssetLoader.normalizeVisualHeight(promoted.findEntity(named: "Body")!, targetHeightMeters: 0.72)
        LiraARAssetLoader.plantBodyOnGround(promoted)
        LiraARAssetLoader.layoutSpectralFXAnchors(on: promoted)
        let core = promoted.findEntity(named: "CoreGlow")!
        let filament = promoted.findEntity(named: "Filament")!
        let shadow = promoted.findEntity(named: "GroundShadow")!
        XCTAssertGreaterThan(core.position.y, shadow.position.y)
        XCTAssertGreaterThan(core.position.z, filament.position.z, "ember forward of plume")
        // After plant: feet ~0, chest mid-torso — meaningful vertical separation.
        XCTAssertGreaterThan(core.position.y - shadow.position.y, 0.2)
        XCTAssertGreaterThan(core.position.y, 0.2)
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
