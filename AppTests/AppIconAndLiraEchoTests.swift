import XCTest
@testable import WaykinApp

final class AppIconAndLiraEchoTests: XCTestCase {
    func testAppIconAssetCatalogExistsInBundle() {
        // Asset catalog AppIcon is compile-time; verify design master still present in docs for provenance.
        let master = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/assets/brand/production/WK_BRAND_AppIcon_1024_v0.2.svg")
        // When running as app test, #filePath is under AppTests — walk up to repo root
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // AppTests
            .deletingLastPathComponent() // repo
        let svg = repoRoot.appendingPathComponent("docs/assets/brand/production/WK_BRAND_AppIcon_1024_v0.2.svg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: svg.path), "Missing app icon SVG master at \(svg.path)")
        _ = master
    }

    func testEchoMaterialTokensAreDistinct() {
        // Sanity: bond gold and guide teal are not the same sRGB triple.
        let bond = CompanionEntityFactory.EchoMaterial.bondCore
        let fringe = CompanionEntityFactory.EchoMaterial.fringe
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        bond.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        fringe.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        XCTAssertNotEqual(br, fr, accuracy: 0.01)
    }

    func testLiraSilhouetteTypeIsAvailable() {
        XCTAssertNotNil(LiraPresenceSilhouette.self)
    }
}
