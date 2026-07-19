import Foundation
import RealityKit
import WaykinCore
@testable import WaykinApp

// Issue #46 test-support fixture: deterministic replay of canonical session
// traces through the production CanonicalARSessionRuntime. No wall-clock
// sleeps anywhere — command flow is driven by explicit receive() calls and
// the runtime's own synchronous drain.

/// One deterministic step of a canonical session trace.
enum ReplayStep: Equatable {
    /// Project a fresh spawn of the companion in its current runtime state.
    case spawn
    /// Apply a canonical world event to the companion runtime, then project
    /// the resulting update (event overlays included).
    case event(WorldEventKind, intensity: Double)
    /// Set a canonical behavior directly, then project an event-free update.
    case behavior(CompanionBehaviorState)
    /// Project a late-attach snapshot for the given pursuit state.
    case snapshot(PursuitState, WorldEventKind?)
    /// Canonical clear (session end).
    case clear
    /// Pump the drain without new commands (a scene-update stand-in).
    case drain
    /// Tear down the current host view.
    case detach
    /// Attach a brand-new host view.
    case reattach
}

struct ReplayTrace {
    let name: String
    let steps: [ReplayStep]
}

/// Everything one replay run observed, comparable across runs.
struct ReplayRunRecord: Equatable {
    let traceName: String
    let renderedCommands: [ARWorldCommand]
    let finalPending: [ARWorldCommand]
    let finalCompanionState: CompanionPresentationState
    let maxPendingObserved: Int
}

/// Exit-criteria artifact: the deterministic replay receipt.
struct ReplaySoakReceipt: Codable, Equatable {
    let traceName: String
    let iterations: Int
    let renderedCommandCount: Int
    let maxPendingObserved: Int
    let deterministic: Bool
}

@MainActor
final class ReplayCommandSourceStub: CanonicalARCommandSource {
    private(set) var handlers: [UUID: ([ARWorldCommand]) -> Void] = [:]
    var activeHandlerCount: Int { handlers.count }

    func attachARWorldCommandHandler(_ handler: @escaping ([ARWorldCommand]) -> Void) -> UUID {
        let owner = UUID()
        handlers[owner] = handler
        return owner
    }

    func detachARWorldCommandHandler(owner: UUID) {
        handlers.removeValue(forKey: owner)
    }
}

/// Drives the production host through traces while recording every command
/// the renderer sees. The render policy is injectable so deferral pressure
/// is explicit and deterministic, never raycast- or camera-dependent.
@MainActor
final class ARCommandReplayHarness {
    let source = ReplayCommandSourceStub()
    let mapper: CanonicalARWorldCommandMapper
    let runtime: CanonicalARSessionRuntime

    private(set) var renderedCommands: [ARWorldCommand] = []
    private(set) var maxPendingObserved = 0
    private(set) var currentView: ARView?
    private var companionRuntime = CompanionRuntime()

    /// Render policy. Defaults to accepting everything.
    var policy: (ARWorldCommand) -> ARCommandResult = { _ in .accepted("replay") }

    init(companionID: UUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!) {
        mapper = CanonicalARWorldCommandMapper(companionID: companionID, companionName: "Lira")
        var record: ((ARWorldCommand) -> ARCommandResult)?
        runtime = CanonicalARSessionRuntime { command, _ in
            record?(command) ?? .accepted("replay")
        }
        record = { [weak self] command in
            guard let self else { return .accepted("replay") }
            self.renderedCommands.append(command)
            return self.policy(command)
        }
    }

    func attachFreshView() {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        runtime.attach(view, appModel: source)
        currentView = view
    }

    func detachCurrentView() {
        guard let view = currentView else { return }
        runtime.detach(view, appModel: source)
        currentView = nil
    }

    /// Commands rendered after a given index (for segment assertions).
    func renderedCommands(after index: Int) -> [ARWorldCommand] {
        Array(renderedCommands.dropFirst(index))
    }

    private func makeEvent(_ kind: WorldEventKind, intensity: Double) -> WorldEvent {
        WorldEvent(kind: kind,
                   occurredAt: Date(timeIntervalSince1970: 1_800_000_000),
                   intensity: intensity,
                   debugLabel: kind.rawValue)
    }

    private func trackPending() {
        maxPendingObserved = max(maxPendingObserved, runtime.pendingCommandSnapshot.count)
    }

    func perform(_ step: ReplayStep) {
        switch step {
        case .spawn:
            runtime.receive(mapper.spawn(companionRuntime: companionRuntime))
        case .event(let kind, let intensity):
            let event = makeEvent(kind, intensity: intensity)
            companionRuntime.apply(event: event)
            runtime.receive(mapper.update(companionRuntime: companionRuntime, event: event))
        case .behavior(let state):
            companionRuntime.apply(command: .setBehavior(state.rawValue))
            runtime.receive(mapper.update(companionRuntime: companionRuntime, event: nil))
        case .snapshot(let pursuit, let kind):
            let event = kind.map { makeEvent($0, intensity: 0.6) }
            runtime.receive(mapper.snapshot(companionRuntime: companionRuntime,
                                            pursuitState: pursuit,
                                            lastEvent: event))
        case .clear:
            runtime.receive(mapper.clear())
        case .drain:
            runtime.receive([])
        case .detach:
            detachCurrentView()
        case .reattach:
            attachFreshView()
        }
        trackPending()
    }

    @discardableResult
    func run(_ trace: ReplayTrace, attachFirst: Bool = true) -> ReplayRunRecord {
        if attachFirst { attachFreshView() }
        for step in trace.steps {
            perform(step)
        }
        return ReplayRunRecord(
            traceName: trace.name,
            renderedCommands: renderedCommands,
            finalPending: runtime.pendingCommandSnapshot,
            finalCompanionState: runtime.companionState,
            maxPendingObserved: maxPendingObserved
        )
    }
}

enum ReplayTraces {
    /// Full canonical arc: spawn, discovery, pursuit rise and release, bond,
    /// clear — the Issue #42 invariants end to end.
    static let companionDiscoveryPursuit = ReplayTrace(
        name: "companion-discovery-pursuit",
        steps: [
            .spawn,
            .behavior(.follow),
            .event(.distantPresence, intensity: 0.3),
            .event(.pursuitBegins, intensity: 0.5),
            .event(.pursuitIntensifies, intensity: 0.8),
            .event(.pursuitFades, intensity: 0.2),
            .event(.bondMoment, intensity: 0.6),
            .behavior(.rest),
            .clear,
        ]
    )

    /// Host lifecycle arc: live updates, detach mid-session, reattach, and a
    /// late snapshot restore — then clear.
    static let detachReattachRestore = ReplayTrace(
        name: "detach-reattach-restore",
        steps: [
            .spawn,
            .event(.pursuitBegins, intensity: 0.5),
            .detach,
            .reattach,
            .drain,
            .snapshot(.approaching, .pursuitBegins),
            .event(.pursuitFades, intensity: 0.2),
            .clear,
        ]
    )
}
