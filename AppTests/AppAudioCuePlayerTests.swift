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

    func testMissingAssetUsesBoundedCacheDiagnostic() {
        let locator = MissingAssetLocator()
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        var diagnostics: [AudioPlaybackDiagnostic] = []
        let player = AppAudioCuePlayer(
            audioSession: session,
            assetLocator: locator,
            playerFactory: factory,
            diagnostic: { diagnostics.append($0) },
            notificationCenter: NotificationCenter()
        )

        player.handle([cue(.companionNear, priority: 2)])
        player.handle([cue(.companionNear, priority: 2)])

        XCTAssertEqual(locator.lookupCount, 1)
        XCTAssertEqual(diagnostics.filter { $0.kind == .assetMissing }.count, 1)
        XCTAssertEqual(diagnostics.filter { $0.reasonCode == .failedAssetCached }.count, 1)
    }

    func testSessionFailureIsDiagnosedWithoutCreatingAPlayer() {
        let session = TestAudioSession()
        session.configureError = TestAudioError.failure
        let factory = TestAudioPlayerFactory()
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)

        player.handle([cue(.companionNear, priority: 2)])

        XCTAssertEqual(session.configureCalls, 1)
        XCTAssertEqual(factory.makeCalls, 0)
        XCTAssertTrue(collector.values.contains { $0.kind == .audioSessionConfigurationFailed })
    }

    func testPlayerInitializationFailureIsDiagnosedAndCached() {
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        factory.makeError = TestAudioError.failure
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)

        player.handle([cue(.companionNear, priority: 2)])
        player.handle([cue(.companionNear, priority: 2)])

        XCTAssertEqual(factory.makeCalls, 1)
        XCTAssertEqual(collector.values.filter { $0.kind == .playerInitializationFailed }.count, 1)
        XCTAssertEqual(collector.values.filter { $0.reasonCode == .failedAssetCached }.count, 1)
    }

    func testPlayFalseAndActiveResultsAreDiagnosed() {
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let fake = TestAudioPlayer()
        factory.player = fake
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)

        fake.playResult = false
        player.handle([cue(.companionNear, priority: 2)])
        XCTAssertTrue(collector.values.contains { $0.kind == .playbackDidNotStart && $0.reasonCode == .playReturnedFalse })

        player.stopAll(fadeOut: false)
        fake.playResult = true
        fake.isPlaying = false
        player.handle([cue(.companionNear, priority: 2)])
        XCTAssertTrue(collector.values.contains { $0.kind == .playerObservedActive })
    }

    func testRouteMappingUsesCoarseExplicitCategories() {
        XCTAssertEqual(audioOutputRouteCategory(for: .builtInSpeaker), .builtInSpeaker)
        XCTAssertEqual(audioOutputRouteCategory(for: .builtInReceiver), .receiver)
        XCTAssertEqual(audioOutputRouteCategory(for: .headphones), .wiredHeadphones)
        XCTAssertEqual(audioOutputRouteCategory(for: .bluetoothA2DP), .bluetooth)
        XCTAssertEqual(audioOutputRouteCategory(for: .airPlay), .airPlay)
        XCTAssertEqual(audioOutputRouteCategory(for: .HDMI), .hdmi)
        XCTAssertEqual(audioOutputRouteCategory(for: .usbAudio), .usb)
        XCTAssertEqual(audioOutputRouteCategory(for: .lineIn), .other)
    }

    func testPauseResumeStopAndFadePreservePlaybackControl() async throws {
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let fake = TestAudioPlayer()
        factory.player = fake
        let player = makePlayer(session: session, factory: factory, notificationCenter: NotificationCenter())

        player.handle([cue(.companionNear, priority: 2)])
        player.pauseAll()
        XCTAssertEqual(fake.pauseCalls, 1)
        player.resumeAll()
        XCTAssertEqual(fake.playCalls, 2)
        player.stopAll(fadeOut: false)
        XCTAssertEqual(fake.stopCalls, 1)
        XCTAssertEqual(session.deactivateCalls, 1)

        player.handle([cue(.companionNear, priority: 2)])
        player.stopAll(fadeOut: true)
        XCTAssertEqual(fake.fadeCalls, 1)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(fake.stopCalls, 2)
    }

    func testResumeRequiresObservedActivePlayerAndSingleConfigurationFailure() {
        let emptyCollector = DiagnosticCollector()
        let emptyPlayer = makePlayer(
            session: TestAudioSession(),
            factory: TestAudioPlayerFactory(),
            collector: emptyCollector
        )
        emptyPlayer.resumeAll()
        XCTAssertFalse(emptyCollector.values.contains { $0.kind == .playbackResumed })

        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let fake = TestAudioPlayer()
        factory.player = fake
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)
        player.handle([cue(.companionNear, priority: 2)])
        player.pauseAll()
        session.configureError = TestAudioError.failure
        fake.playResult = false

        player.resumeAll()

        XCTAssertEqual(fake.playCalls, 2)
        XCTAssertFalse(collector.values.contains { $0.kind == .playbackResumed })
        XCTAssertEqual(
            collector.values.filter { $0.kind == .audioSessionConfigurationFailed }.count,
            1
        )
    }

    func testPauseAndStopRequireObservedInactivePlayers() async throws {
        let emptyCollector = DiagnosticCollector()
        let emptyPlayer = makePlayer(
            session: TestAudioSession(),
            factory: TestAudioPlayerFactory(),
            collector: emptyCollector
        )
        emptyPlayer.pauseAll()
        XCTAssertFalse(emptyCollector.values.contains { $0.kind == .playbackSuspended })

        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let stubborn = StubbornAudioPlayer()
        factory.player = stubborn
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)

        player.handle([cue(.companionNear, priority: 2)])
        player.pauseAll()
        XCTAssertFalse(collector.values.contains { $0.kind == .playbackSuspended })

        player.stopAll(fadeOut: false)
        XCTAssertFalse(collector.values.contains { $0.kind == .playbackStopped })

        player.handle([cue(.companionNear, priority: 2)])
        player.stopAll(fadeOut: true)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertFalse(collector.values.contains { $0.kind == .playbackStopped })
    }

    func testFadeAndStopDiagnosticsDistinguishRequestsFromObservedStop() async throws {
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let fake = TestAudioPlayer()
        factory.player = fake
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)

        player.handle([cue(.companionNear, priority: 2)])
        player.stopAll(fadeOut: true)

        XCTAssertTrue(collector.values.contains { $0.kind == .playbackFadeRequested })
        XCTAssertTrue(collector.values.contains { $0.kind == .playbackStopRequested })
        XCTAssertFalse(collector.values.contains { $0.kind == .playbackStopped })

        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(collector.values.contains { $0.kind == .playbackStopped })

        player.stopAll(fadeOut: false)
        XCTAssertEqual(
            collector.values.filter { $0.kind == .playbackStopRequested }.count,
            2
        )
    }

    func testDelegateCompletionAndDecodeCallbacksBecomeDiagnostics() {
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let fake = TestAudioPlayer()
        factory.player = fake
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: factory, collector: collector)

        player.handle([cue(.companionNear, priority: 2)])
        fake.finish(successfully: true)
        fake.decodeError()

        XCTAssertTrue(collector.values.contains { $0.kind == .playbackFinished })
        XCTAssertTrue(collector.values.contains { $0.kind == .playbackDecodeError && $0.reasonCode == .decodeError })
    }

    func testInterruptionAndRouteNotificationsAreCoarseAndReadOnly() async {
        let session = TestAudioSession()
        session.currentRouteCategory = .builtInSpeaker
        let center = NotificationCenter()
        let collector = DiagnosticCollector()
        let player = makePlayer(session: session, factory: TestAudioPlayerFactory(), collector: collector, notificationCenter: center)

        center.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ])
        center.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
            AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        ])
        center.post(name: AVAudioSession.routeChangeNotification, object: nil, userInfo: [
            AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
        ])
        await Task.yield()
        _ = player

        XCTAssertTrue(collector.values.contains { $0.kind == .playbackInterrupted })
        XCTAssertTrue(collector.values.contains { $0.kind == .playbackInterruptionEnded && $0.interruptionResumeDisposition == .shouldResume })
        XCTAssertTrue(collector.values.contains { $0.kind == .routeChanged && $0.routeCategory == .builtInSpeaker && $0.routeChangeReason == .newDeviceAvailable })
    }

    func testNotificationObserversAreRemovedWithAdapter() async {
        let center = NotificationCenter()
        let collector = DiagnosticCollector()
        weak var weakPlayer: AppAudioCuePlayer?

        do {
            let player = makePlayer(
                session: TestAudioSession(),
                factory: TestAudioPlayerFactory(),
                collector: collector,
                notificationCenter: center
            )
            weakPlayer = player
            XCTAssertNotNil(weakPlayer)
        }

        XCTAssertNil(weakPlayer)
        center.post(name: AVAudioSession.routeChangeNotification, object: nil, userInfo: [
            AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
        ])
        await Task.yield()
        XCTAssertTrue(collector.values.isEmpty)
    }

    func testDiagnosticHandlerInjectionAndCueOrderingDoNotChangePlayback() {
        let session = TestAudioSession()
        let factory = TestAudioPlayerFactory()
        let fake = TestAudioPlayer()
        factory.player = fake
        var firstHandler: [AudioPlaybackDiagnostic] = []
        var secondHandler: [AudioPlaybackDiagnostic] = []
        let player = AppAudioCuePlayer(
            audioSession: session,
            assetLocator: TestAssetLocator(),
            playerFactory: factory,
            diagnostic: { firstHandler.append($0) },
            notificationCenter: NotificationCenter()
        )
        player.setDiagnosticHandler { secondHandler.append($0) }

        player.handle([
            cue(.quietShift, priority: 1),
            cue(.companionNear, priority: 2)
        ])

        let receivedKinds = secondHandler
            .filter { $0.kind == .cueReceived }
            .compactMap(\.cueKind)
        XCTAssertEqual(receivedKinds, [.companionNear, .quietShift])
        XCTAssertTrue(firstHandler.isEmpty)
        XCTAssertEqual(fake.playCalls, 2)
    }

    func testDemoEmitsCuesAndEndSendsOneStop() throws {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let spy = AudioCuePlayerSpy()
        let model = WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            audioPlayer: spy,
            fieldTestReceiptStore: nil
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
            audioPlayer: spy,
            fieldTestReceiptStore: nil
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

    private func makePlayer(
        session: TestAudioSession,
        factory: TestAudioPlayerFactory,
        collector: DiagnosticCollector,
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> AppAudioCuePlayer {
        AppAudioCuePlayer(
            audioSession: session,
            assetLocator: TestAssetLocator(),
            playerFactory: factory,
            diagnostic: { collector.values.append($0) },
            notificationCenter: notificationCenter
        )
    }

    private func makePlayer(
        session: TestAudioSession,
        factory: TestAudioPlayerFactory,
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> AppAudioCuePlayer {
        AppAudioCuePlayer(
            audioSession: session,
            assetLocator: TestAssetLocator(),
            playerFactory: factory,
            diagnostic: { _ in },
            notificationCenter: notificationCenter
        )
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

@MainActor
private final class DiagnosticCollector {
    var values: [AudioPlaybackDiagnostic] = []
}

private enum TestAudioError: Error {
    case failure
}

@MainActor
private final class TestAudioSession: AudioSessionControlling {
    var currentRouteCategory: AudioOutputRouteCategory = .builtInSpeaker
    var configureError: Error?
    var activateError: Error?
    var configureCalls = 0
    var activateCalls = 0
    var deactivateCalls = 0

    func configureAmbientMixing() throws {
        configureCalls += 1
        if let configureError { throw configureError }
    }

    func activate() throws {
        activateCalls += 1
        if let activateError { throw activateError }
    }

    func deactivate() throws {
        deactivateCalls += 1
    }
}

@MainActor
private class TestAudioPlayer: AudioPlayerControlling {
    var isPlaying = false
    var numberOfLoops = 0
    var volume: Float = 1
    var pan: Float = 0
    var playResult = true
    var playCalls = 0
    var pauseCalls = 0
    var stopCalls = 0
    var fadeCalls = 0
    private var onFinished: (@MainActor (Bool) -> Void)?
    private var onDecodeError: (@MainActor () -> Void)?

    func prepareToPlay() {}

    func play() -> Bool {
        playCalls += 1
        if playResult { isPlaying = true }
        return playResult
    }

    func pause() {
        pauseCalls += 1
        isPlaying = false
    }

    func stop() {
        stopCalls += 1
        isPlaying = false
    }

    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
        self.volume = volume
        fadeCalls += 1
    }

    func setPlaybackCallbacks(
        onFinished: @escaping @MainActor (Bool) -> Void,
        onDecodeError: @escaping @MainActor () -> Void
    ) {
        self.onFinished = onFinished
        self.onDecodeError = onDecodeError
    }

    func finish(successfully: Bool) {
        isPlaying = false
        onFinished?(successfully)
    }

    func decodeError() {
        onDecodeError?()
    }
}

@MainActor
private final class StubbornAudioPlayer: TestAudioPlayer {
    override func pause() {
        pauseCalls += 1
    }

    override func stop() {
        stopCalls += 1
    }
}

@MainActor
private final class TestAudioPlayerFactory: AudioPlayerMaking {
    var player = TestAudioPlayer()
    var makeError: Error?
    var makeCalls = 0

    func makePlayer(contentsOf url: URL) throws -> any AudioPlayerControlling {
        makeCalls += 1
        if let makeError { throw makeError }
        return player
    }
}

private final class TestAssetLocator: AudioAssetLocating {
    func url(for descriptor: AudioAssetDescriptor) -> URL? {
        URL(fileURLWithPath: "/tmp/\(descriptor.assetName).\(descriptor.fileExtension)")
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
