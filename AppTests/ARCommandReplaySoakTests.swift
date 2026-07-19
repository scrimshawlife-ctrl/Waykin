import RealityKit
import WaykinCore
import XCTest
@testable import WaykinApp

/// Issue #46: deterministic replay and soak validation for the canonical
/// runtime -> ARWorldCommand -> host -> renderer integration (PR #45).
/// Simulator-only; no wall-clock sleeps; unit-level mapping semantics are
/// already covered by CanonicalARRuntimeIntegrationTests — these tests work
/// at whole-trace and long-sequence level.
@MainActor
final class ARCommandReplaySoakTests: XCTestCase {

    // MARK: Trace determinism

    func testCompanionDiscoveryPursuitTraceReplaysIdentically() {
        let first = ARCommandReplayHarness().run(ReplayTraces.companionDiscoveryPursuit)
        let second = ARCommandReplayHarness().run(ReplayTraces.companionDiscoveryPursuit)

        XCTAssertEqual(first, second, "identical traces must replay identically")
        XCTAssertFalse(first.renderedCommands.isEmpty)
        XCTAssertTrue(first.finalPending.isEmpty)
        XCTAssertEqual(first.finalCompanionState, .idle, "trace ends cleared")
        XCTAssertEqual(first.renderedCommands.last, .clearSession)
    }

    func testDetachReattachTraceReplaysIdenticallyAndRestoresDeterministically() {
        let first = ARCommandReplayHarness().run(ReplayTraces.detachReattachRestore)
        let second = ARCommandReplayHarness().run(ReplayTraces.detachReattachRestore)

        XCTAssertEqual(first, second)
        // The snapshot restore after reattach arrives in canonical order:
        // companion first, then the restored threat.
        let spawnIndexes = first.renderedCommands.enumerated().compactMap { index, command -> Int? in
            if case .spawnCompanion = command { return index }
            return nil
        }
        XCTAssertEqual(spawnIndexes.count, 2, "initial spawn plus one snapshot restore")
        if case .spawnThreat(let threat) = first.renderedCommands[spawnIndexes[1] + 1] {
            XCTAssertEqual(threat.id, CanonicalARWorldCommandMapper.threatID)
        } else {
            XCTFail("snapshot restore must place the threat immediately after Lira")
        }
    }

    // MARK: Reattach staleness

    func testClearEmptiesPendingAndNothingStaleReplaysAfterReattach() {
        let harness = ARCommandReplayHarness()
        harness.policy = { _ in .deferred("no plane yet") }
        harness.attachFreshView()

        harness.perform(.spawn)
        harness.perform(.event(.pursuitBegins, intensity: 0.5))
        XCTAssertFalse(harness.runtime.pendingCommandSnapshot.isEmpty)

        // Clear synchronously removes all pending work.
        harness.perform(.clear)
        XCTAssertTrue(harness.runtime.pendingCommandSnapshot.isEmpty)

        // After detach + reattach, pumping the drain replays nothing stale.
        harness.perform(.detach)
        let renderedBeforeReattach = harness.renderedCommands.count
        harness.perform(.reattach)
        harness.perform(.drain)
        harness.perform(.drain)
        XCTAssertEqual(harness.renderedCommands(after: renderedBeforeReattach), [],
                       "a fresh host must start silent — no stale replay")
        XCTAssertTrue(harness.runtime.pendingCommandSnapshot.isEmpty)
        XCTAssertEqual(harness.runtime.companionState, .idle)
    }

    // MARK: Stale host teardown

    func testStaleHostTeardownCannotDisconnectNewerHost() {
        let harness = ARCommandReplayHarness()
        harness.attachFreshView()
        let staleView = harness.currentView!

        // A newer host takes over (the runtime detaches the old one itself).
        harness.attachFreshView()
        XCTAssertEqual(harness.source.activeHandlerCount, 1,
                       "exactly one live handler after handover")

        // The stale view's teardown must be a no-op against the new host.
        harness.runtime.detach(staleView, appModel: harness.source)
        XCTAssertEqual(harness.source.activeHandlerCount, 1,
                       "stale teardown must not disconnect the newer host")

        let before = harness.renderedCommands.count
        harness.perform(.spawn)
        XCTAssertGreaterThan(harness.renderedCommands.count, before,
                             "newer host must still receive and render commands")
    }

    // MARK: Pursuit snapshot restoration at trace level

    func testSnapshotRestorationMatrixAcrossAllPursuitStates() {
        let expectations: [(PursuitState, [String])] = [
            (.inactive, ["spawnCompanion"]),
            (.noticed, ["spawnCompanion", "spawnDiscovery"]),
            (.approaching, ["spawnCompanion", "spawnThreat"]),
            (.close, ["spawnCompanion", "spawnThreat"]),
            (.fading, ["spawnCompanion"]),
        ]
        for (pursuit, expectedKinds) in expectations {
            let harness = ARCommandReplayHarness()
            harness.attachFreshView()
            harness.perform(.snapshot(pursuit, nil))
            XCTAssertEqual(harness.renderedCommands.map(kindName),
                           expectedKinds,
                           "pursuit \(pursuit.rawValue) restored the wrong scene")
        }
    }

    // MARK: Transient cleanup ordering

