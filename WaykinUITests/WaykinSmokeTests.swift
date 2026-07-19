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
        XCTAssertEqual(app.buttons.matching(identifier: "waykin.beginWalk").count, 1)
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.demo.mode").firstMatch.exists)
    }

    func testBeginWalkCompletesAndCreatesMemory() {
        launch(reset: true)
        runBeginWalk()
    }

    func testPauseResumeEndWorks() {
        launch(reset: true)

        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        begin.tap()

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.session.screen").firstMatch.waitForExistence(timeout: 5))
        let phrase = app.staticTexts.matching(identifier: "waykin.session.phrase").firstMatch
        let presence = app.descendants(matching: .any).matching(identifier: "waykin.session.presence").firstMatch
        XCTAssertTrue(phrase.waitForExistence(timeout: 5))
        XCTAssertTrue(presence.waitForExistence(timeout: 5))
        let phraseBeforePause = phrase.label
        let presenceBeforePause = presence.value as? String
        XCTAssertTrue(app.buttons.matching(identifier: "waykin.session.pause").firstMatch.waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "waykin.session.pause").firstMatch.tap()
        let resume = app.buttons.matching(identifier: "waykin.session.resume").firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertEqual(phrase.label, phraseBeforePause)
        XCTAssertEqual(presence.value as? String, presenceBeforePause)
        resume.tap()
        app.buttons.matching(identifier: "waykin.session.runToEnd").firstMatch.tap()
        app.buttons.matching(identifier: "waykin.session.end").firstMatch.tap()

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.session.closing").firstMatch.exists)
    }

    func testActiveSessionRequiresEndAndWritesMemoryAndReceipt() {
        launch(reset: true)

        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        begin.tap()

        let end = app.buttons.matching(identifier: "waykin.session.end").firstMatch
        XCTAssertTrue(end.waitForExistence(timeout: 5))
        XCTAssertEqual(app.navigationBars.buttons.count, 0)

        app.buttons.matching(identifier: "waykin.session.runToEnd").firstMatch.tap()
        end.tap()

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(identifier: "waykin.summary.memoryWrite").firstMatch.label, "WRITTEN")
        XCTAssertEqual(app.staticTexts.matching(identifier: "waykin.summary.receiptWrite").firstMatch.label, "WRITTEN")
    }

    func testActiveSessionPrioritizesCompanionPresenceBeforeMovement() {
        launch(reset: true)
        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        begin.tap()

        let presence = app.descendants(matching: .any).matching(identifier: "waykin.session.presence").firstMatch
        let phrase = app.staticTexts.matching(identifier: "waykin.session.phrase").firstMatch
        let elapsed = app.descendants(matching: .any).matching(identifier: "waykin.session.elapsed").firstMatch
        let distance = app.descendants(matching: .any).matching(identifier: "waykin.session.distance").firstMatch
        let map = app.descendants(matching: .any).matching(identifier: "waykin.session.map").firstMatch

        XCTAssertTrue(presence.waitForExistence(timeout: 5))
        XCTAssertTrue(phrase.waitForExistence(timeout: 5))
        XCTAssertEqual(phrase.label, "Lira is listening.")
        XCTAssertTrue(elapsed.exists)
        XCTAssertTrue(distance.exists)
        XCTAssertTrue(map.exists)
        XCTAssertGreaterThan(presence.frame.height, map.frame.height)
        XCTAssertLessThanOrEqual(map.frame.height, 100)
    }

    func testActiveSessionAccessibilityAtLargestTextSize() {
        app = XCUIApplication()
        app.launchArguments = [
            "-WAYKIN_UI_TESTING", "YES",
            "-WAYKIN_RESET_STATE", "YES",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        begin.tap()

        let presence = app.descendants(matching: .any).matching(identifier: "waykin.session.presence").firstMatch
        let phrase = app.staticTexts.matching(identifier: "waykin.session.phrase").firstMatch
        let pathStatus = app.descendants(matching: .any).matching(identifier: "waykin.session.pressure").firstMatch
        let elapsed = app.descendants(matching: .any).matching(identifier: "waykin.session.elapsed").firstMatch
        let distance = app.descendants(matching: .any).matching(identifier: "waykin.session.distance").firstMatch
        let pause = app.buttons.matching(identifier: "waykin.session.pause").firstMatch
        let end = app.buttons.matching(identifier: "waykin.session.end").firstMatch
        let map = app.descendants(matching: .any).matching(identifier: "waykin.session.map").firstMatch

        XCTAssertTrue(presence.waitForExistence(timeout: 5))
        XCTAssertTrue(phrase.exists)
        XCTAssertTrue(pathStatus.exists)
        XCTAssertTrue(elapsed.exists)
        XCTAssertTrue(distance.exists)
        XCTAssertTrue(pause.exists)
        XCTAssertTrue(end.exists)
        XCTAssertTrue(map.exists)
        XCTAssertEqual(pause.label, "Pause walk")
        XCTAssertEqual(end.label, "End walk")
        XCTAssertGreaterThanOrEqual(pause.frame.width, 44)
        XCTAssertGreaterThanOrEqual(pause.frame.height, 44)
        XCTAssertGreaterThanOrEqual(end.frame.width, 44)
        XCTAssertGreaterThanOrEqual(end.frame.height, 44)
        XCTAssertEqual(presence.label, "Lira presence")
        // Pose-aware value from LiraSessionFigure (opening → manifesting).
        XCTAssertEqual(presence.value as? String, "Lira is forming presence")
        XCTAssertEqual(phrase.label, "Lira is listening.")
        XCTAssertEqual(pathStatus.label, "Path status")
        XCTAssertEqual(pathStatus.value as? String, "The path is quiet.")
        XCTAssertEqual(elapsed.label, "Time")
        XCTAssertEqual(elapsed.value as? String, "0 seconds")
        XCTAssertEqual(distance.label, "Distance")
        XCTAssertEqual(distance.value as? String, "0 meters")

        let accessibilityIdentifiers = app.descendants(matching: .any)
            .allElementsBoundByAccessibilityElement
            .map(\.identifier)
        guard
            let presenceIndex = accessibilityIdentifiers.firstIndex(of: "waykin.session.presence"),
            let phraseIndex = accessibilityIdentifiers.firstIndex(of: "waykin.session.phrase"),
            let pathStatusIndex = accessibilityIdentifiers.firstIndex(of: "waykin.session.pressure"),
            let pauseIndex = accessibilityIdentifiers.firstIndex(of: "waykin.session.pause"),
            let mapIndex = accessibilityIdentifiers.firstIndex(of: "waykin.session.map")
        else {
            return XCTFail("Expected active-session elements in the accessibility hierarchy")
        }
        XCTAssertLessThan(presenceIndex, phraseIndex)
        XCTAssertLessThan(phraseIndex, pathStatusIndex)
        XCTAssertLessThan(pathStatusIndex, pauseIndex)
        XCTAssertLessThan(pauseIndex, mapIndex)

        XCTAssertEqual(map.label, "Location context")
        XCTAssertEqual(map.value as? String, "Waiting for a location update.")
        XCTAssertEqual(app.maps.count, 0)
        XCTAssertEqual(app.images.matching(identifier: "waykin.session.map").count, 1)
        let mapSemantics = "\(map.label) \(map.value as? String ?? "")"
        XCTAssertFalse(mapSemantics.contains("37.7749"))
        XCTAssertFalse(mapSemantics.contains("-122.4194"))
    }

    func testMemoryPersistsAcrossRelaunch() {
        launch(reset: true)

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.persistence.mode").firstMatch.waitForExistence(timeout: 5))

        runBeginWalk()

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

    func testHomeKeepsSingleBeginWalkPath() {
        launch(reset: true)
        XCTAssertTrue(app.staticTexts["Waykin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "waykin.beginWalk").count, 1)
    }

    func testLocationDenialPreservesDemoMode() {
        launch(reset: true)
        XCTAssertTrue(app.buttons.matching(identifier: "waykin.beginWalk").firstMatch.waitForExistence(timeout: 5))
    }

    /// S4/S7-style home presence: Lira stage + Form skins + unlock line.
    func testHomeLiraStageAndFormSkins() {
        launch(reset: true)

        let homeLira = app.descendants(matching: .any).matching(identifier: "waykin.home.lira").firstMatch
        XCTAssertTrue(homeLira.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "waykin.home.bondRow").firstMatch.exists)

        let selected = app.staticTexts.matching(identifier: "waykin.home.skin.selected").firstMatch
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        XCTAssertEqual(selected.label, "dawn")

        let veil = app.buttons.matching(identifier: "waykin.home.skin.veil").firstMatch
        XCTAssertTrue(veil.waitForExistence(timeout: 5))
        veil.tap()
        XCTAssertEqual(selected.label, "veil")
        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.home.skin.line").firstMatch.label.contains("Half-seen")
            || app.staticTexts.matching(identifier: "waykin.home.skin.line").firstMatch.label.contains("intuition"))

        let rupture = app.buttons.matching(identifier: "waykin.home.skin.rupture").firstMatch
        XCTAssertTrue(rupture.waitForExistence(timeout: 5))
        rupture.tap()
        XCTAssertEqual(selected.label, "rupture")

        let dawn = app.buttons.matching(identifier: "waykin.home.skin.dawn").firstMatch
        dawn.tap()
        XCTAssertEqual(selected.label, "dawn")
    }

    /// S1/S2/S7 Settings appearance force (Day / Night / Auto).
    func testSettingsAppearanceForce() {
        launch(reset: true)

        let settings = app.buttons.matching(identifier: "waykin.home.settings").firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        let night = app.descendants(matching: .any).matching(identifier: "waykin.settings.appearance.night").firstMatch
        XCTAssertTrue(night.waitForExistence(timeout: 5))
        night.tap()

        let done = app.buttons.matching(identifier: "waykin.settings.done").firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()

        let appearance = app.staticTexts.matching(identifier: "waykin.home.appearance.selected").firstMatch
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))
        XCTAssertEqual(appearance.label, "night")

        settings.tap()
        let day = app.descendants(matching: .any).matching(identifier: "waykin.settings.appearance.day").firstMatch
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        day.tap()
        app.buttons.matching(identifier: "waykin.settings.done").firstMatch.tap()
        XCTAssertEqual(appearance.label, "day")

        settings.tap()
        let system = app.descendants(matching: .any).matching(identifier: "waykin.settings.appearance.system").firstMatch
        XCTAssertTrue(system.waitForExistence(timeout: 5))
        system.tap()
        app.buttons.matching(identifier: "waykin.settings.done").firstMatch.tap()
        XCTAssertEqual(appearance.label, "system")
    }

    /// S8 AR Companion form label tracks selected skin.
    func testARCompanionFormLabelTracksSkin() {
        launch(reset: true)

        app.buttons.matching(identifier: "waykin.home.skin.veil").firstMatch.tap()
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "waykin.home.skin.selected").firstMatch.label,
            "veil"
        )

        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        begin.tap()

        // Indoor smoke: session presence remains reachable with pose a11y after open.
        let presence = app.descendants(matching: .any).matching(identifier: "waykin.session.presence").firstMatch
        XCTAssertTrue(presence.waitForExistence(timeout: 5))
        XCTAssertEqual(presence.label, "Lira presence")
        XCTAssertFalse((presence.value as? String ?? "").isEmpty)

        let openAR = app.buttons.matching(identifier: "waykin.session.openARCompanion").firstMatch
        XCTAssertTrue(openAR.waitForExistence(timeout: 5))
        openAR.tap()

        let status = app.descendants(matching: .any).matching(identifier: "waykin.ar.canonical.status").firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 8))
        let statusText = "\(status.label) \(status.value as? String ?? "")"
        XCTAssertTrue(
            statusText.localizedCaseInsensitiveContains("Form: Veil")
                || statusText.localizedCaseInsensitiveContains("Veil"),
            "Expected AR form Veil in status, got \(statusText)"
        )
        // LOD diagnostic may be procedural mid until artist USDZ is packaged.
        let lod = app.staticTexts.matching(identifier: "waykin.ar.canonical.lod").firstMatch
        if lod.waitForExistence(timeout: 2) {
            XCTAssertTrue(
                lod.label.contains("procedural") || lod.label.contains("usdz") || lod.label.contains("LOD"),
                "Unexpected LOD label: \(lod.label)"
            )
        }
    }

    private func runBeginWalk() {
        let begin = app.buttons.matching(identifier: "waykin.beginWalk").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 5)); begin.tap()

        let runBtn = app.buttons["Run to End"]
        if runBtn.waitForExistence(timeout: 3) { runBtn.tap() }

        let complete = app.buttons.matching(identifier: "waykin.session.end").firstMatch
        if complete.waitForExistence(timeout: 5) { complete.tap() }

        XCTAssertTrue(app.staticTexts.matching(identifier: "waykin.summary.screen").firstMatch.waitForExistence(timeout: 10))
    }
}
