import WaykinCore
import XCTest
@testable import WaykinApp

final class CompanionPresencePresentationTests: XCTestCase {
    func testCompanionBehaviorMapsToBoundedVisualTreatment() {
        let treatments: [(CompanionBehaviorState, CGFloat, Double, CGFloat)] = [
            (.idle, 0.76, 0.64, 0),
            (.follow, 0.9, 1, 0),
            (.lead, 0.84, 1, -20),
            (.celebrate, 1.12, 1, 0),
            (.observe, 0.76, 0.64, 0),
            (.drawNear, 1.08, 1, 0),
            (.rest, 0.82, 0.72, 0)
        ]

        for (behavior, scale, opacity, offset) in treatments {
            let presentation = makePresentation(behavior: behavior, isOpening: false)
            XCTAssertEqual(presentation.presenceScale, scale, accuracy: 0.001)
            XCTAssertEqual(presentation.presenceOpacity, opacity, accuracy: 0.001)
            XCTAssertEqual(presentation.verticalOffset, offset, accuracy: 0.001)
        }
    }

    func testPursuitStateMapsToIncreasingAndReleasingPressure() {
        XCTAssertEqual(makePresentation(pursuit: .inactive).pressureIntensity, 0)
        XCTAssertEqual(makePresentation(pursuit: .noticed).pressureIntensity, 0.2)
        XCTAssertEqual(makePresentation(pursuit: .approaching).pressureIntensity, 0.45)
        XCTAssertEqual(makePresentation(pursuit: .close).pressureIntensity, 0.75)
        XCTAssertEqual(makePresentation(pursuit: .fading).pressureIntensity, 0.12)
    }

    func testWorldPhrasesAreDeterministicFromExistingState() {
        XCTAssertEqual(makePresentation(event: .companionObserves).phrase, "Lira is watching the path.")
        XCTAssertEqual(makePresentation(event: .companionDrawsNear).phrase, "Lira draws near.")
        XCTAssertEqual(makePresentation(event: .companionMovesAhead).phrase, "Lira has moved ahead.")
        XCTAssertEqual(makePresentation(event: .quietInterval).phrase, "The path has gone quiet.")
        XCTAssertEqual(makePresentation(event: .pursuitFades).phrase, "The pressure is fading.")
        XCTAssertEqual(makePresentation(pursuit: .approaching).phrase, "Something is keeping pace.")
    }

    func testOpeningIsVisibleBeforeMovementAndPausePreservesPresence() {
        let opening = makePresentation(isOpening: true)
        XCTAssertEqual(opening.phrase, "Lira is listening.")
        XCTAssertEqual(opening.elapsedText, "0:00")
        XCTAssertEqual(opening.distanceText, "0 m")

        let active = makePresentation(behavior: .drawNear, event: .companionDrawsNear)
        let paused = makePresentation(behavior: .drawNear, event: .companionDrawsNear, isPaused: true)
        XCTAssertEqual(paused.phrase, active.phrase)
        XCTAssertEqual(paused.behavior.rawValue, active.behavior.rawValue)
        XCTAssertNil(paused.animationDuration)
    }

    func testReducedMotionDisablesBoundedPresenceAnimation() {
        let presentation = makePresentation(behavior: .celebrate)
        XCTAssertNotNil(presentation.animationDuration(reduceMotion: false))
        XCTAssertNil(presentation.animationDuration(reduceMotion: true))
    }

    func testClosingPhraseReflectsActualPressureState() {
        XCTAssertEqual(makePresentation(pursuit: .fading).closingPhrase, "The presence faded.")
        XCTAssertEqual(makePresentation(pursuit: .close).closingPhrase, "Lira stayed with you.")
        XCTAssertEqual(makePresentation(event: .bondMoment).closingPhrase, "The path remembers.")
    }

    // MARK: - Accessibility hardening (Fable active-session pass)

    func testPresenceAccessibilityValueCoversEveryBehaviorWithHumanWording() {
        let expected: [CompanionBehaviorState: String] = [
            .idle: "Lira, waiting quietly. The path is calm.",
            .follow: "Lira, staying close. The path is calm.",
            .lead: "Lira, moving ahead. The path is calm.",
            .celebrate: "Lira, celebrating with you. The path is calm.",
            .observe: "Lira, watching the path. The path is calm.",
            .drawNear: "Lira, drawing near. The path is calm.",
            .rest: "Lira, resting beside you. The path is calm."
        ]
        for (behavior, value) in expected {
            XCTAssertEqual(makePresentation(behavior: behavior).presenceAccessibilityValue, value)
        }
    }

