import Combine
import Observation
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
protocol CanonicalARCommandSource: AnyObject {
    func attachARWorldCommandHandler(_ handler: @escaping ([ARWorldCommand]) -> Void) -> UUID
    func detachARWorldCommandHandler(owner: UUID)
    /// Privacy-safe AR presentation snapshot for field-test receipts (D1).
    func ingestARPresentationDiagnostics(_ summary: FieldTestARPresentationSummary)
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
    @ObservationIgnored private var continuityElapsed: TimeInterval = 0
    /// How often the frame loop verifies the companion survived tracking loss.
    private static let continuityCheckInterval: TimeInterval = 1.0
    private weak var arView: ARView?

    private(set) var capabilityState: ARCapabilityState = .checking
    private(set) var companionState: CompanionPresentationState = .idle
    private(set) var lastResult = "Waiting for AR session"
    private(set) var companionLODDescription = "procedural_living_familiar_mid"
    /// #125: placement continuity note (ok_present / planted_* / replant_*).
    private(set) var companionContinuityNote = "none"
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

    /// Lead vs follow, chosen when the walk is started.
    func setEscortMode(_ mode: LiraEscortMode) {
        renderer.escortMode = mode
    }

    func setCompanionSkin(_ skin: LiraSkin) {
        // Re-applies materials to live companion when planted.
        renderer.companionSkin = skin
    }

    /// Sync Reduce Motion from UI (call on appear / onChange).
    func setReduceMotion(_ enabled: Bool) {
        renderer.reduceMotionEnabled = enabled
    }

