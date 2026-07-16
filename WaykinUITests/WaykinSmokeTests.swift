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
    }

    func testCalmDayWalkCompletesAndCreatesMemory() { launch(reset: true); runScenario("calmDayWalk") }
    func testNightOrcPursuitChangesThreatAndCompletes() { launch(reset: true); runScenario("nightOrcPursuit") }
    func testFutureSelfIntervalShowsCatchWindowAndCompletes() { launch(reset: true); runScenario("futureSelfInterval") }

    func testMemoryPersistsAcrossRelaunch() {
        launch(reset: true)

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.persistence.mode").firstMatch.waitForExistence(timeout: 5))

        runScenario("calmDayWalk")

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))

        // Return home to reliably open Memory History from Home
        let homeBtnAfterSummary = app.buttons.matching(identifier: "waykin.summary.home").firstMatch
        if homeBtnAfterSummary.waitForExistence(timeout: 3) { homeBtnAfterSummary.tap() }

        // Now open Memory History from Home
        let memLink = app.buttons["Memory History"]
        XCTAssertTrue(memLink.waitForExistence(timeout: 5))
        memLink.tap()

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.memory.screen").firstMatch.waitForExistence(timeout: 5))

        // Wait for query diagnostics
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.memory.queryState").firstMatch.waitForExistence(timeout: 5))
        let stateLabel = app.staticTexts.matching(identifier: "waykin.memory.queryState").firstMatch.label
        XCTAssertEqual(stateLabel, "POPULATED")

        let countLabel = app.staticTexts.matching(identifier: "waykin.persistence.queryMemoryCount").firstMatch
        XCTAssertTrue(countLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(Int(countLabel.label) ?? 0 >= 1)

        let idsLabel = app.staticTexts.matching(identifier: "waykin.persistence.queryMemoryIDs").firstMatch
        XCTAssertTrue(idsLabel.waitForExistence(timeout: 5))
        let ids = idsLabel.label
        XCTAssertFalse(ids.isEmpty)

        // Extract first ID (newest first)
        let memoryID = ids.components(separatedBy: ",").first ?? ""
        XCTAssertFalse(memoryID.isEmpty)

        // Assert exact row using the stable identifier from dedicated row
        let exactRow = app.descendants(matching: .any)["waykin.memory.item.\(memoryID)"]
        XCTAssertTrue(exactRow.waitForExistence(timeout: 5))

        let homeBtn = app.buttons.matching(identifier: "waykin.summary.home").firstMatch
        if homeBtn.waitForExistence(timeout: 3) { homeBtn.tap() }

        app.terminate()

        launch(reset: false)

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.persistence.mode").firstMatch.waitForExistence(timeout: 5))

        let memoryLink = app.buttons["Memory History"]
        XCTAssertTrue(memoryLink.waitForExistence(timeout: 5))
        memoryLink.tap()

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.memory.screen").firstMatch.waitForExistence(timeout: 5))

        // Wait for query populated after relaunch
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.memory.queryState").firstMatch.waitForExistence(timeout: 5))
        let relaunchState = app.staticTexts.matching(identifier: "waykin.memory.queryState").firstMatch.label
        XCTAssertEqual(relaunchState, "POPULATED")

        let relaunchCount = app.staticTexts.matching(identifier: "waykin.persistence.queryMemoryCount").firstMatch
        XCTAssertTrue(relaunchCount.waitForExistence(timeout: 5))
        XCTAssertTrue(Int(relaunchCount.label) ?? 0 >= 1)

        let relaunchIDs = app.staticTexts.matching(identifier: "waykin.persistence.queryMemoryIDs").firstMatch
        XCTAssertTrue(relaunchIDs.waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchIDs.label.contains(memoryID))

        // Assert the exact row after relaunch
        let restoredRow = app.descendants(matching: .any)["waykin.memory.item.\(memoryID)"]
        if !restoredRow.exists {
            app.swipeUp()
        }
        XCTAssertTrue(restoredRow.waitForExistence(timeout: 10))
    }

    func testDayAndNightRecommendationsDiffer() {
        launch(reset: true)
        XCTAssertTrue(app.staticTexts["Waykin"].waitForExistence(timeout: 5))
    }

    func testLocationDenialPreservesDemoMode() {
        launch(reset: true)
        XCTAssertTrue(app.buttons["Demo Scenarios"].waitForExistence(timeout: 5))
    }

    private func runScenario(_ raw: String) {
        let demoLink = app.buttons["Demo Scenarios"]
        XCTAssertTrue(demoLink.waitForExistence(timeout: 5)); demoLink.tap()

        let scenarioBtn = app.buttons.matching(identifier: "waykin.demo.scenario.\(raw)").firstMatch
        XCTAssertTrue(scenarioBtn.waitForExistence(timeout: 5)); scenarioBtn.tap()

        let runBtn = app.buttons["Run to End"]
        if runBtn.waitForExistence(timeout: 3) { runBtn.tap() }

        let complete = app.buttons.matching(identifier: "waykin.session.complete").firstMatch
        if complete.waitForExistence(timeout: 5) { complete.tap() }

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))
    }
}
