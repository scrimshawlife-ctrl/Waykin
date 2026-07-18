import AVFoundation
import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class ARSessionShellTests: XCTestCase {
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

    func testEntityRegistryClearRemovesRegisteredAnchorsFromScene() {
        let registry = AREntityRegistry()
        let arView = ARView(frame: .zero)
        let first = AnchorEntity()
        let second = AnchorEntity()
        arView.scene.addAnchor(first)
        arView.scene.addAnchor(second)
        registry.register(first, for: "first")
        registry.register(second, for: "second")

        XCTAssertEqual(arView.scene.anchors.count, 2)

        registry.clear()

        XCTAssertEqual(registry.count, 0)
        XCTAssertTrue(arView.scene.anchors.isEmpty)
        XCTAssertNil(first.parent)
        XCTAssertNil(second.parent)
    }

    func testBackgroundPauseThenTrackingResetStartRestoresActiveSession() async {
        let monitor = ARCapabilityMonitor(
            currentState: { .available },
            requestCameraAccess: { .available }
        )
        let coordinator = ARSessionCoordinator(capabilityMonitor: monitor)
        var resetCount = 0
        coordinator.onSessionReset = { resetCount += 1 }

        await coordinator.start()
        coordinator.pause()

        XCTAssertEqual(coordinator.capabilityState, .available)
        XCTAssertEqual(resetCount, 0)

        await coordinator.start(resetTracking: true)

        XCTAssertEqual(resetCount, 1)
        XCTAssertEqual(coordinator.capabilityState, .active)
    }

    func testARLabBackgroundClearsEntitiesAndStopsDemoBeforeResume() async throws {
        let registry = AREntityRegistry()
        let coordinator = availableCoordinator()
        let bridge = ARDemoRuntimeBridge()
        let runtime = ARCompanionLabRuntime(
            registry: registry,
            sessionCoordinator: coordinator,
            demoBridge: bridge
        )
        let arView = ARView(frame: .zero)
        runtime.attach(arView)
        let entity = Entity()
        registry.register(entity, for: "stale")
        _ = try bridge.start()

        runtime.handleScenePhase(.background)

        XCTAssertEqual(runtime.registryCount, 0)
        XCTAssertFalse(runtime.isDemoRunning)
        XCTAssertEqual(runtime.trackingText, "Paused")

        registry.register(Entity(), for: "between-phases")
        await runtime.resumeAfterBackground()

        XCTAssertEqual(runtime.registryCount, 0)
        XCTAssertEqual(coordinator.capabilityState, .active)
    }

    func testARLabConsumesPendingBackgroundResetWhenViewAttaches() async throws {
        let registry = AREntityRegistry()
        let coordinator = availableCoordinator()
        let bridge = ARDemoRuntimeBridge()
        let runtime = ARCompanionLabRuntime(
            registry: registry,
            sessionCoordinator: coordinator,
            demoBridge: bridge
        )
        registry.register(Entity(), for: "pre-attachment")
        _ = try bridge.start()
        let arView = ARView(frame: .zero)

        runtime.handleScenePhase(.background)
        runtime.attach(arView)

        for _ in 0..<100 where runtime.registryCount != 0 || runtime.isDemoRunning {
            try? await Task.sleep(for: .milliseconds(20))
        }

        XCTAssertEqual(runtime.registryCount, 0)
        XCTAssertFalse(runtime.isDemoRunning)
    }

    func testARLabBackgroundCancelsAnInFlightSessionStart() async {
        let monitor = ARCapabilityMonitor(
            currentState: { .available },
            requestCameraAccess: {
                try? await Task.sleep(for: .milliseconds(100))
                return .available
            }
        )
        let coordinator = ARSessionCoordinator(capabilityMonitor: monitor)
        let runtime = ARCompanionLabRuntime(sessionCoordinator: coordinator)
        let arView = ARView(frame: .zero)

        runtime.attach(arView)
        runtime.handleScenePhase(.background)
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(coordinator.capabilityState, .available)
        XCTAssertEqual(runtime.trackingText, "Paused")
    }

    func testARLabRetainsPendingResetUntilAuthorizationAllowsRecovery() async {
        var authorization: ARCapabilityState = .cameraDenied
        let monitor = ARCapabilityMonitor(
            currentState: { authorization },
            requestCameraAccess: { authorization }
        )
        let coordinator = ARSessionCoordinator(capabilityMonitor: monitor)
        let registry = AREntityRegistry()
        let runtime = ARCompanionLabRuntime(
            registry: registry,
            sessionCoordinator: coordinator
        )
        let arView = ARView(frame: .zero)
        registry.register(Entity(), for: "pending-authorization")

        runtime.handleScenePhase(.background)
        runtime.attach(arView)
        try? await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(runtime.registryCount, 1)

        authorization = .available
        await runtime.resumeAfterBackground()

        XCTAssertEqual(runtime.registryCount, 0)
    }

    func testARLabReplacingActiveViewClearsOldSceneState() {
        let registry = AREntityRegistry()
        let runtime = ARCompanionLabRuntime(
            registry: registry,
            sessionCoordinator: availableCoordinator()
        )
        let firstView = ARView(frame: .zero)
        let secondView = ARView(frame: .zero)
        runtime.attach(firstView)
        registry.register(Entity(), for: "old-view")

        runtime.attach(secondView)

        XCTAssertEqual(runtime.registryCount, 0)
    }

    private func availableCoordinator() -> ARSessionCoordinator {
        ARSessionCoordinator(
            capabilityMonitor: ARCapabilityMonitor(
                currentState: { .available },
                requestCameraAccess: { .available }
            )
        )
    }
}
