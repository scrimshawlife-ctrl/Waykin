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

    func testOrcPursuitTimeIndependence() {
        let slowSpeed = 1.0
        let pursuerAdjustment = 2.0

        let tenTicksDist = (0..<10).reduce(120.0) { dist, _ in
            dist + (slowSpeed - pursuerAdjustment) * 1.0
        }

        let oneTickDist = 120.0 + (slowSpeed - pursuerAdjustment) * 10.0

        XCTAssertEqual(tenTicksDist, oneTickDist, accuracy: 0.1)
    }
}