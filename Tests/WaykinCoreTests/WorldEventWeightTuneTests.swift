import XCTest
@testable import WaykinCore

final class WorldEventWeightTuneTests: XCTestCase {
    func testDefaultRulesCoverExactlyBoundedVocabulary() {
        let kinds = Set(WorldEventGeneratorConfiguration.defaultRules.map(\.kind))
        XCTAssertEqual(kinds, Set(WorldEventKind.allCases))
        XCTAssertEqual(WorldEventGeneratorConfiguration.defaultRules.count, WorldEventKind.allCases.count)
    }

    func testCompanionPresenceOutweighsPursuitEntryWhenOverlapping() {
        let rules = WorldEventGeneratorConfiguration.defaultRules
        func weight(_ kind: WorldEventKind) -> UInt64 {
            rules.first { $0.kind == kind }!.weight
        }

        let companionWeight =
            weight(.companionDrawsNear)
            + weight(.companionObserves)
            + weight(.companionMovesAhead)
        let pursuitEntryWeight = weight(.pursuitBegins) + weight(.distantPresence)

        XCTAssertGreaterThan(companionWeight, pursuitEntryWeight)
        XCTAssertGreaterThan(weight(.companionDrawsNear), weight(.pursuitBegins))
        XCTAssertGreaterThan(weight(.companionDrawsNear), weight(.quietInterval))
    }

    func testPursuitBeginsIsRarerThanCompanionDrawsNear() throws {
        let rules = Dictionary(
            uniqueKeysWithValues: WorldEventGeneratorConfiguration.defaultRules.map { ($0.kind, $0) }
        )
        let drawsNear = try XCTUnwrap(rules[.companionDrawsNear])
        let begins = try XCTUnwrap(rules[.pursuitBegins])

        XCTAssertGreaterThan(begins.cooldown, drawsNear.cooldown)
        XCTAssertGreaterThan(begins.minimumPressure, drawsNear.minimumPressure)
        XCTAssertLessThan(begins.weight, drawsNear.weight)
    }

    func testBondMomentThresholdIsReachableWithoutHighBond() throws {
        let bond = try XCTUnwrap(
            WorldEventGeneratorConfiguration.defaultRules.first { $0.kind == .bondMoment }
        )
        XCTAssertLessThanOrEqual(bond.minimumBondLevel, 8)
        XCTAssertLessThanOrEqual(bond.minimumEnergy, 0.25)
    }

    func testFrequencyBoundStillHoldsAfterLightTune() {
        let start = Date(timeIntervalSince1970: 5_000)
        var generator = WorldEventGenerator(seed: 19)
        var lastEventAt: Date?
        var count = 0

        for idx in 0..<30 {
            let now = start.addingTimeInterval(Double(idx * 10))
            let state = WorldState(
                timeContext: .twilight,
                movementState: .moving,
                currentSpeedMetersPerSecond: 1.5,
                sessionDistanceMeters: Double(idx * 25),
                activeTime: Double(idx * 10),
                bondLevel: 14,
                familiarity: 0.4,
                energy: 0.7,
                pressure: 0.4,
                lastEventAt: lastEventAt
            )
            if let event = generator.evaluate(state: state, now: now) {
                count += 1
                lastEventAt = event.occurredAt
            }
        }

        // minimumTickSpacing 40s over ~300s active window → sparse generation.
        XCTAssertLessThanOrEqual(count, 8)
        XCTAssertGreaterThan(count, 0)
    }

    func testCompanionEligibleStatePrefersNonPursuitKindsOften() {
        let start = Date(timeIntervalSince1970: 9_000)
        var counts: [WorldEventKind: Int] = [:]

        for seed in UInt64(1)...40 {
            var generator = WorldEventGenerator(seed: seed)
            let state = WorldState(
                timeContext: .midday,
                movementState: .moving,
                currentSpeedMetersPerSecond: 1.3,
                sessionDistanceMeters: 120,
                activeTime: 80,
                bondLevel: 12,
                familiarity: 0.25,
                energy: 0.35,
                pressure: 0.18,
                lastEventAt: nil
            )
            if let event = generator.evaluate(state: state, now: start) {
                counts[event.kind, default: 0] += 1
            }
        }

        let companionHits =
            (counts[.companionDrawsNear] ?? 0)
            + (counts[.companionObserves] ?? 0)
            + (counts[.companionMovesAhead] ?? 0)
            + (counts[.quietInterval] ?? 0)
        let pursuitHits =
            (counts[.pursuitBegins] ?? 0)
            + (counts[.pursuitIntensifies] ?? 0)
            + (counts[.distantPresence] ?? 0)

        XCTAssertGreaterThan(companionHits, 0)
        XCTAssertGreaterThanOrEqual(companionHits, pursuitHits)
        // Low pressure must not open pursuit intensifies.
        XCTAssertEqual(counts[.pursuitIntensifies] ?? 0, 0)
    }
}
