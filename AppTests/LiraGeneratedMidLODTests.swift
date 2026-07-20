import XCTest
@testable import WaykinApp

/// GENERATED_MID_LOD package + joint token contract (#159).
@MainActor
final class LiraGeneratedMidLODTests: XCTestCase {
    func testPackagedEvidenceClassIsArtistBlendMidLOD() {
        // Runtime package prefers artist Blender export when present (#161).
        XCTAssertEqual(LiraARAssetCatalog.packagedEvidenceClass, "ARTIST_BLEND_MID_LOD")
        XCTAssertTrue(LiraARAssetCatalog.packagedLODHint.contains("ARTIST_BLEND_MID_LOD"))
    }

    func testUSDASourceDeclaresGeneratedClassAndJoints() throws {
        // Prefer repo USDA path relative to this test file → walk up to repo root.
        let thisFile = URL(fileURLWithPath: #filePath)
        var dir = thisFile.deletingLastPathComponent()
        var usda: URL?
        for _ in 0..<6 {
            let candidate = dir.appendingPathComponent("docs/assets/companion/ar/src/Lira_AR_Base.usda")
            if FileManager.default.fileExists(atPath: candidate.path) {
                usda = candidate
                break
            }
            dir = dir.deletingLastPathComponent()
        }
        guard let usda else {
            throw XCTSkip("USDA source not found from test bundle path")
        }
        let text = try String(contentsOf: usda, encoding: .utf8)
        XCTAssertTrue(text.contains("GENERATED_MID_LOD"))
        for name in [
            "LiraRoot", "Body", "Head", "LeftEar", "RightEar", "Tail",
            "Filament", "FilamentBase", "FilamentMid", "FilamentTip",
            "CoreGlow", "GroundShadow", "StatusIndicator"
        ] {
            XCTAssertTrue(text.contains("\"\(name)\""), "missing \(name)")
        }
    }

    func testSkeletalRigListsFilamentSegments() {
        XCTAssertTrue(LiraSkeletalRig.filamentSegments.contains("FilamentMid"))
        XCTAssertTrue(LiraSkeletalRig.filamentSegments.contains("FilamentTip"))
        XCTAssertTrue(LiraSkeletalRig.hasSkeletalJoints(
            CompanionEntityFactory().makeLira()
        ))
    }
}