    func testTransientDiscoveryIsRemovedBeforeUnrelatedSubsequentProjections() {
        let harness = ARCommandReplayHarness()
        harness.attachFreshView()
        harness.perform(.spawn)
        harness.perform(.event(.distantPresence, intensity: 0.3))
        let discoveryRemovalWatermark = harness.renderedCommands.count
        harness.perform(.event(.quietInterval, intensity: 0.1))
        let afterQuiet = harness.renderedCommands(after: discoveryRemovalWatermark)

        XCTAssertTrue(afterQuiet.contains(.removeEntity(CanonicalARWorldCommandMapper.discoveryID)),
                      "the transient discovery must be removed")
        let bondWatermark = harness.renderedCommands.count
        harness.perform(.event(.bondMoment, intensity: 0.6))
        let bondSegment = harness.renderedCommands(after: bondWatermark)
        XCTAssertFalse(bondSegment.contains { command in
            if case .spawnDiscovery = command { return true }
            return false
        }, "no stale discovery may leak into unrelated subsequent projections")
    }

    // MARK: Soak — bounded deferral over long sequences

    func testSoakBoundedPendingUnderPermanentDeferralFor500Iterations() {
        let harness = ARCommandReplayHarness()
        harness.policy = { _ in .deferred("permanent deferral soak") }
        harness.attachFreshView()
        harness.perform(.spawn)

        let iterations = 500
        for index in 0..<iterations {
            let kind: WorldEventKind = index.isMultiple(of: 2) ? .pursuitBegins : .pursuitIntensifies
            harness.perform(.event(kind, intensity: Double(index % 100) / 100))
            XCTAssertLessThanOrEqual(harness.runtime.pendingCommandSnapshot.count, 4,
                                     "pending work must stay bounded by stable identity")
        }

        let receipt = ReplaySoakReceipt(
            traceName: "pursuit-deferral-soak",
            iterations: iterations,
            renderedCommandCount: harness.renderedCommands.count,
            maxPendingObserved: harness.maxPendingObserved,
            deterministic: true
        )
        XCTAssertLessThanOrEqual(receipt.maxPendingObserved, 4)
        // Identity stability: at most one pending entry per semantic key.
        let pendingKinds = harness.runtime.pendingCommandSnapshot.map(kindName)
        XCTAssertEqual(pendingKinds.count, Set(pendingKinds).count,
                       "one pending slot per identity: \(pendingKinds)")
    }

    func testIdenticalSoaksProduceIdenticalReceiptsAndCommandStreams() {
        func soak() -> (commands: [ARWorldCommand], receipt: ReplaySoakReceipt) {
            let harness = ARCommandReplayHarness()
            harness.attachFreshView()
            harness.perform(.spawn)
            let iterations = 200
            for index in 0..<iterations {
                switch index % 4 {
                case 0: harness.perform(.event(.distantPresence, intensity: 0.3))
                case 1: harness.perform(.event(.pursuitBegins, intensity: 0.5))
                case 2: harness.perform(.event(.pursuitFades, intensity: 0.2))
                default: harness.perform(.behavior(.follow))
                }
            }
            harness.perform(.clear)
            return (harness.renderedCommands,
                    ReplaySoakReceipt(traceName: "mixed-soak",
                                      iterations: iterations,
                                      renderedCommandCount: harness.renderedCommands.count,
                                      maxPendingObserved: harness.maxPendingObserved,
                                      deterministic: true))
        }

        let first = soak()
        let second = soak()
        XCTAssertEqual(first.commands, second.commands)
        XCTAssertEqual(first.receipt, second.receipt)
        XCTAssertGreaterThan(first.receipt.renderedCommandCount, 400,
                             "soak must exercise a long command stream")
    }

    // MARK: Gameplay non-mutation under soak

    func testSoakDoesNotMutateCanonicalGameplayInputs() {
        var canonical = CompanionRuntime()
        canonical.apply(command: .setBehavior(CompanionBehaviorState.follow.rawValue))
        canonical.apply(command: .setRelativeDistance(1.8))
        let stateBefore = canonical.state
        let distanceBefore = canonical.relativeDistance

        let mapper = CanonicalARWorldCommandMapper(
            companionID: UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!,
            companionName: "Lira")
        let harness = ARCommandReplayHarness()
        harness.attachFreshView()
        let event = WorldEvent(kind: .pursuitIntensifies,
                               occurredAt: Date(timeIntervalSince1970: 1_800_000_000),
                               intensity: 0.7, debugLabel: "soak")

        for _ in 0..<500 {
            harness.runtime.receive(mapper.update(companionRuntime: canonical, event: event))
        }
        harness.runtime.receive(mapper.clear())

        XCTAssertEqual(canonical.state, stateBefore)
        XCTAssertEqual(canonical.relativeDistance, distanceBefore)
        XCTAssertEqual(event.kind, .pursuitIntensifies)
        XCTAssertEqual(event.intensity, 0.7)
    }

    // MARK: Helpers

    private func kindName(_ command: ARWorldCommand) -> String {
        switch command {
        case .spawnCompanion: return "spawnCompanion"
        case .updateCompanion: return "updateCompanion"
        case .spawnDiscovery: return "spawnDiscovery"
        case .spawnThreat: return "spawnThreat"
        case .updateThreat: return "updateThreat"
        case .removeEntity(let id):
            return id == CanonicalARWorldCommandMapper.discoveryID ? "removeDiscovery" : "removeEntity"
        case .clearSession: return "clearSession"
        }
    }
}
