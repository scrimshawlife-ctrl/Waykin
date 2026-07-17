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
        XCTAssertFalse(scenarios.map(\.experienceID).contains("wandering-paths"))
        XCTAssertFalse(scenarios.map(\.experienceID).contains("orc_pursuit"))
        XCTAssertFalse(scenarios.map(\.experienceID).contains("future_self"))
    }

    @MainActor
    func testDemoExposesCanonicalWalkStateForPresentation() throws {
        let controller = DemoSessionController(movementEngine: MovementEngine())
        try controller.start(scenarioID: .calmDayWalk)

        XCTAssertNotNil(controller.companionWalkState)
        XCTAssertEqual(controller.companionWalkState?.pursuitState, .inactive)
        controller.advanceOneTick()
        XCTAssertNotNil(controller.companionWalkState?.worldState)
    }

    func testDemoRunsOneOrderedArcAndWritesSpecificMemory() throws {
        let controller = DemoSessionController(movementEngine: MovementEngine())
        try controller.start(scenarioID: .calmDayWalk)
        var eventKinds: [WorldEventKind] = []

        while controller.isRunning,
              let scenario = controller.currentScenario,
              controller.tickIndex < scenario.ticks.count {
            controller.advanceOneTick()
            if let event = controller.currentEvent {
                eventKinds.append(event.kind)
            }
        }

        XCTAssertEqual(eventKinds, [
            .companionObserves,
            .companionDrawsNear,
            .distantPresence,
            .pursuitBegins,
            .pursuitIntensifies,
            .pursuitFades,
            .bondMoment
        ])
        let (_, _, summary) = controller.end()
        XCTAssertEqual(
            summary?.memory.text,
            "Lira watched the path, drew close when a distant presence appeared, and stayed beside you until it faded."
        )
    }

    func testPauseResumeDoesNotDuplicateDemoArc() throws {
        let controller = DemoSessionController(movementEngine: MovementEngine())
        try controller.start(scenarioID: .calmDayWalk)
        controller.advanceOneTick()
        let eventCountBeforePause = controller.companionWalkState?.eventHistory.count

        controller.pause()
        controller.advanceOneTick()
        controller.advanceOneTick()
        XCTAssertEqual(controller.companionWalkState?.eventHistory.count, eventCountBeforePause)

        controller.resume()
        controller.runToEnd()
        XCTAssertEqual(controller.companionWalkState?.eventHistory.count, 7)
        XCTAssertEqual(Set(controller.companionWalkState?.eventHistory.map(\.kind) ?? []).count, 7)
    }
}
