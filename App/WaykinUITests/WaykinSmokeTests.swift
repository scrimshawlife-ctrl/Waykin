import XCTest

/// UI smoke tests — launch-arg + accessibility-identifier pattern adopted
/// from the first Waykin implementation.
@MainActor
final class WaykinSmokeTests: XCTestCase {
    var app: XCUIApplication!

    private func launch(_ extraArguments: [String]) {
        app = XCUIApplication()
        app.launchArguments = ["--demo-reset"] + extraArguments
        app.launch()
    }

    func testOnboardingCreatesCompanionAndLandsOnHome() {
        launch([])

        let nameField = app.textFields["waykin.onboarding.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Ember")

        let begin = app.buttons["waykin.onboarding.begin"]
        XCTAssertTrue(begin.isEnabled)
        begin.tap()

        XCTAssertTrue(app.staticTexts["Today's adventures"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ember"].exists)
        XCTAssertTrue(app.staticTexts["Stranger"].exists)
    }

    func testDemoSeedShowsYesterdaysMemoryAndRecommendations() {
        launch(["--demo-seed"])

        XCTAssertTrue(app.staticTexts["Ember"].waitForExistence(timeout: 5))
        // Day-2 greeting must reference the seeded memory's location.
        XCTAssertTrue(app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS %@", "Shoreline Park"))
            .firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Shared memories"].exists)
        XCTAssertTrue(app.staticTexts["Today's adventures"].exists)
    }

    func testSessionScreenOpensWithStartControl() {
        launch(["--demo-seed", "--demo-open", "walk-together"])

        let start = app.buttons["waykin.session.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.label.contains("Companion Walk"))
    }
}
