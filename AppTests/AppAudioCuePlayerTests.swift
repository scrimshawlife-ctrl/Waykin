import AVFoundation
import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class AppAudioCuePlayerTests: XCTestCase {
    func testCatalogMapsEverySupportedCue() {
        let expected: [AudioCueKind: (String, Int, AudioPlaybackChannel)] = [
            .companionNear: ("companion_near", 2, .foreground),
            .companionAhead: ("companion_ahead", 2, .foreground),
            .distantFootsteps: ("distant_presence", 3, .foreground),
            .pursuitPressure: ("pursuit_pressure", 4, .foreground),
            .pursuitRelease: ("pursuit_release", 3, .foreground),
            .bondMotif: ("bond_motif", 5, .foreground),
            .quietShift: ("quiet_shift", 1, .ambient)
        ]

        XCTAssertEqual(Set(expected.keys), Set(AudioCueKind.allCases))
        for (kind, mapping) in expected {
            let descriptor = AudioCueAssetCatalog.descriptor(for: kind)
            XCTAssertEqual(descriptor?.assetName, mapping.0)
            XCTAssertEqual(descriptor?.priority, mapping.1)
            XCTAssertEqual(descriptor?.channel, mapping.2)
            XCTAssertEqual(descriptor?.fileExtension, "wav")
        }
        XCTAssertNil(AudioCueAssetCatalog.descriptor(forRawValue: "malformed"))
    }

    func testEveryBundledAssetCanInitializeAPlayer() throws {
        let locator = BundleAudioAssetLocator(bundle: .main)

        for kind in AudioCueKind.allCases {
            let descriptor = try XCTUnwrap(AudioCueAssetCatalog.descriptor(for: kind))
            let url = try XCTUnwrap(locator.url(for: descriptor), "Missing bundled asset for \(kind.rawValue)")
            XCTAssertNoThrow(try AVAudioPlayer(contentsOf: url))
        }
    }

    func testPlannerEnforcesPriorityDeduplicationAndForegroundBound() {
        var planner = AudioCuePlaybackPlanner()

        XCTAssertEqual(planner.decision(for: cue(.companionNear, priority: 2)), .play(AudioCueAssetCatalog.descriptor(for: .companionNear)!, replacingActiveCue: false))
        XCTAssertEqual(planner.decision(for: cue(.companionNear, priority: 2)), .ignoreDuplicate)
        XCTAssertEqual(planner.decision(for: cue(.pursuitPressure, priority: 4)), .play(AudioCueAssetCatalog.descriptor(for: .pursuitPressure)!, replacingActiveCue: true))
        XCTAssertEqual(planner.decision(for: cue(.companionAhead, priority: 2)), .ignoreLowerPriority)
        XCTAssertEqual(planner.decision(for: cue(.quietShift, priority: 1)), .play(AudioCueAssetCatalog.descriptor(for: .quietShift)!, replacingActiveCue: false))
    }

    func testPlannerLifecycleIsExplicit() {
        var planner = AudioCuePlaybackPlanner()
        _ = planner.decision(for: cue(.bondMotif, priority: 5))

        planner.pause()
        XCTAssertTrue(planner.isPaused)
        XCTAssertEqual(planner.decision(for: cue(.quietShift, priority: 1)), .ignoreWhilePaused)

        planner.resume()
        XCTAssertFalse(planner.isPaused)
        planner.stop()
        XCTAssertEqual(planner.decision(for: cue(.companionNear, priority: 2)), .play(AudioCueAssetCatalog.descriptor(for: .companionNear)!, replacingActiveCue: false))
    }

    func testMissingAssetIsAttemptedAndDiagnosedOnlyOnce() {
        let locator = MissingAssetLocator()
        var diagnostics: [String] = []
        let player = AppAudioCuePlayer(assetLocator: locator) { diagnostics.append($0) }
        let missingCue = cue(.companionNear, priority: 2)

        player.handle([missingCue])
        player.handle([missingCue])

        XCTAssertEqual(locator.lookupCount, 1)
        XCTAssertEqual(diagnostics.count, 1)
        XCTAssertTrue(diagnostics[0].contains("companion_near.wav"))
    }

    func testDemoEmitsCuesAndEndSendsOneStop() throws {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let spy = AudioCuePlayerSpy()
        let model = WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            audioPlayer: spy
        )

        model.startDemo(.calmDayWalk)
        spy.stopCalls = 0
        model.runDemoToEnd()
        model.endDemo()

        XCTAssertFalse(spy.handledCues.isEmpty)
        XCTAssertEqual(spy.stopCalls, 1)
        XCTAssertTrue(spy.lastStopFaded)
    }

    func testPauseResumeAndInterruptionForwardToPlayer() throws {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let spy = AudioCuePlayerSpy()
        let model = WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            audioPlayer: spy
        )
        model.startDemo(.calmDayWalk)

        model.pauseDemo()
        model.resumeDemo()
        model.handleScenePhase(.inactive)
        model.handleScenePhase(.active)
        model.handleAudioSessionInterruption(Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        ))
        model.handleAudioSessionInterruption(Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        ))

        XCTAssertEqual(spy.pauseCalls, 3)
        XCTAssertEqual(spy.resumeCalls, 3)
    }

    private func cue(_ kind: AudioCueKind, priority: Int) -> AudioCue {
        AudioCue(
            kind: kind,
            intensity: 0.7,
            priority: priority,
            cooldownGroup: kind.rawValue,
            shouldFade: true,
            debugLabel: kind.rawValue
        )
    }
}

private final class MissingAssetLocator: AudioAssetLocating {
    var lookupCount = 0

    func url(for descriptor: AudioAssetDescriptor) -> URL? {
        lookupCount += 1
        return nil
    }
}

@MainActor
private final class AudioCuePlayerSpy: AudioCuePlaying {
    var handledCues: [AudioCue] = []
    var pauseCalls = 0
    var resumeCalls = 0
    var stopCalls = 0
    var lastStopFaded = false

    func handle(_ cues: [AudioCue]) { handledCues.append(contentsOf: cues) }
    func pauseAll() { pauseCalls += 1 }
    func resumeAll() { resumeCalls += 1 }
    func stopAll(fadeOut: Bool) {
        stopCalls += 1
        lastStopFaded = fadeOut
    }
}
