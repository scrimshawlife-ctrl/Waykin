import XCTest
@testable import WaykinApp

final class CompanionLocomotionPolicyTests: XCTestCase {
    func testDeadZoneHoldsPosition() {
        let policy = CompanionLocomotionPolicy()
        XCTAssertEqual(
            policy.decision(current: [0, 0, 0], target: [0.2, 0, 0], deltaTime: 1),
            .hold
        )
    }

    func testMovementIsBoundedByMaximumSpeed() {
        let policy = CompanionLocomotionPolicy()
        XCTAssertEqual(
            policy.decision(current: [0, 0, 0], target: [4, 0, 0], deltaTime: 1),
            .move([1.5, 0, 0])
        )
    }

    func testSevereDisplacementRequestsReset() {
        let policy = CompanionLocomotionPolicy()
        XCTAssertEqual(
            policy.decision(current: [0, 0, 0], target: [9, 0, 0], deltaTime: 1),
            .reset([9, 0, 0])
        )
    }

    func testInvalidInputFailsClosed() {
        let policy = CompanionLocomotionPolicy()
        XCTAssertEqual(
            policy.decision(current: [.infinity, 0, 0], target: [1, 0, 0], deltaTime: 1),
            .hold
        )
        XCTAssertEqual(
            policy.decision(current: [0, 0, 0], target: [1, 0, 0], deltaTime: .nan),
            .hold
        )
    }
}
