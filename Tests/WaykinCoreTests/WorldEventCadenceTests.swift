import XCTest
@testable import WaykinCore

/// Field receipts show very few world events on real walks — 2 in 255s, 4 in 185s — so the
/// companion rarely reacts to anything. These measure the generator's actual yield over a
/// simulated walk rather than asserting intent, so tuning can be judged against a number.
final class WorldEventCadenceTests: XCTestCase {
    /// A calm first-time walk: low pressure, no route familiarity — the common case.
    private func calmState(elapsed: TimeInterval, distance: Double) -> WorldState {
        WorldState(
            timeContext: .midday,
            movementState: .moving,
            currentSpeedMetersPerSecond: 1.2,
            sessionDistanceMeters: distance,
            activeTime: elapsed,
            bondLevel: 20,
            familiarity: min(1, distance / 2000),
            energy: 0.45,
            pressure: 0.0
        )
    }

    private func runWalk(
        seconds: TimeInterval,
        configuration: WorldEventGeneratorConfiguration,
        state: (TimeInterval) -> WorldState
    ) -> [WorldEventKind] {
        var generator = WorldEventGenerator(seed: 42, configuration: configuration)
        var fired: [WorldEventKind] = []
        let start = Date(timeIntervalSince1970: 0)
        var t: TimeInterval = 0
        while t <= seconds {
            if let event = generator.evaluate(
                state: state(t),
                now: start.addingTimeInterval(t),
                elapsed: t
            ) {
                fired.append(event.kind)
            }
            t += 1
        }
        return fired
    }

    func testCalmWalkEventYield() {
        let minutes: TimeInterval = 5
        let fired = runWalk(seconds: minutes * 60, configuration: WorldEventGeneratorConfiguration()) { t in
            self.calmState(elapsed: t, distance: t * 1.2)
        }
        let perMinute = Double(fired.count) / minutes
        var counts: [String: Int] = [:]
        for k in fired { counts[k.rawValue, default: 0] += 1 }
        print("WAYKIN_CADENCE_CALM: \(fired.count) events in \(Int(minutes))min = \(String(format: "%.2f", perMinute))/min")
        print("WAYKIN_CADENCE_KINDS: \(counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))")
        XCTAssertGreaterThan(fired.count, 0, "a calm walk produced no events at all")
    }

    /// How much of the vocabulary a real walk unlocks, derived the way the app derives it.
    /// Pressure is what gates half the kinds, so this must go through `WorldState.derive`
    /// rather than a hand-built state, or it measures nothing.
    func testVocabularyUnlockedByRealWalkDistances() {
        for (metres, seconds) in [(50.0, 60.0), (150.0, 180.0), (400.0, 420.0), (800.0, 720.0)] {
            var session = MovementSession(activityType: .walk, experienceID: "cadence")
            session.distanceMeters = metres
            session.activeTime = seconds
            session.currentSpeedMetersPerSecond = 1.2
            session.movementState = .moving
            let state = WorldState.derive(from: session, timeContext: .midday, bondLevel: 20)
            let reachable = WorldEventGeneratorConfiguration.defaultRules.filter {
                $0.isEligible(for: state, elapsed: seconds, lastFiredAtElapsed: nil)
            }
            print(String(
                format: "WAYKIN_UNLOCK %.0fm/%.0fs pressure=%.2f reachable=%d/%d %@",
                metres, seconds, state.pressure, reachable.count,
                WorldEventKind.allCases.count,
                reachable.map { $0.kind.rawValue }.sorted().joined(separator: ",")
            ))
        }
    }

    /// How much of the vocabulary a calm walker can ever see.
    func testCalmWalkReachableVocabulary() {
        let state = calmState(elapsed: 600, distance: 700)
        let reachable = WorldEventGeneratorConfiguration.defaultRules.filter {
            $0.isEligible(for: state, elapsed: 600, lastFiredAtElapsed: nil)
        }
        print("WAYKIN_REACHABLE_CALM: \(reachable.count)/\(WorldEventKind.allCases.count) — \(reachable.map { $0.kind.rawValue }.sorted().joined(separator: ","))")
        let unreachable = Set(WorldEventKind.allCases).subtracting(reachable.map(\.kind))
        print("WAYKIN_UNREACHABLE_CALM: \(unreachable.map(\.rawValue).sorted().joined(separator: ","))")
        XCTAssertGreaterThan(reachable.count, 0)
    }
}
