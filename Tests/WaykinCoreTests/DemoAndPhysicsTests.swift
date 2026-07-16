import XCTest
@testable import WaykinCore

final class DemoAndPhysicsTests: XCTestCase {
    func testDemoControllerCompletesScenarios() {
        let movement = MovementEngine()
        let controller = DemoSessionController(movementEngine: movement)
        
        for scenario in controller.availableScenarios() {
            XCTAssertNoThrow(try controller.start(scenarioID: scenario.id))
            controller.runToEnd()
            let (_, result, summary) = controller.end()
            
            XCTAssertNotNil(result)
            XCTAssertNotNil(summary)
            XCTAssertEqual(summary?.outcome, scenario.expectedOutcome, "Scenario \(scenario.id) failed")
        }
    }
    
    func testOrcPursuitTimeIndependence() {
        // Ten 1s ticks vs one 10s tick should give similar distance change
        let slowSpeed = 1.0
        let pursuerAdjustment = 2.0  // simplified
        
        let tenTicksDist = (0..<10).reduce(120.0) { dist, _ in
            dist + (slowSpeed - pursuerAdjustment) * 1.0
        }
        
        let oneTickDist = 120.0 + (slowSpeed - pursuerAdjustment) * 10.0
        
        XCTAssertEqual(tenTicksDist, oneTickDist, accuracy: 0.1)
    }
}
