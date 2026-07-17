import XCTest
@testable import WaykinCore

@MainActor
final class DemoAndPhysicsTests: XCTestCase {
    func testDemoControllerCompletesScenarios() async throws {
        let movement = MovementEngine()
        let controller = DemoSessionController(movementEngine: movement)

        for scenario in controller.availableScenarios() {
            try controller.start(scenarioID: scenario.id)
            controller.runToEnd()
            let (_, result, summary) = controller.end()

            XCTAssertNotNil(result)
            XCTAssertNotNil(summary)
            XCTAssertEqual(summary?.outcome, scenario.expectedOutcome, "Scenario \(scenario.id) failed")
        }
    }

    func testDemoModeOnlyOffersCanonicalCompanionWalk() {
        let movement = MovementEngine()
        let controller = DemoSessionController(movementEngine: movement)

        let scenarios = controller.availableScenarios()
        XCTAssertEqual(scenarios.map(\.id), [.calmDayWalk])
        XCTAssertEqual(scenarios.map(\.experienceID), ["companion_walk"])
    }
}
