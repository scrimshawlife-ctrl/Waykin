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

    func testPressureStatesHaveDistinctHumanAccessibilityDescriptions() {
        let descriptions: [(PursuitState, String)] = [
            (.inactive, "The path is quiet."),
            (.noticed, "A change has been noticed on the path."),
            (.approaching, "Something is drawing closer on the path."),
            (.close, "The pressure is close."),
            (.fading, "The pressure is fading.")
        ]

        XCTAssertEqual(Set(descriptions.map { $0.1 }).count, descriptions.count)
        for (state, expected) in descriptions {
            XCTAssertEqual(makePresentation(pursuit: state).pressureAccessibilityValue, expected)
        }
    }

    func testAccessibilityValuesDoNotLeakRawPressureOrDebugTokens() {
        for state in [PursuitState.inactive, .noticed, .approaching, .close, .fading] {
            let value = makePresentation(pursuit: state).pressureAccessibilityValue.lowercased()
            XCTAssertNotEqual(value, state.rawValue.lowercased())
            XCTAssertFalse(value.contains("pressure \(state.rawValue.lowercased())"))
            XCTAssertFalse(value.rangeOfCharacter(from: .decimalDigits) != nil)
            XCTAssertFalse(value.contains("pursuitstate"))
            XCTAssertFalse(value.contains("debug"))
        }
    }

    func testMetricsProvideNaturalSingularAndPluralAccessibilityValues() {
        XCTAssertEqual(makePresentation(elapsedSeconds: 0).elapsedAccessibilityValue, "0 seconds")
        XCTAssertEqual(makePresentation(elapsedSeconds: 1).elapsedAccessibilityValue, "1 second")
        XCTAssertEqual(makePresentation(elapsedSeconds: 59).elapsedAccessibilityValue, "59 seconds")
        XCTAssertEqual(makePresentation(elapsedSeconds: 60).elapsedAccessibilityValue, "1 minute")
        XCTAssertEqual(makePresentation(elapsedSeconds: 61).elapsedAccessibilityValue, "1 minute, 1 second")
        XCTAssertEqual(makePresentation(elapsedSeconds: 122).elapsedAccessibilityValue, "2 minutes, 2 seconds")
        XCTAssertEqual(makePresentation(distanceMeters: 0).distanceAccessibilityValue, "0 meters")
        XCTAssertEqual(makePresentation(distanceMeters: 1).distanceAccessibilityValue, "1 meter")
        XCTAssertEqual(makePresentation(distanceMeters: 2).distanceAccessibilityValue, "2 meters")
    }

    func testPressureChangesBothTextAndOuterRingGeometry() {
        let quiet = makePresentation(pursuit: .inactive)
        let close = makePresentation(pursuit: .close)

        XCTAssertNotEqual(quiet.pressureLabel, close.pressureLabel)
        XCTAssertNotEqual(quiet.pressureStrokeWidth, close.pressureStrokeWidth)
        XCTAssertEqual(quiet.pressureStrokeWidth, 2, accuracy: 0.001)
        XCTAssertEqual(close.pressureStrokeWidth, 6.5, accuracy: 0.001)
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

    func testPresentationProvidesExplicitNonColorStatusText() {
        let presentation = makePresentation(behavior: .rest, pursuit: .approaching)

        XCTAssertEqual(presentation.phrase, "Something is keeping pace.")
        XCTAssertEqual(presentation.pressureLabel, "Pressure approaching")
        XCTAssertEqual(presentation.audioLabel, "Sound quiet")
    }

    func testPressureEquivalentPhrasesHaveOneAccessibilityOwner() {
        XCTAssertTrue(makePresentation(pursuit: .close, event: .pursuitIntensifies).phraseIsRedundantForAccessibility)
        XCTAssertTrue(makePresentation(pursuit: .fading, event: .pursuitFades).phraseIsRedundantForAccessibility)
        XCTAssertTrue(makePresentation(pursuit: .inactive, event: .quietInterval).phraseIsRedundantForAccessibility)
        XCTAssertTrue(makePresentation(pursuit: .close).phraseIsRedundantForAccessibility)
        XCTAssertTrue(makePresentation(pursuit: .fading).phraseIsRedundantForAccessibility)

        XCTAssertFalse(makePresentation(pursuit: .noticed, event: .pursuitBegins).phraseIsRedundantForAccessibility)
        XCTAssertFalse(makePresentation(pursuit: .approaching).phraseIsRedundantForAccessibility)
        XCTAssertFalse(makePresentation(pursuit: .close, event: .companionDrawsNear).phraseIsRedundantForAccessibility)
        XCTAssertFalse(makePresentation(pursuit: .noticed, event: .quietInterval).phraseIsRedundantForAccessibility)
        XCTAssertFalse(makePresentation(pursuit: .close, event: .pursuitIntensifies, isOpening: true).phraseIsRedundantForAccessibility)
    }

    func testMapAccessibilityProvidesContextWithoutCoordinates() {
        let waiting = CompactSessionMap(latitude: nil, longitude: nil)
        let located = CompactSessionMap(latitude: 37.7749, longitude: -122.4194)

        XCTAssertEqual(waiting.locationAccessibilityValue, "Waiting for a location update.")
        XCTAssertEqual(located.locationAccessibilityValue, "Current location is available for this walk.")
        XCTAssertFalse(located.locationAccessibilityValue.contains("37.7749"))
        XCTAssertFalse(located.locationAccessibilityValue.contains("-122.4194"))
    }

    func testClosingPhraseReflectsActualPressureState() {
        XCTAssertEqual(makePresentation(pursuit: .fading).closingPhrase, "The presence faded.")
        XCTAssertEqual(makePresentation(pursuit: .close).closingPhrase, "Lira stayed with you.")
        XCTAssertEqual(makePresentation(event: .bondMoment).closingPhrase, "The path remembers.")
    }

    func testPathRelationPhrasesWhenPursuitInactive() {
        XCTAssertEqual(
            makePresentation(pathRelation: .onPath).phrase,
            "Lira walks with you."
        )
        XCTAssertEqual(
            makePresentation(pathRelation: .onPath, energyHint: 0.2).phrase,
            "Lira matches your pace."
        )
        XCTAssertEqual(makePresentation(pathRelation: .strained).phrase, "The path feels strained.")
        XCTAssertEqual(makePresentation(pathRelation: .offPath).phrase, "The path has slipped.")
        XCTAssertEqual(
            makePresentation(pathRelation: .recovered).phrase,
            "The path is finding you again."
        )
        // World event still wins over path.
        XCTAssertEqual(
            makePresentation(event: .bondMoment, pathRelation: .strained).phrase,
            "Lira shares the moment."
        )
        // Pursuit still wins over path.
        XCTAssertEqual(
            makePresentation(pursuit: .close, pathRelation: .onPath).phrase,
            "The pressure is close."
        )
    }

    func testPathIntegrityBlendsIntoInactivePressure() {
        let quiet = makePresentation(pathRelation: .establishing, pathIntegrityPressure: 0)
        let strained = makePresentation(pathRelation: .strained, pathIntegrityPressure: 0.5)
        XCTAssertEqual(quiet.pressureIntensity, 0, accuracy: 0.001)
        XCTAssertGreaterThan(strained.pressureIntensity, 0.3)
        XCTAssertEqual(strained.pressureLabel, "Path strained")
        XCTAssertEqual(strained.pressureAccessibilityValue, "The path feels strained.")
    }

    func testEnergyHintLiftsPresenceOpacitySlightly() {
        let base = makePresentation(behavior: .idle, energyHint: 0)
        let lifted = makePresentation(behavior: .idle, energyHint: 0.2)
        XCTAssertEqual(base.presenceOpacity, 0.64, accuracy: 0.001)
        XCTAssertGreaterThan(lifted.presenceOpacity, base.presenceOpacity)
        XCTAssertLessThanOrEqual(lifted.presenceOpacity, 1)
    }

    private func makePresentation(
        behavior: CompanionBehaviorState = .follow,
        pursuit: PursuitState = .inactive,
        event: WorldEventKind? = nil,
        isOpening: Bool = false,
        isPaused: Bool = false,
        elapsedSeconds: TimeInterval = 0,
        distanceMeters: Double = 0,
        pathRelation: PathRelation = .establishing,
        pathIntegrityPressure: Double = 0,
        energyHint: Double = 0
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
            longitude: nil,
            pathRelation: pathRelation,
            pathIntegrityPressure: pathIntegrityPressure,
            energyHint: energyHint
        )
    }
}
