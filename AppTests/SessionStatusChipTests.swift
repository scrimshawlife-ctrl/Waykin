import SwiftUI
import XCTest
@testable import WaykinApp

@MainActor
final class SessionStatusChipTests: XCTestCase {
    func testChipTonesAreDistinct() {
        XCTAssertNotEqual(SessionStatusChip.Tone.calm, SessionStatusChip.Tone.caution)
        XCTAssertNotEqual(SessionStatusChip.Tone.caution, SessionStatusChip.Tone.emphasis)
    }

    func testGPSPresentationMapsIntoChipInputs() {
        let signal = GPSSignalPresentation(state: .active)
        let chip = SessionStatusChip(
            title: signal.label,
            systemImage: signal.symbolName,
            tone: signal.isProblem ? .caution : .calm,
            accessibilityLabelText: "GPS status",
            accessibilityValueText: signal.accessibilityValue,
            accessibilityIdentifier: "waykin.session.liveSignal"
        )
        XCTAssertEqual(chip.title, "GPS active")
        XCTAssertEqual(chip.tone, .calm)
        XCTAssertEqual(chip.accessibilityIdentifier, "waykin.session.liveSignal")
    }

    func testDegradedGPSUsesCautionTone() {
        let signal = GPSSignalPresentation(state: .degraded)
        XCTAssertTrue(signal.isProblem)
        XCTAssertEqual(signal.label, "GPS weak")
    }
}
