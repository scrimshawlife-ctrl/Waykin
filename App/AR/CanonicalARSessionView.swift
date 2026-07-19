import Combine
import Observation
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
protocol CanonicalARCommandSource: AnyObject {
    func attachARWorldCommandHandler(_ handler: @escaping ([ARWorldCommand]) -> Void) -> UUID
    func detachARWorldCommandHandler(owner: UUID)
}

@MainActor
@Observable
final class CanonicalARSessionRuntime {
    private let registry: AREntityRegistry
    private let diagnostics: ARDiagnosticRecorder
    private let sessionCoordinator: ARSessionCoordinator
    private let assetLoader: LiraARAssetLoader
    private let renderer: ARWorldCommandRenderer
    @ObservationIgnored private var renderCommandOverride: ((ARWorldCommand, ARView) -> ARCommandResult)?
    @ObservationIgnored private var sceneUpdateSubscription: Cancellable?
    @ObservationIgnored private var sessionStartTask: Task<Void, Never>?
    @ObservationIgnored private var usdzPreloadTask: Task<Void, Never>?
    @ObservationIgnored private var pendingCommands: [ARWorldCommand] = []
    @ObservationIgnored private var commandHandlerOwner: UUID?
    private weak var arView: ARView?

    private(set) var capabilityState: ARCapabilityState = .checking
    private(set) var companionState: CompanionPresentationState = .idle
    private(set) var lastResult = "Waiting for AR session"
    private(set) var companionLODDescription = "procedural_living_familiar_mid"
    var pendingCommandSnapshot: [ARWorldCommand] { pendingCommands }

    init(renderCommand: ((ARWorldCommand, ARView) -> ARCommandResult)? = nil) {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let assetLoader = LiraARAssetLoader()
        self.registry = registry
        self.diagnostics = diagnostics
        self.sessionCoordinator = ARSessionCoordinator()
        self.assetLoader = assetLoader
        self.renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: diagnostics,
            assetLoader: assetLoader
        )
        self.renderCommandOverride = renderCommand
    }

    func setCompanionSkin(_ skin: LiraSkin) {
        renderer.companionSkin = skin
    }

    func attach(_ arView: ARView, appModel: any CanonicalARCommandSource) {
        if let currentView = self.arView, currentView !== arView {
            detach(currentView, appModel: appModel)
        }
        sceneUpdateSubscription?.cancel()
        sessionStartTask?.cancel()
        usdzPreloadTask?.cancel()
        self.arView = arView
        arView.session = sessionCoordinator.session
        sceneUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.drainPendingCommands()
            self?.advancePresentation(by: event.deltaTime)
        }
        sessionCoordinator.onCapabilityStateChange = { [weak self] state in
            self?.capabilityState = state
        }
        commandHandlerOwner = appModel.attachARWorldCommandHandler { [weak self] commands in
            self?.receive(commands)
        }
        // Preload optional artist USDZ before / while AR session starts.
        usdzPreloadTask = Task { [weak self] in
            guard let self else { return }
            await self.assetLoader.preloadFromBundle()
            self.companionLODDescription = self.assetLoader.activeLODDescription
        }
        sessionStartTask = Task { [weak self] in
            await self?.sessionCoordinator.start()
        }
    }

    func detach(_ arView: ARView, appModel: any CanonicalARCommandSource) {
        guard self.arView === arView else { return }
        if let commandHandlerOwner {
            appModel.detachARWorldCommandHandler(owner: commandHandlerOwner)
            self.commandHandlerOwner = nil
        }
        pendingCommands.removeAll(keepingCapacity: true)
        report(render(.clearSession, in: arView))
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = nil
        sessionStartTask?.cancel()
        sessionStartTask = nil
        usdzPreloadTask?.cancel()
        usdzPreloadTask = nil
        sessionCoordinator.pause()
        companionState = .idle
        self.arView = nil
    }

    func receive(_ commands: [ARWorldCommand]) {
        guard let arView else { return }
        if commands.contains(.clearSession) {
            pendingCommands.removeAll(keepingCapacity: true)
            report(render(.clearSession, in: arView))
            companionState = .idle
            return
        }

        for command in commands {
            enqueue(command)
        }
        drainPendingCommands()
    }

    private func enqueue(_ command: ARWorldCommand) {
        if let key = pendingKey(for: command),
           let existing = pendingCommands.firstIndex(where: { pendingKey(for: $0) == key }) {
            pendingCommands.remove(at: existing)
        }
        pendingCommands.append(command)
    }

    private func pendingKey(for command: ARWorldCommand) -> PendingCommandKey? {
        switch command {
        case .spawnCompanion:
            return .companionSpawn
        case .updateCompanion:
            return .companionUpdate
        case .spawnDiscovery(let presentation):
            return .entity(presentation.id)
        case .spawnThreat(let presentation), .updateThreat(let presentation):
            return .entity(presentation.id)
        case .removeEntity(let id):
            return .entity(id)
        case .clearSession:
            return nil
        }
    }

    private func drainPendingCommands() {
        guard let arView else { return }
        var index = pendingCommands.startIndex
        while index < pendingCommands.endIndex {
            let command = pendingCommands[index]
            let result = render(command, in: arView)
            report(result)
            guard case .deferred = result else {
                pendingCommands.remove(at: index)
                companionState = renderer.companionState
                continue
            }

            // Initial attachment keeps Lira first. Once that invariant is
            // established, one deferred entity must not stall independent
            // companion or cleanup projections behind it.
            if case .spawnCompanion = command {
                return
            }
            index = pendingCommands.index(after: index)
        }
    }

    private func advancePresentation(by delta: TimeInterval) {
        // A2 local loops every frame; celebrate state machine remains separate.
        renderer.advanceLocalMotion(by: delta)
        guard let transition = renderer.advanceCompanionPresentation(by: delta) else { return }
        companionState = transition.resolvedState
    }

    private func render(_ command: ARWorldCommand, in arView: ARView) -> ARCommandResult {
        renderCommandOverride?(command, arView) ?? renderer.render(command, in: arView)
    }

    private func report(_ result: ARCommandResult) {
        switch result {
        case .accepted(let detail): lastResult = "Accepted: \(detail)"
        case .deferred(let detail): lastResult = "Deferred: \(detail)"
        case .removed(let detail): lastResult = "Removed: \(detail)"
        case .cleared: lastResult = "Session cleared"
        }
    }

    private enum PendingCommandKey: Equatable {
        case companionSpawn
        case companionUpdate
        case entity(UUID)
    }
}