    var motionDiagnosticsLine: String { renderer.motionDiagnosticsLine }
    /// "walk clip running?" — the puppet-player fields cannot answer this.
    var authoredAnimationNote: String {
        renderer.authoredAnimationNote
    }
    var isSkeletalDriving: Bool { renderer.isSkeletalDriving }
    var activeSkeletalClipName: String { renderer.activeSkeletalClip?.rawValue ?? "none" }

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
            self?.advanceFollow(by: event.deltaTime)
            self?.maintainContinuity(by: event.deltaTime)
            self?.advancePresentation(by: event.deltaTime)
        }
        sessionCoordinator.onCapabilityStateChange = { [weak self] state in
            self?.capabilityState = state
        }
        commandHandlerOwner = appModel.attachARWorldCommandHandler { [weak self] commands in
            self?.receive(commands)
        }
        // Start the camera first. The packaged companion is an 18MB rigged USDZ, and
        // parsing it ahead of session start left the AR view black for seconds while the
        // walker waited on a feed that had not been asked for yet.
        sessionStartTask = Task { [weak self] in
            await self?.sessionCoordinator.start()
        }
        // Then preload the companion at lower priority; placement defers until it lands.
        usdzPreloadTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.assetLoader.preloadFromBundle()
            self.companionLODDescription = self.assetLoader.activeLODDescription
        }
    }

    func detach(_ arView: ARView, appModel: any CanonicalARCommandSource) {
        guard self.arView === arView else { return }
        publishPresentationDiagnostics(to: appModel)
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

    /// Push privacy-safe AR labels + counts into the walk receipt path.
    func publishPresentationDiagnostics(to appModel: any CanonicalARCommandSource) {
        let counts = diagnostics.fieldTestPresentationSummary
        let summary = FieldTestARPresentationSummary(
            arSessionOpened: true,
            finalLODDescription: companionLODDescription,
            meshEvidenceClass: LiraARAssetCatalog.packagedEvidenceClass,
            finalContinuityNote: companionContinuityNote,
            finalCapabilityState: capabilityState.rawValue,
            motionDiagnosticsLine: motionDiagnosticsLine,
            placementDeferredCount: counts.placementDeferredCount,
            continuityReplantCount: counts.continuityReplantCount,
            entityReplacementCount: counts.entityReplacementCount,
            companionPlaced: counts.companionPlaced
        )
        appModel.ingestARPresentationDiagnostics(summary)
        WaykinLog.ar.info(
            "snapshot lod=\(self.companionLODDescription, privacy: .public) continuity=\(self.companionContinuityNote, privacy: .public) cap=\(self.capabilityState.rawValue, privacy: .public)"
        )
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
                companionContinuityNote = renderer.companionContinuityNote
                companionLODDescription = assetLoader.activeLODDescription
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

    /// Walk the companion toward the walker each frame, so she covers ground instead of
    /// snapping into place. Needs the live camera transform, which only the view owns.
    private func advanceFollow(by delta: TimeInterval) {
        guard let arView else { return }
        renderer.advanceCompanionFollow(by: delta, cameraTransform: arView.cameraTransform)
    }

    /// Throttled frame-driven continuity so Lira recovers from a dropped world anchor
    /// within ~1s, instead of vanishing until the next game `updateCompanion` command.
    /// No-ops until a companion has actually been spawned (renderer guards that).
    private func maintainContinuity(by delta: TimeInterval) {
        guard let arView, delta.isFinite, delta >= 0 else { return }
        continuityElapsed += delta
        guard continuityElapsed >= Self.continuityCheckInterval else { return }
        continuityElapsed = 0
        renderer.maintainCompanionContinuity(in: arView)
        companionContinuityNote = renderer.companionContinuityNote
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
    var escortMode: LiraEscortMode = .follow
    /// Mirrored walk controls (#126) so Pause/End stay reachable without leaving AR.
    var isPaused: Bool = false
    var onPause: (() -> Void)?
    var onResume: (() -> Void)?
    var onEnd: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wkTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var runtime = CanonicalARSessionRuntime()

    var body: some View {
        ZStack {
            CanonicalARCameraView(runtime: runtime, appModel: appModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Developer diagnostics HUD — hidden in normal sessions, shown for
                    // operators (-WAYKIN_OPERATOR_DEBUG) and UI tests (-WAYKIN_UI_TESTING).
                    if ARDiagnosticsHUDFeature.isEnabled {
                        // Compact by design: this sits over the live camera during field
                        // walks, so it stays three short lines. Full detail still reaches
                        // the walk receipt via ingestARPresentationDiagnostics.
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(runtime.capabilityState.rawValue) · \(runtime.companionState.rawValue) · \(runtime.authoredAnimationNote)")
                                .accessibilityIdentifier("waykin.ar.canonical.anim")
                            Text(runtime.companionLODDescription)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .accessibilityIdentifier("waykin.ar.canonical.lod")
                            Text(runtime.companionContinuityNote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .accessibilityIdentifier("waykin.ar.canonical.continuity")
                        }
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(arStatusAccessibilityLabel)
                        .accessibilityIdentifier("waykin.ar.canonical.status")
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close AR companion")
                    .accessibilityIdentifier("waykin.ar.canonical.close")
                }
                .padding(12)
                .background(.ultraThinMaterial)

                Spacer()

                // Bottom mirrored session controls (#126).
                if onPause != nil || onResume != nil || onEnd != nil {
                    HStack(spacing: 12) {
                        if isPaused {
                            Button {
                                onResume?()
                            } label: {
                                WKIconLabel(title: "Resume", icon: .resume)
                                    .frame(minWidth: 48, minHeight: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.guide)
                            .accessibilityLabel("Resume walk")
                            .accessibilityIdentifier("waykin.ar.session.resume")
                        } else {
                            Button {
                                onPause?()
                            } label: {
                                WKIconLabel(title: "Pause", icon: .pause)
                                    .frame(minWidth: 48, minHeight: 48)
                            }
                            .buttonStyle(.bordered)
                            .tint(theme.pause)
                            .accessibilityLabel("Pause walk")
                            .accessibilityIdentifier("waykin.ar.session.pause")
                        }

                        Button {
                            onEnd?()
                        } label: {
                            WKIconLabel(title: "End", icon: .stop)
                                .frame(minWidth: 48, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.textSecondary)
                        .accessibilityLabel("End walk")
                        .accessibilityIdentifier("waykin.ar.session.end")
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .accessibilityIdentifier("waykin.ar.session.controls")
                }
            }
        }
        .onAppear {
            runtime.setEscortMode(escortMode)
            runtime.setCompanionSkin(liraSkin)
            runtime.setReduceMotion(reduceMotion)
        }
        .onChange(of: liraSkin) { _, newSkin in
            runtime.setCompanionSkin(newSkin)
        }
        .onChange(of: escortMode) { _, newMode in
            runtime.setEscortMode(newMode)
        }
        .onChange(of: reduceMotion) { _, enabled in
            runtime.setReduceMotion(enabled)
        }
        .onDisappear {
            runtime.publishPresentationDiagnostics(to: appModel)
        }
    }

    private var arStatusAccessibilityLabel: String {
        var parts = [
            "AR: \(runtime.capabilityState.rawValue)",
            "Lira: \(runtime.companionState.rawValue)",
            "Form: \(liraSkin.displayName)",
            "LOD: \(runtime.companionLODDescription)",
            "mesh \(LiraARAssetCatalog.packagedEvidenceClass)",
            "Motion: \(runtime.motionDiagnosticsLine)",
            "Continuity: \(runtime.companionContinuityNote)"
        ]
        if let hint = ARContinuityHint.message(from: runtime.companionContinuityNote) {
            parts.append(hint)
        }
        return parts.joined(separator: ", ")
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
