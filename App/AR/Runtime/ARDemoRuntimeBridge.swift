import Foundation
import WaykinCore

struct ARDemoFrame {
    let tickIndex: Int
    let totalTicks: Int
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
    private(set) var hasSpawnedThreat = false
    private var pendingFrame: ARDemoFrame?

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
        hasSpawnedThreat = false
        let frame = makeFrame(event: nil)
        pendingFrame = frame
        return frame
    }

    func advance() -> ARDemoFrame? {
        guard controller.isRunning else { return nil }
        if pendingFrame != nil {
            let frame = makeFrame(event: controller.currentEvent)
            pendingFrame = frame
            return frame
        }
        let priorTick = controller.tickIndex
        controller.advanceOneTick()
        let frame = makeFrame(event: controller.currentEvent)
        if controller.tickIndex != priorTick {
            pendingFrame = frame
        }
        return frame
    }

    func acknowledgeRenderedFrame() {
        guard let frame = pendingFrame else { return }
        pendingFrame = nil
        if frame.isComplete {
            _ = controller.end()
        }
    }

    func reset() {
        if controller.isRunning {
            _ = controller.end()
        }
        controller = DemoSessionController(movementEngine: movementEngine)
        hasSpawnedCompanion = false
        hasSpawnedThreat = false
        pendingFrame = nil
    }

    func markCompanionPlaced() { hasSpawnedCompanion = true }
    func markCompanionMissing() { hasSpawnedCompanion = false }
    func markThreatPlaced() { hasSpawnedThreat = true }
    func markThreatMissing() { hasSpawnedThreat = false }

    private func makeFrame(event: WorldEvent?) -> ARDemoFrame {
        let runtime = controller.companionRuntime
        let companionCommand = adapter.companionCommand(
            runtime: runtime,
            event: event,
            replacingExisting: hasSpawnedCompanion
        )
        let commands = [companionCommand] + adapter.eventCommands(
            for: event,
            threatExists: hasSpawnedThreat
        )
        return ARDemoFrame(
            tickIndex: controller.tickIndex,
            totalTicks: controller.currentScenario?.ticks.count ?? 0,
            eventKind: event?.kind,
            companionState: adapter.presentationState(runtime: runtime, event: event),
            relativeDistance: runtime.relativeDistance,
            commands: commands,
            isComplete: controller.tickIndex >= totalTicks && totalTicks > 0
        )
    }
}