@MainActor
struct CanonicalARSessionView: View {
    let appModel: any CanonicalARCommandSource
    var liraSkin: LiraSkin = .dawn
    @Environment(\.dismiss) private var dismiss
    @State private var runtime = CanonicalARSessionRuntime()

    var body: some View {
        ZStack(alignment: .top) {
            CanonicalARCameraView(runtime: runtime, appModel: appModel)
                .ignoresSafeArea()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AR: \(runtime.capabilityState.rawValue)")
                    Text("Lira: \(runtime.companionState.rawValue)")
                    Text("Form: \(liraSkin.displayName)")
                    Text("LOD: \(runtime.companionLODDescription)")
                        .accessibilityIdentifier("waykin.ar.canonical.lod")
                    Text(runtime.lastResult)
                }
                .font(.caption.weight(.semibold))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "AR: \(runtime.capabilityState.rawValue), Lira: \(runtime.companionState.rawValue), Form: \(liraSkin.displayName), LOD: \(runtime.companionLODDescription)"
                )
                .accessibilityIdentifier("waykin.ar.canonical.status")

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close AR companion")
            }
            .padding(12)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            runtime.setCompanionSkin(liraSkin)
        }
        .onChange(of: liraSkin) { _, newSkin in
            runtime.setCompanionSkin(newSkin)
        }
    }
}

@MainActor
private struct CanonicalARCameraView: UIViewRepresentable {
    let runtime: CanonicalARSessionRuntime
    let appModel: any CanonicalARCommandSource

    final class Coordinator {
        let runtime: CanonicalARSessionRuntime
        let appModel: any CanonicalARCommandSource

        init(runtime: CanonicalARSessionRuntime, appModel: any CanonicalARCommandSource) {
            self.runtime = runtime
            self.appModel = appModel
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(runtime: runtime, appModel: appModel)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        runtime.attach(view, appModel: appModel)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.runtime.detach(uiView, appModel: coordinator.appModel)
    }
}
