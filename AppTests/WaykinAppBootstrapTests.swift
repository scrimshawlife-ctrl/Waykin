import SwiftData
import XCTest
@testable import WaykinApp
import WaykinCore

@MainActor
final class WaykinAppBootstrapTests: XCTestCase {
    func testPrimarySuccessLaunchesFileBackedMode() throws {
        let primary = try makeInMemoryContainer()
        var fallbackCalls = 0
        let bootstrapper = WaykinAppBootstrapper(
            makePrimaryContainer: { _, _ in primary },
            makeFallbackContainer: {
                fallbackCalls += 1
                return try self.makeInMemoryContainer()
            }
        )

        guard case .ready(_, let model) = bootstrapper.bootstrap(
            isUITesting: false,
            shouldReset: false
        ) else {
            return XCTFail("Expected ready bootstrap")
        }
        XCTAssertEqual(model.persistenceMode, "FILE_BACKED")
        XCTAssertEqual(fallbackCalls, 0)
    }

    func testPrimaryFailureUsesInMemoryFallback() throws {
        let fallback = try makeInMemoryContainer()
        let bootstrapper = WaykinAppBootstrapper(
            makePrimaryContainer: { _, _ in throw BootstrapTestError.failed },
            makeFallbackContainer: { fallback }
        )

        guard case .ready(_, let model) = bootstrapper.bootstrap(
            isUITesting: true,
            shouldReset: true
        ) else {
            return XCTFail("Expected fallback bootstrap")
        }
        XCTAssertEqual(model.persistenceMode, "IN_MEMORY_FALLBACK")
    }

    func testDualFailureReturnsUnavailableWithoutCreatingModel() {
        var primaryCalls = 0
        var fallbackCalls = 0
        let bootstrapper = WaykinAppBootstrapper(
            makePrimaryContainer: { _, _ in
                primaryCalls += 1
                throw BootstrapTestError.failed
            },
            makeFallbackContainer: {
                fallbackCalls += 1
                throw BootstrapTestError.failed
            }
        )

        guard case .unavailable = bootstrapper.bootstrap(
            isUITesting: false,
            shouldReset: false
        ) else {
            return XCTFail("Expected unavailable bootstrap")
        }
        XCTAssertEqual(primaryCalls, 1)
        XCTAssertEqual(fallbackCalls, 1)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}

private enum BootstrapTestError: Error {
    case failed
}
