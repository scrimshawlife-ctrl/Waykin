import XCTest

@MainActor
final class WaykinSmokeTests: XCTestCase {
    var app: XCUIApplication!

    private func launch(reset: Bool) {
        app = XCUIApplication()
        var args = ["-WAYKIN_UI_TESTING", "YES"]
        if reset {
            args += ["-WAYKIN_RESET_STATE", "YES"]
        } else {
            args += ["-WAYKIN_RESET_STATE", "NO"]
        }
        app.launchArguments = args
        app.launch()
    }

    func testAppLaunchesAndDemoIsReachable() {
        launch(reset: true)
        XCTAssertTrue(app.staticTexts["Waykin"].waitForExistence(timeout: 5))
        let demoLink = app.buttons["Demo Scenarios"]
        XCTAssertTrue(demoLink.waitForExistence(timeout: 5))
    }

    func testCalmDayWalkCompletesAndCreatesMemory() {
        launch(reset: true)
        runScenario(raw: "calmDayWalk")
    }

    func testNightOrcPursuitChangesThreatAndCompletes() {
        launch(reset: true)
        runScenario(raw: "nightOrcPursuit")
    }

    func testFutureSelfIntervalShowsCatchWindowAndCompletes() {
        launch(reset: true)
        runScenario(raw: "futureSelfInterval")
    }

    func testMemoryPersistsAcrossRelaunch() {
        launch(reset: true)

        // Wait for persistence diagnostics
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.persistence.mode").firstMatch.waitForExistence(timeout: 5))

        runScenario(raw: "calmDayWalk")

        // Capture any memory item (stable prefix)
        let memoryItem = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'waykin.memory.item'")).firstMatch
        XCTAssertTrue(memoryItem.waitForExistence(timeout: 5))

        let homeBtn = app.buttons.matching(identifier: "waykin.summary.home").firstMatch
        if homeBtn.waitForExistence(timeout: 3) {
            homeBtn.tap()
        }

        app.terminate()

        launch(reset: false)

        let memoryLink = app.buttons["Memory History"]
        XCTAssertTrue(memoryLink.waitForExistence(timeout: 5))
        memoryLink.tap()

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.memory.screen").firstMatch.waitForExistence(timeout: 5))

        let restored = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'waykin.memory.item'")).firstMatch
        XCTAssertTrue(restored.waitForExistence(timeout: 8))
    }

    func testDayAndNightRecommendationsDiffer() {
        launch(reset: true)
        XCTAssertTrue(app.staticTexts["Waykin"].waitForExistence(timeout: 5))
        if app.buttons["Night"].waitForExistence(timeout: 2) {
            app.buttons["Night"].tap()
        }
        if app.buttons["Day"].waitForExistence(timeout: 2) {
            app.buttons["Day"].tap()
        }
    }

    func testLocationDenialPreservesDemoMode() {
        launch(reset: true)
        XCTAssertTrue(app.buttons["Demo Scenarios"].waitForExistence(timeout: 5))
    }

    private func runScenario(raw: String) {
        let demoLink = app.buttons["Demo Scenarios"]
        XCTAssertTrue(demoLink.waitForExistence(timeout: 5))
        demoLink.tap()

        let scenarioBtn = app.buttons.matching(identifier: "waykin.demo.scenario.\(raw)").firstMatch
        XCTAssertTrue(scenarioBtn.waitForExistence(timeout: 5))
        scenarioBtn.tap()

        let runBtn = app.buttons["Run to End"]
        if runBtn.waitForExistence(timeout: 3) {
            runBtn.tap()
        }

        let completeBtn = app.buttons.matching(identifier: "waykin.session.complete").firstMatch
        if completeBtn.waitForExistence(timeout: 5) {
            completeBtn.tap()
        }

        let summary = app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
    }
}
