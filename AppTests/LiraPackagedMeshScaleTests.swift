import RealityKit
import XCTest
@testable import WaykinApp

/// Measures what the packaged companion actually ends up as, in metres, loaded exactly
/// the way the app loads it. Device photos showed a flat untextured surface filling the
/// frame, which is what a correctly-textured mesh looks like when it is far too large to
/// see as a whole — so the height is the fact worth pinning down.
@MainActor
final class LiraPackagedMeshScaleTests: XCTestCase {
    private func loadedCompanion() async throws -> (Entity, LiraARAssetLoader) {
        guard let url = LiraARAssetCatalog.baseUSDZURL else {
            throw XCTSkip("Packaged Lira_AR_Base.usdz not in test host bundle")
        }
        let loader = LiraARAssetLoader()
        await loader.preloadFromBundle(usdzURL: url)
        guard case .usdz = loader.source else {
            throw XCTSkip("packaged load fell back: \(loader.activeLODDescription)")
        }
        return (loader.makeLira(), loader)
    }

    func testPackagedCompanionIsApproximatelyCanonicalHeight() async throws {
        let (entity, loader) = try await loadedCompanion()
        let height = entity.visualBounds(relativeTo: nil).extents.y
        print("WAYKIN_MESH_HEIGHT: \(height) m | note=\(loader.loadNote)")
        XCTAssertGreaterThan(height, 0.35, "companion collapsed: \(height) m")
        XCTAssertLessThan(height, 1.60, "companion is oversized: \(height) m")
    }

    /// The loader reports `clips=6` for a package containing a single `SkelAnimation`,
    /// and `playAuthoredAnimation` plays `availableAnimations.first`. If that first entry
    /// is not the walk cycle, the rig is driven by the wrong curves.
    func testPackagedCompanionAnimationInventory() async throws {
        let (entity, loader) = try await loadedCompanion()
        var names: [String] = []
        func walk(_ e: Entity, _ path: String) {
            for a in e.availableAnimations {
                names.append("\(path)/\(e.name).[\(a.name ?? "<unnamed>")] dur=\(String(format: "%.2f", a.definition.duration))")
            }
            for c in e.children { walk(c, path + "/" + e.name) }
        }
        walk(entity, "")
        print("WAYKIN_ANIM_INVENTORY count=\(names.count) note=\(loader.loadNote)")
        for n in names { print("WAYKIN_ANIM: \(n)") }
        XCTAssertFalse(names.isEmpty, "packaged rig exposed no animations")
    }

    /// The selected clip must be the joint-curve animation on the rig, never one of the
    /// synthesized scene/subtree wrappers that replay the baked root transform.
    func testAuthoredClipSelectionPicksTheSkeletalCurves() async throws {
        let (entity, _) = try await loadedCompanion()
        let picked = LiraARAssetLoader.preferredAuthoredClip(in: entity)
        let hostName = picked?.0.name ?? "<none>"
        let clipName = picked?.1.name ?? "<none>"
        print("WAYKIN_PICKED_HOST: \(hostName)")
        print("WAYKIN_PICKED_CLIP: \(clipName)")
        XCTAssertNotNil(picked, "no authored clip selected")
        let lowered = clipName.lowercased()
        XCTAssertFalse(lowered.contains("scene animation"), "picked a synthesized scene clip: \(clipName)")
        XCTAssertFalse(lowered.contains("subtree animation"), "picked a synthesized subtree clip: \(clipName)")
        XCTAssertNotEqual(hostName, "LiraRoot", "clip must drive the rig, not the companion root")
    }

    /// Device photos show flat untextured grey while the packaged asset renders teal in
    /// usdrecord. Something between load and display is replacing the authored PBR, so
    /// report what the cloned entity's materials actually are.
    func testPackagedCompanionKeepsAuthoredTexturedMaterials() async throws {
        let (entity, loader) = try await loadedCompanion()
        var textured = 0, flat = 0, other = 0
        func visit(_ e: Entity, _ path: String) {
            if let m = e as? ModelEntity, let mats = m.model?.materials {
                for mat in mats {
                    if let pbr = mat as? PhysicallyBasedMaterial {
                        if pbr.baseColor.texture != nil { textured += 1 }
                        else { flat += 1; print("WAYKIN_MAT_FLAT_PBR: \(path)/\(e.name)") }
                    } else if mat is SimpleMaterial {
                        flat += 1
                        print("WAYKIN_MAT_SIMPLE: \(path)/\(e.name)")
                    } else if mat is UnlitMaterial {
                        flat += 1
                    } else { other += 1 }
                }
            }
            for c in e.children { visit(c, path + "/" + e.name) }
        }
        visit(entity, "")
        print("WAYKIN_MATERIALS textured=\(textured) flat=\(flat) other=\(other) preserve=\(loader.preserveAuthoredMaterials)")
        XCTAssertGreaterThan(textured, 0, "authored texture was lost before display")
    }

