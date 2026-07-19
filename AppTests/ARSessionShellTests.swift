import ARKit
import AVFoundation
import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class ARSessionShellTests: XCTestCase {
    func testCancelledStartDoesNotRequestAuthorizationOrRunSession() async {
        let probe = ARSessionStartProbe(authorization: .immediate(.available))
        let session = CountingARSession()
        let coordinator = makeCoordinator(probe: probe, session: session)

        let task = Task { @MainActor in
            await coordinator.start()
        }
        task.cancel()
        await task.value

        XCTAssertEqual(probe.authorizationRequestCount, 0)
        XCTAssertEqual(session.runCount, 0)
    }

    func testCancellationDuringAuthorizationDoesNotRunSession() async {
        let probe = ARSessionStartProbe(authorization: .suspended)
        let session = CountingARSession()
        let coordinator = makeCoordinator(probe: probe, session: session)
        let task = Task { @MainActor in
            await coordinator.start()
        }

        await probe.waitUntilAuthorizationRequested()
        XCTAssertEqual(probe.authorizationRequestCount, 1)
        task.cancel()
        probe.completeAuthorization(with: .available)
        await task.value

        XCTAssertEqual(probe.authorizationRequestCount, 1)
        XCTAssertEqual(session.runCount, 0)
    }

    func testActiveStartRequestsAuthorizationAndRunsSessionOnce() async {
        let probe = ARSessionStartProbe(authorization: .immediate(.available))
        let session = CountingARSession()
        let coordinator = makeCoordinator(probe: probe, session: session)

        await coordinator.start()

        XCTAssertEqual(probe.authorizationRequestCount, 1)
        XCTAssertEqual(session.runCount, 1)
        XCTAssertEqual(coordinator.capabilityState, .active)
    }

    func testCapabilityResolutionPrefersUnsupportedHardware() {
        XCTAssertEqual(
            ARCapabilityMonitor.resolve(
                isWorldTrackingSupported: false,
                cameraAuthorizationStatus: .authorized
            ),
            .unsupported
        )
    }

    func testCapabilityResolutionMapsCameraAuthorization() {
        XCTAssertEqual(
            ARCapabilityMonitor.resolve(
                isWorldTrackingSupported: true,
                cameraAuthorizationStatus: .notDetermined
            ),
            .checking
        )
        XCTAssertEqual(
            ARCapabilityMonitor.resolve(
                isWorldTrackingSupported: true,
                cameraAuthorizationStatus: .authorized
            ),
            .available
        )
        XCTAssertEqual(
            ARCapabilityMonitor.resolve(
                isWorldTrackingSupported: true,
                cameraAuthorizationStatus: .denied
            ),
            .cameraDenied
        )
        XCTAssertEqual(
            ARCapabilityMonitor.resolve(
                isWorldTrackingSupported: true,
                cameraAuthorizationStatus: .restricted
            ),
            .cameraDenied
        )
    }

    func testEntityRegistryReplacesExistingEntityAndRemovesItFromParent() {
        let registry = AREntityRegistry()
        let parent = Entity()
        let original = Entity()
        let replacement = Entity()
        parent.addChild(original)

        registry.register(original, for: "marker")
        registry.register(replacement, for: "marker")

        XCTAssertNil(original.parent)
        XCTAssertTrue(registry.entity(for: "marker") === replacement)
        XCTAssertEqual(registry.count, 1)
    }

    func testEntityRegistryClearRemovesAllEntitiesFromParents() {
        let registry = AREntityRegistry()
        let parent = Entity()
        let first = Entity()
        let second = Entity()
        parent.addChild(first)
        parent.addChild(second)
        registry.register(first, for: "first")
        registry.register(second, for: "second")

        registry.clear()

        XCTAssertEqual(registry.count, 0)
        XCTAssertNil(first.parent)
        XCTAssertNil(second.parent)
    }

    private func makeCoordinator(
        probe: ARSessionStartProbe,
        session: ARSession
    ) -> ARSessionCoordinator {
        ARSessionCoordinator(
            session: session,
            requestCameraAccess: { await probe.requestCameraAccess() }
        )
    }
}

@MainActor
private final class ARSessionStartProbe {
    enum Authorization {
        case immediate(ARCapabilityState)
        case suspended
    }

    private let authorization: Authorization
    private var authorizationContinuation: CheckedContinuation<ARCapabilityState, Never>?
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []

    private(set) var authorizationRequestCount = 0

    init(authorization: Authorization) {
        self.authorization = authorization
    }

    func requestCameraAccess() async -> ARCapabilityState {
        authorizationRequestCount += 1
        let waiters = requestWaiters
        requestWaiters.removeAll(keepingCapacity: true)
        waiters.forEach { $0.resume() }

        switch authorization {
        case .immediate(let state):
            return state
        case .suspended:
            return await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
            }
        }
    }

    func waitUntilAuthorizationRequested() async {
        guard authorizationRequestCount == 0 else { return }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func completeAuthorization(with state: ARCapabilityState) {
        authorizationContinuation?.resume(returning: state)
        authorizationContinuation = nil
    }
}

@MainActor
private final class CountingARSession: ARSession {
    private(set) var runCount = 0

    override func run(_ configuration: ARConfiguration, options: ARSession.RunOptions = []) {
        runCount += 1
    }
}
