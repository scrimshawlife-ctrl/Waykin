import Foundation
import WaykinCore

struct ARDemoFrame {
    let tickIndex: Int
    let eventKind: WorldEventKind?
    let companionState: CompanionPresentationState
    let relativeDistance: Double
    let commands: [ARWorldCommand]
    let isComplete: Bool
}

@MainActor
final class ARDemoRuntimeBridge {
    private let movementEngine: MovementEngine
    private let adapter: ARCompanionRuntimeAdapter
    private(set) var controller: DemoSessionController
    private(set) var hasSpawnedCompanion = false

    init(
        movementEngine: MovementEngine = MovementEngine(),
        adapter: ARCompanionRuntimeAdapter = ARCompanionRuntimeAdapter()
    ) {
        self.movementEngine = movementEngine
        self.adapter = adapter
        self.controller = DemoSessionController(movementEngine: movementEngine)
    }

    var isRunning: Bool { controller.isRunning }
    var tickIndex: Int { controller.tickIndex }
    var totalTicks: Int { controller.currentScenario?.ticks.count ?? 0 }

    func start() throws -> ARDemoFrame {
        if controller.isRunning {
            _ = controller.end()
        }
        try controller.start(scenarioID: .calmDayWalk)
        hasSpawnedCompanion = false
        return makeFrame(event: nil)
    }

    func advance() -> ARDemoFrame? {
        guard controller.isRunning else { return nil }
        let priorTick = controller.tickIndex
        controller.advanceOneTick()
        guard controller.tickIndex != priorTick else { return makeFrame(event: controller.currentEvent) }
        return makeFrame(event: controller.currentEvent)
    }

    func runRemaining() -> [ARDemoFrame] {
        var frames: [ARDemoFrame] = []
        while controller.isRunning, controller.tickIndex < totalTicks {
            guard let frame = advance() else { break }
            frames.append(frame)
        }
        return frames
    }

    func reset() {
        if controller.isRunning {
            _ = controller.end()
        }
        controller = DemoSessionController(movementEngine: movementEngine)
        hasSpawnedCompanion = false
    }

    private func makeFrame(event: WorldEvent?) -> ARDemoFrame {
        let runtime = controller.companionRuntime
        let companionCommand = adapter.companionCommand(
            runtime: runtime,
            event: event,
            replacingExisting: hasSpawnedCompanion
        )
        hasSpawnedCompanion = true

        let commands = [companionCommand] + adapter.eventCommands(for: event)
        return ARDemoFrame(
            tickIndex: controller.tickIndex,
            eventKind: event?.kind,
            companionState: adapter.presentationState(runtime: runtime, event: event),
            relativeDistance: runtime.relativeDistance,
            commands: commands,
            isComplete: controller.tickIndex >= totalTicks && totalTicks > 0
        )
    }
}
