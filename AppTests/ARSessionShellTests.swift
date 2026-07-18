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
}