    func testPressureAccessibilityDescriptionCoversEveryPursuitStateDistinctly() {
        let states: [PursuitState] = [.inactive, .noticed, .approaching, .close, .fading]
        let descriptions = states.map { makePresentation(pursuit: $0).pressureAccessibilityDescription }
        XCTAssertEqual(Set(descriptions).count, states.count, "every pursuit state must be distinguishable")
        for description in descriptions {
            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.hasSuffix("."), "should read as a sentence: \(description)")
        }
    }

    func testAccessibilityValuesExposeNoRawEnumOrDebugTerminology() {
        let rawTokens = ["drawNear", "inactive", "quietInterval", "pursuitBegins",
                         "pursuitIntensifies", "bondMoment", "waykin.", "_", "rawValue"]
        for behavior in [CompanionBehaviorState.idle, .follow, .lead, .celebrate, .observe, .drawNear, .rest] {
            for pursuit in [PursuitState.inactive, .noticed, .approaching, .close, .fading] {
                let presentation = makePresentation(behavior: behavior, pursuit: pursuit)
                let value = presentation.presenceAccessibilityValue
                for token in rawTokens {
                    XCTAssertFalse(value.contains(token), "raw token '\(token)' leaked into: \(value)")
                }
                XCTAssertNil(value.rangeOfCharacter(from: .decimalDigits),
                             "numeric pressure must not be exposed: \(value)")
            }
        }
    }

    func testOpeningStateHasValidAccessibilityDescription() {
        let opening = makePresentation(isOpening: true)
        XCTAssertEqual(opening.presenceAccessibilityValue, "Lira is listening.")
        XCTAssertEqual(opening.elapsedAccessibilityValue, "Elapsed time, 0 seconds")
        XCTAssertEqual(opening.distanceAccessibilityValue, "Distance, 0 meters")
    }

    func testMetricAccessibilityValuesReadNaturally() {
        let mid = makePresentation(elapsedSeconds: 252, distanceMeters: 380.9)
        XCTAssertEqual(mid.elapsedAccessibilityValue, "Elapsed time, 4 minutes 12 seconds")
        XCTAssertEqual(mid.distanceAccessibilityValue, "Distance, 380 meters")

        let singular = makePresentation(elapsedSeconds: 61, distanceMeters: 1)
        XCTAssertEqual(singular.elapsedAccessibilityValue, "Elapsed time, 1 minute 1 second")
        XCTAssertEqual(singular.distanceAccessibilityValue, "Distance, 1 meter")

        let underMinute = makePresentation(elapsedSeconds: 42, distanceMeters: 0)
        XCTAssertEqual(underMinute.elapsedAccessibilityValue, "Elapsed time, 42 seconds")
    }

    func testCalmAndPressureStatesDistinguishableWithoutColor() {
        let calm = makePresentation(pursuit: .inactive)
        let close = makePresentation(pursuit: .close)
        // Geometry channel: ring thickness grows with pressure.
        XCTAssertGreaterThan(close.pressureStrokeWidth, calm.pressureStrokeWidth)
        // Text channels: status label and VoiceOver description both differ.
        XCTAssertNotEqual(close.pressureLabel, calm.pressureLabel)
        XCTAssertNotEqual(close.pressureAccessibilityDescription, calm.pressureAccessibilityDescription)
    }

    func testReducedMotionIsStaticForEveryBehaviorAndPauseKeepsSemantics() {
        for behavior in [CompanionBehaviorState.idle, .follow, .lead, .celebrate, .observe, .drawNear, .rest] {
            XCTAssertNil(makePresentation(behavior: behavior).animationDuration(reduceMotion: true),
                         "reduced motion must remove continuous animation for \(behavior.rawValue)")
        }
        // Pausing never resets what the state means, with or without motion.
        let active = makePresentation(behavior: .drawNear, pursuit: .approaching)
        let paused = makePresentation(behavior: .drawNear, pursuit: .approaching, isPaused: true)
        XCTAssertEqual(paused.presenceAccessibilityValue, active.presenceAccessibilityValue)
        XCTAssertEqual(paused.phrase, active.phrase)
        XCTAssertNil(paused.animationDuration(reduceMotion: false))
        XCTAssertNil(paused.animationDuration(reduceMotion: true))
    }

    func testClosingAccessibilityReflectsOnlyActualFinalState() {
        XCTAssertEqual(makePresentation(pursuit: .fading).closingPhrase, "The presence faded.")
        XCTAssertEqual(makePresentation().closingPhrase, "Lira stayed with you.")
        // The closing line never invents an event that did not occur.
        XCTAssertEqual(makePresentation(event: nil).closingPhrase, "Lira stayed with you.")
    }

    private func makePresentation(
        behavior: CompanionBehaviorState = .follow,
        pursuit: PursuitState = .inactive,
        event: WorldEventKind? = nil,
        isOpening: Bool = false,
        isPaused: Bool = false,
        elapsedSeconds: TimeInterval = 0,
        distanceMeters: Double = 0
    ) -> CompanionPresencePresentation {
        CompanionPresencePresentation(
            companionName: "Lira",
            bondLevel: 12,
            behavior: behavior,
            pursuitState: pursuit,
            eventKind: event,
            audioCueKind: nil,
            elapsedSeconds: elapsedSeconds,
            distanceMeters: distanceMeters,
            isPaused: isPaused,
            isOpening: isOpening,
            latitude: nil,
            longitude: nil
        )
    }
}
