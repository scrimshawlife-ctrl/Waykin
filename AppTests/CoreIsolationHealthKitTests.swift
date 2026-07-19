import XCTest

/// Structural reminder: HealthKit must not appear in WaykinCore sources.
final class CoreIsolationHealthKitTests: XCTestCase {
    func testWaykinCoreSourcesDoNotImportHealthKit() throws {
        let core = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // AppTests
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("Sources/WaykinCore", isDirectory: true)

        let enumerator = FileManager.default.enumerator(
            at: core,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        var scanned = 0
        while let item = enumerator?.nextObject() as? URL {
            guard item.pathExtension == "swift" else { continue }
            scanned += 1
            let text = try String(contentsOf: item, encoding: .utf8)
            XCTAssertFalse(
                text.contains("import HealthKit"),
                "HealthKit leak in \(item.lastPathComponent)"
            )
        }
        XCTAssertGreaterThan(scanned, 5)
    }
}
