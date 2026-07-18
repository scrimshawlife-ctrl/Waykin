import Foundation
import XCTest

@MainActor
final class AR3FramePacingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "com.waykin.arlab")
        app.launch()
    }

    func testFramePacingWorkload() {
        let start = app.buttons["waykin.ar.demo.start"]
        let run = app.buttons["waykin.ar.demo.run"]
        let clear = app.buttons["waykin.ar.clear"]
        let result = app.staticTexts["waykin.ar.lastCommand"]
        let registryCount = app.staticTexts["waykin.ar.registryCount"]

        XCTAssertTrue(app.staticTexts["AR: active"].waitForExistence(timeout: 30), "AR tracking did not become active")
        for control in [start, run, clear] {
            XCTAssertTrue(control.waitForExistence(timeout: 20), "AR Lab controls did not become available")
        }
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(registryCount.waitForExistence(timeout: 5))

        completeWarmup(start: start, run: run, clear: clear, result: result, registryCount: registryCount)
        emit("AR3_AUTOMATION_READY")

        sleep(seconds: 25)
        completeMeasuredCycle(1, start: start, run: run, clear: clear, result: result, registryCount: registryCount)
        sleep(seconds: 15)
        completeMeasuredCycle(2, start: start, run: run, clear: clear, result: result, registryCount: registryCount)
        sleep(seconds: 15)
        completeMeasuredCycle(3, start: start, run: run, clear: clear, result: result, registryCount: registryCount)

        emit("AR3_AUTOMATION_WORKLOAD_COMPLETE")
        sleep(seconds: 60)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(waitForLabel(registryCount, equalTo: "Entities: 0", timeout: 2))
    }

    private func completeWarmup(
        start: XCUIElement,
        run: XCUIElement,
        clear: XCUIElement,
        result: XCUIElement,
        registryCount: XCUIElement
    ) {
        for attempt in 1...6 {
            start.tap()
            run.tap()
            if waitForLabel(result, equalTo: "Demo arc complete", timeout: 5) {
                clear.tap()
                XCTAssertTrue(waitForLabel(registryCount, equalTo: "Entities: 0", timeout: 5))
                return
            }
            clear.tap()
            emit("AR3_AUTOMATION_WARMUP_RETRY=\(attempt)")
            sleep(seconds: 2)
        }
        XCTFail("AR Lab could not complete a warm-up arc")
    }

    private func completeMeasuredCycle(
        _ cycle: Int,
        start: XCUIElement,
        run: XCUIElement,
        clear: XCUIElement,
        result: XCUIElement,
        registryCount: XCUIElement
    ) {
        emit("AR3_AUTOMATION_CYCLE_\(cycle)_START")
        start.tap()
        run.tap()
        XCTAssertTrue(
            waitForLabel(result, equalTo: "Demo arc complete", timeout: 8),
            "Measured cycle \(cycle) did not complete"
        )
        clear.tap()
        XCTAssertTrue(
            waitForLabel(registryCount, equalTo: "Entities: 0", timeout: 5),
            "Measured cycle \(cycle) did not clean up"
        )
        emit("AR3_AUTOMATION_CYCLE_\(cycle)_PASS")
    }

    private func waitForLabel(_ element: XCUIElement, equalTo expected: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expected)
        return XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: element)],
            timeout: timeout
        ) == .completed
    }

    private func sleep(seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func emit(_ marker: String) {
        FileHandle.standardOutput.write(Data("\(marker)\n".utf8))
    }
}
