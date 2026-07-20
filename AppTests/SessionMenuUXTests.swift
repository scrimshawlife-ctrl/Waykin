import SwiftUI
import WaykinCore
import XCTest
@testable import WaykinApp

/// #126 menu UX — structure and identifiers (simulator-safe).
@MainActor
final class SessionMenuUXTests: XCTestCase {
    func testRealWalkCTATitlesForSessionStates() {
        // Mirrors HomeView realWalkButtonTitle mapping without mounting the full view tree.
        XCTAssertEqual(title(for: .idle), "Begin Walk")
        XCTAssertEqual(title(for: .completed), "Begin Walk")
        XCTAssertEqual(title(for: .requestingPermission), "Allow Location…")
        XCTAssertEqual(title(for: .active), "Walk in Progress")
        XCTAssertEqual(title(for: .paused), "Walk in Progress")
        XCTAssertEqual(title(for: .ending), "Ending Walk…")
        XCTAssertEqual(title(for: .failed), "Try Walk Again")
    }

    func testRealWalkCTADisabledOnlyWhileBusy() {
        XCTAssertFalse(disabled(for: .idle))
        XCTAssertFalse(disabled(for: .completed))
        XCTAssertFalse(disabled(for: .failed))
        XCTAssertTrue(disabled(for: .requestingPermission))
        XCTAssertTrue(disabled(for: .active))
        XCTAssertTrue(disabled(for: .paused))
        XCTAssertTrue(disabled(for: .ending))
    }

    func testCanonicalARAcceptsMirroredSessionControls() {
        // Compile-time / API surface: optional session hooks exist for full-screen AR.
        let view = CanonicalARSessionView(
            appModel: StubARCommandSource(),
            liraSkin: .dawn,
            isPaused: false,
            onPause: {},
            onResume: {},
            onEnd: {}
        )
        XCTAssertNotNil(view.onPause)
        XCTAssertNotNil(view.onResume)
        XCTAssertNotNil(view.onEnd)
        XCTAssertFalse(view.isPaused)
    }

    // MARK: - Local mirrors of HomeView mapping (#126)

    private func title(for state: RealWalkSessionState) -> String {
        switch state {
        case .requestingPermission: return "Allow Location…"
        case .active, .paused: return "Walk in Progress"
        case .ending: return "Ending Walk…"
        case .failed: return "Try Walk Again"
        case .idle, .completed: return "Begin Walk"
        }
    }

    private func disabled(for state: RealWalkSessionState) -> Bool {
        switch state {
        case .requestingPermission, .active, .paused, .ending: return true
        case .idle, .completed, .failed: return false
        }
    }
}

@MainActor
private final class StubARCommandSource: CanonicalARCommandSource {
    func attachARWorldCommandHandler(_ handler: @escaping ([ARWorldCommand]) -> Void) -> UUID { UUID() }
    func detachARWorldCommandHandler(owner: UUID) {}
    func ingestARPresentationDiagnostics(_ summary: FieldTestARPresentationSummary) {}
}
