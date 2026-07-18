import ARKit
import AVFoundation
import WaykinCore

struct ARCapabilityMonitor {
    private let currentStateProvider: () -> ARCapabilityState
    private let requestCameraAccessProvider: () async -> ARCapabilityState

    init(
        currentState: @escaping () -> ARCapabilityState = {
            Self.resolve(
                isWorldTrackingSupported: ARWorldTrackingConfiguration.isSupported,
                cameraAuthorizationStatus: AVCaptureDevice.authorizationStatus(for: .video)
            )
        },
        requestCameraAccess: @escaping () async -> ARCapabilityState = {
            await Self.requestSystemCameraAccess()
        }
    ) {
        currentStateProvider = currentState
        requestCameraAccessProvider = requestCameraAccess
    }

    func currentState() -> ARCapabilityState {
        currentStateProvider()
    }

    func requestCameraAccess() async -> ARCapabilityState {
        await requestCameraAccessProvider()
    }

    private static func requestSystemCameraAccess() async -> ARCapabilityState {
        guard ARWorldTrackingConfiguration.isSupported else { return .unsupported }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .available
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .available : .cameraDenied
        case .denied, .restricted:
            return .cameraDenied
        @unknown default:
            return .cameraDenied
        }
    }

    static func resolve(
        isWorldTrackingSupported: Bool,
        cameraAuthorizationStatus: AVAuthorizationStatus
    ) -> ARCapabilityState {
        guard isWorldTrackingSupported else { return .unsupported }

        switch cameraAuthorizationStatus {
        case .authorized:
            return .available
        case .notDetermined:
            return .checking
        case .denied, .restricted:
            return .cameraDenied
        @unknown default:
            return .cameraDenied
        }
    }
}
