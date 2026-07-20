import UIKit
import XCTest
@testable import WaykinApp

@MainActor
final class LiraGraphicsPathTests: XCTestCase {
    func testStillCatalogCoverageIsFullSevenByThree() {
        let coverage = LiraStillCatalog.catalogCoverage()
        XCTAssertEqual(
            coverage.present,
            LiraSessionPose.allCases.count * LiraSkin.allCases.count,
            "expected full matrix; missing=\(coverage.missing.map { "\($0.0.rawValue)/\($0.1.rawValue)" })"
        )
        XCTAssertTrue(coverage.missing.isEmpty)
    }

    func testGraphicsPathIsCatalogWhenStillLoads() {
        for pose in LiraSessionPose.allCases {
            for skin in LiraSkin.allCases {
                let path = LiraStillCatalog.graphicsPath(pose: pose, skin: skin)
                XCTAssertEqual(
                    path,
                    .catalogStill,
                    "\(pose.rawValue)/\(skin.rawValue) should resolve catalog still"
                )
                XCTAssertEqual(path.diagnosticLabel, "still:catalog")
            }
        }
    }

    func testAssetLoaderLoadNoteAndLODDescription() async {
        let loader = LiraARAssetLoader()
        XCTAssertEqual(loader.loadNote, "not_attempted")
        XCTAssertTrue(loader.activeLODDescription.contains("procedural"))

        await loader.preloadFromBundle(usdzURL: nil)
        XCTAssertEqual(loader.source, .procedural)
        XCTAssertEqual(loader.loadNote, "no_packaged_url")
        XCTAssertTrue(loader.activeLODDescription.contains("no_packaged_url"))

        // Packaged URL path (may still fall back if RealityKit rejects file).
        await loader.preloadFromBundle()
        XCTAssertTrue(
            loader.activeLODDescription.contains("procedural")
                || loader.activeLODDescription.contains("generated_usdz")
                || loader.activeLODDescription.contains("meshy_usdz")
                || loader.activeLODDescription.contains("artist_blend_usdz")
                || loader.activeLODDescription.contains("artist_usdz"),
            "unexpected LOD: \(loader.activeLODDescription) loadNote=\(loader.loadNote)"
        )
        XCTAssertNotEqual(loader.loadNote, "not_attempted")
    }

    func testGlyphsResolveInCatalog() {
        for skin in LiraSkin.allCases {
            let name = LiraStillCatalog.glyphName(for: skin)
            XCTAssertNotNil(UIImage(named: name), "missing glyph \(name)")
        }
    }
}
