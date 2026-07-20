import XCTest

/// Optional sim screenshot matrix for product evidence (SIMULATOR class only).
///
/// Run only when capturing:
/// ```
/// WAYKIN_CAPTURE_SCREENSHOTS=1 WAYKIN_SCREENSHOT_OUT_DIR=/abs/path \
///   xcodebuild test -scheme Waykin \
///   -destination 'platform=iOS Simulator,name=iPhone 17' \
///   -only-testing:WaykinUITests/ScreenshotMatrixCaptureTests
/// ```
@MainActor
final class ScreenshotMatrixCaptureTests: XCTestCase {
    private var app: XCUIApplication!

    private var outDir: URL? {
        if ProcessInfo.processInfo.environment["WAYKIN_CAPTURE_SCREENSHOTS"] == "1",
           let raw = ProcessInfo.processInfo.environment["WAYKIN_SCREENSHOT_OUT_DIR"],
           !raw.isEmpty {
            return URL(fileURLWithPath: raw, isDirectory: true)
        }
        // Shell capture script writes the absolute out path here so UI tests
        // do not depend on xcodebuild env inheritance.
        let marker = URL(fileURLWithPath: "/tmp/waykin_screenshot_out_dir.txt")
        if let raw = try? String(contentsOf: marker, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return URL(fileURLWithPath: raw, isDirectory: true)
        }
        return nil
    }

    private func launch(appearance: String) {
        app = XCUIApplication()
        app.launchArguments = [
            "-WAYKIN_UI_TESTING", "YES",
            "-WAYKIN_RESET_STATE", "YES",
            "-WAYKIN_APPEARANCE", appearance,
        ]
        app.launch()
    }

    private func saveShot(_ name: String) throws {
        guard let outDir else {
            throw XCTSkip("Set WAYKIN_CAPTURE_SCREENSHOTS=1 and WAYKIN_SCREENSHOT_OUT_DIR to capture")
        }
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let shot = app.screenshot()
        let url = outDir.appendingPathComponent("\(name).png")
        try shot.pngRepresentation.write(to: url)
    }

    func testCaptureDayNightWalkSurfaces() throws {
        guard outDir != nil else {
            throw XCTSkip("Set WAYKIN_CAPTURE_SCREENSHOTS=1 and WAYKIN_SCREENSHOT_OUT_DIR to capture")
        }

        // Day — Home (wait past splash for Begin Walk control)
        launch(appearance: "day")
        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 15))
        // Small settle so layout finishes after splash dismiss.
        Thread.sleep(forTimeInterval: 0.4)
        try saveShot("01_home_day")

        // Day — Active session (Demo)
        begin.tap()
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.session.screen").firstMatch.waitForExistence(timeout: 8))
        Thread.sleep(forTimeInterval: 0.3)
        try saveShot("02_session_day")

        // Day — Summary
        app.buttons.matching(identifier: "waykin.session.runToEnd").firstMatch.tap()
        app.buttons.matching(identifier: "waykin.session.end").firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 0.3)
        try saveShot("03_summary_day")

        // Night — Home + session
        launch(appearance: "night")
        let beginNight = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(beginNight.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 0.4)
        try saveShot("04_home_night")

        beginNight.tap()
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.session.screen").firstMatch.waitForExistence(timeout: 8))
        Thread.sleep(forTimeInterval: 0.3)
        try saveShot("05_session_night")

        app.buttons.matching(identifier: "waykin.session.runToEnd").firstMatch.tap()
        app.buttons.matching(identifier: "waykin.session.end").firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 0.3)
        try saveShot("06_summary_night")
    }
}