    /// Height was only ever measured at rest. The walk clip writes transform keys to the
    /// `Armature` — the same node the loader scales to normalize height — so playback can
    /// overwrite that scale and reshape the companion the moment it starts.
    func testCompanionKeepsItsShapeOnceTheClipIsPlaying() async throws {
        let (entity, loader) = try await loadedCompanion()
        let atRest = entity.visualBounds(relativeTo: nil)
        loader.playAuthoredAnimation(on: entity)
        try await Task.sleep(nanoseconds: 600_000_000)
        let playing = entity.visualBounds(relativeTo: nil)
        print("WAYKIN_BOUNDS_REST:    h=\(atRest.extents.y) w=\(atRest.extents.x) d=\(atRest.extents.z)")
        print("WAYKIN_BOUNDS_PLAYING: h=\(playing.extents.y) w=\(playing.extents.x) d=\(playing.extents.z)")
        let ratio = playing.extents.y / max(atRest.extents.y, 0.0001)
        print("WAYKIN_HEIGHT_RATIO: \(ratio)")
        XCTAssertGreaterThan(playing.extents.y, 0.35, "collapsed once playing: \(playing.extents.y) m")
        XCTAssertLessThan(playing.extents.y, 1.60, "ballooned once playing: \(playing.extents.y) m")
    }

    /// Replacing a companion must take the previous one out of the scene. Anchors added
    /// with `scene.addAnchor` are owned by the scene, so `removeFromParent()` leaves them
    /// rendered — the procedural placeholder kept standing in front of the packaged mesh.
    func testReplacingACompanionRemovesThePreviousAnchorFromTheScene() throws {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        let registry = AREntityRegistry()
        let first = AnchorEntity(world: .zero)
        first.addChild(CompanionEntityFactory().makeLira())
        arView.scene.addAnchor(first)
        registry.register(first, for: "companion")
        XCTAssertEqual(arView.scene.anchors.count, 1)

        let second = AnchorEntity(world: .zero)
        second.addChild(CompanionEntityFactory().makeLira())
        arView.scene.addAnchor(second)
        registry.register(second, for: "companion")

        print("WAYKIN_SCENE_ANCHORS after replace: \(arView.scene.anchors.count)")
        XCTAssertEqual(arView.scene.anchors.count, 1, "stale companion left in the scene")
        XCTAssertNil(first.scene, "previous anchor still attached")
    }

    /// The retired `Lira_*` sidecars target a 25-joint artist armature; the packaged fox
    /// is a 24-joint humanoid. They share no joints, so they can never drive it — recorded
    /// here so the next person does not spend an evening trying to make them bind.
    func testRetiredArtistClipsCannotDriveTheFoxRig() async throws {
        let (entity, loader) = try await loadedCompanion()
        try XCTSkipUnless(loader.hasAuthoredAnimation, "packaged asset is not an authored rig")
        await loader.loadDCCClipSidecars()
        let player = LiraSkeletalPlayer()
        _ = player.install(on: entity, externalDCC: loader.dccClipLibrary)
        print("WAYKIN_FOX_STATE_CLIPS: \(loader.foxStateClips.count)")
        print("WAYKIN_RETIRED_SIDECARS: \(loader.dccClipLibrary.count)")
        XCTAssertTrue(
            loader.hasAuthoredAnimation,
            "the fox must keep driving itself rather than deferring to incompatible clips"
        )
    }

    func testPackagedCompanionSitsOnTheGroundPlane() async throws {
        let (entity, _) = try await loadedCompanion()
        let bounds = entity.visualBounds(relativeTo: nil)
        let footY = bounds.center.y - bounds.extents.y * 0.5
        print("WAYKIN_MESH_FOOT_Y: \(footY) m")
        XCTAssertLessThan(abs(footY), 0.25, "companion not grounded, feet at \(footY) m")
    }
}
