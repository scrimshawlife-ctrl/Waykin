import ARKit
import WaykinCore

@MainActor
final class ARSessionCoordinator: NSObject {
    let session: ARSession
    private let capabilityMonitor: ARCapabilityMonitor

    private(set) var capabilityState: ARCapabilityState = .checking {
        didSet {
            guard oldValue != capabilityState else { return }
            onCapabilityStateChange?(capabilityState)
        }
    }

    var onCapabilityStateChange: ((ARCapabilityState) -> Void)?

    init(
        session: ARSession = ARSession(),
        capabilityMonitor: ARCapabilityMonitor = ARCapabilityMonitor()
    ) {
        self.session = session
        self.capabilityMonitor = capabilityMonitor
        super.init()
        session.delegate = self
        capabilityState = capabilityMonitor.currentState()
    }

    func start(resetTracking: Bool = false) async {
        let authorizationState = await capabilityMonitor.requestCameraAccess()
        guard !Task.isCancelled else { return }
        guard authorizationState == .available else {
            capabilityState = authorizationState
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        var options: ARSession.RunOptions = []
        if resetTracking {
            options.formUnion([.resetTracking, .removeExistingAnchors])
        }

        session.run(configuration, options: options)
        capabilityState = .active
    }

    func pause() {
        session.pause()
        if capabilityState == .active || capabilityState == .trackingLimited {
            capabilityState = .available
        }
    }

    func stopAndReset() {
        session.pause()
        capabilityState = capabilityMonitor.currentState()
    }
}

extension ARSessionCoordinator: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.capabilityState = .trackingLimited
        }
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor [weak self] in
            self?.capabilityState = .trackingLimited
        }
    }

    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.start(resetTracking: true)
        }
    }

    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let nextState: ARCapabilityState
        switch camera.trackingState {
        case .normal:
            nextState = .active
        case .notAvailable, .limited:
            nextState = .trackingLimited
        }

        Task { @MainActor [weak self] in
            self?.capabilityState = nextState
        }
    }
}
