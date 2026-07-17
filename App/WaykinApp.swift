import SwiftUI
import WaykinCore
import MapKit
import SwiftData
import AVFoundation

enum AppRoute: Hashable {
    case activeSession(DemoScenarioID)
    case summary(UUID)
    case memoryHistory
}

enum PersistenceLoadState: String, Equatable {
    case idle, loading, loaded, failed
}

enum RealWalkSessionState: Equatable {
    case idle
    case requestingPermission
    case active
    case paused
    case ending
    case completed
    case failed
}

@main
struct WaykinApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let container: ModelContainer
    @State private var appModel: WaykinAppModel

    init() {
        do {
            let isUITesting = ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING")
            var shouldReset = false
            let args = ProcessInfo.processInfo.arguments
            if let idx = args.firstIndex(of: "-WAYKIN_RESET_STATE"), idx + 1 < args.count {
            let val = args[idx + 1].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            shouldReset = (val == "YES" || val == "TRUE" || val == "1")
        }

            let container: ModelContainer
            if isUITesting {
                container = try PersistenceStore.makeFileBackedContainer(reset: shouldReset)
            } else {
                let url = try PersistenceConfiguration.persistentStoreURL()
                let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
                let config = ModelConfiguration(schema: schema, url: url)
                container = try ModelContainer(for: schema, configurations: config)
            }
            self.container = container

            let store = PersistenceStore(modelContainer: container)
            self._appModel = State(initialValue: WaykinAppModel(persistenceStore: store))
        } catch {
            // Fallback for non-critical paths; UI tests will fail explicitly if file-backed required
            let fallbackContainer = try! ModelContainer(for: CompanionRecord.self, SessionMemoryRecord.self)
            self.container = fallbackContainer
            self._appModel = State(initialValue: WaykinAppModel(persistenceStore: PersistenceStore(modelContainer: fallbackContainer)))
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appModel.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .activeSession(let scenario):
                            ActiveSessionView(scenario: scenario)
                        case .summary(let id):
                            if let summary = appModel.lastSummary, summary.id == id {
                                SessionSummaryView(summary: summary)
                            } else {
                                Text("Summary not found")
                            }
                        case .memoryHistory:
                            MemoryHistoryView()
                        }
                    }
            }
            .environment(appModel)
            .onChange(of: scenePhase) { _, phase in
                appModel.handleScenePhase(phase)
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                appModel.handleAudioSessionInterruption(notification)
            }
        }
        .modelContainer(container)
    }
}

@MainActor
@Observable
final class WaykinAppModel {
    let movementEngine: MovementEngine
    let persistenceStore: PersistenceStore
    let recommendationEngine = RecommendationEngine()
    let demoController: DemoSessionController
    let audioPlayer: any AudioCuePlaying
    let fieldTestReceiptStore: (any FieldTestReceiptStoring)?
    let fieldTestNow: @MainActor () -> Date

    let realLocationProvider: any RealLocationProviding

    var companion: Companion
    var activeRecommendation: ExperienceRecommendation?
    var lastSummary: SessionSummary?
    var lastClosingPhrase = ""
    var demoMessage = ""
    var selectedTimeContext: String = "day"
    var path = NavigationPath()

    // Diagnostics (UI-test only)
    var persistenceMode: String = "FILE_BACKED"
    var persistenceLoadState: PersistenceLoadState = .loaded
    var persistenceMemoryCount: Int = 0
    var lastSavedMemoryID: String = ""
    var persistenceStorePathHash: String = ""
    private(set) var latestFieldTestReceiptURL: URL?
    private(set) var fieldTestReceiptError: FieldTestReceiptStoreError?

    // Live real-session state (physical device)
    private(set) var realWalkState: RealWalkSessionState = .idle
    var isLiveSessionActive: Bool { realWalkState == .active || realWalkState == .paused }
    var liveSignalState: LiveLocationSignalState = .waitingForAuthorization
    var liveAcceptedCount: Int = 0
    var liveRejectedCount: Int = 0
    private var realExperienceState: ExperienceSessionState?
    private var realExperienceContext: ExperienceContext?
    private(set) var realCompanionRuntime = CompanionRuntime()
    private var lifecycleSuspendedRealWalk = false
    private var activeFieldTestReceipt: FieldTestReceiptBuilder?
    private var lastObservedMovementState: MovementState = .idle

    var activePresencePresentation: CompanionPresencePresentation {
        let usesPhysicalRuntime = isLiveSessionActive
        let walkState: CompanionWalkState? = if usesPhysicalRuntime {
            if case .companionWalk(let state) = realExperienceState?.runtimeState { state } else { nil }
        } else {
            demoController.companionWalkState
        }
        let session = movementEngine.currentSession
        let coordinate = session?.routePoints.last

        return CompanionPresencePresentation(
            companionName: companion.name,
            bondLevel: companion.bondLevel,
            behavior: usesPhysicalRuntime ? realCompanionRuntime.state : demoController.companionRuntime.state,
            pursuitState: walkState?.pursuitState ?? .inactive,
            eventKind: walkState?.lastEvent?.kind,
            audioCueKind: walkState?.activeAudioCues.first?.kind,
            elapsedSeconds: session?.elapsedTime ?? 0,
            distanceMeters: session?.distanceMeters ?? 0,
            isPaused: usesPhysicalRuntime ? realWalkState == .paused : demoController.isPaused,
            isOpening: usesPhysicalRuntime ? liveAcceptedCount == 0 : demoController.tickIndex == 0,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        )
    }

    init(
        persistenceStore: PersistenceStore,
        audioPlayer: (any AudioCuePlaying)? = nil,
        movementEngine: MovementEngine = MovementEngine(),
        realLocationProvider: any RealLocationProviding = RealLocationProvider(),
        fieldTestReceiptStore: (any FieldTestReceiptStoring)? = FileFieldTestReceiptStore.applicationSupport(),
        fieldTestNow: @escaping @MainActor () -> Date = Date.init
    ) {
        self.persistenceStore = persistenceStore
        self.movementEngine = movementEngine
        self.demoController = DemoSessionController(movementEngine: movementEngine)
        self.audioPlayer = audioPlayer ?? AppAudioCuePlayer()
        self.realLocationProvider = realLocationProvider
        self.fieldTestReceiptStore = fieldTestReceiptStore
        self.fieldTestNow = fieldTestNow

        var shouldReset = false
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-WAYKIN_RESET_STATE"), idx + 1 < args.count {
            let val = args[idx + 1].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            shouldReset = (val == "YES" || val == "TRUE" || val == "1")
        }

        if shouldReset {
            _ = try? persistenceStore.resetDemoData()
        }

        if let loaded = try? persistenceStore.loadCompanion() {
            self.companion = loaded
        } else {
            self.companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
            _ = try? persistenceStore.saveCompanion(self.companion)
        }
        persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0
        persistenceStorePathHash = String((try? PersistenceConfiguration.persistentStoreURL().path.hashValue) ?? 0)
        configureRealLocationCallbacks()
        refreshRecommendation()
    }

    func refreshRecommendation() {
        activeRecommendation = recommendationEngine.recommend(
            for: selectedTimeContext,
            lastExperience: companion.lastSessionID?.uuidString,
            activity: .walk
        ).first
    }

    func setTimeContext(_ context: String) {
        selectedTimeContext = context
        refreshRecommendation()
    }

    func startDemo(_ scenario: DemoScenarioID) {
        do {
            lastClosingPhrase = ""
            audioPlayer.stopAll(fadeOut: false)
            try demoController.start(scenarioID: scenario)
            if let session = movementEngine.currentSession, fieldTestReceiptStore != nil {
                let builder = FieldTestReceiptBuilder(
                    sessionID: session.id,
                    mode: .demo,
                    startedAt: session.startedAt,
                    startingBond: companion.bondLevel
                )
                builder.recordSessionTransition(from: .idle, to: .active, at: session.startedAt)
                activeFieldTestReceipt = builder
                lastObservedMovementState = session.movementState
            }
            demoMessage = "Walking with Lira..."
            path.append(AppRoute.activeSession(scenario))
        } catch {
            demoMessage = "Failed to start demo"
        }
    }

    func pauseDemo() {
        let wasRunning = demoController.isRunning && !demoController.isPaused
        demoController.pause()
        audioPlayer.pauseAll()
        if wasRunning {
            let now = fieldTestNow()
            activeFieldTestReceipt?.recordSessionTransition(from: .active, to: .paused, at: now)
            activeFieldTestReceipt?.recordAudioLifecycle("pause", at: now)
        }
    }

    func resumeDemo() {
        let wasPaused = demoController.isRunning && demoController.isPaused
        demoController.resume()
        audioPlayer.resumeAll()
        if wasPaused {
            let now = fieldTestNow()
            activeFieldTestReceipt?.recordSessionTransition(from: .paused, to: .active, at: now)
            activeFieldTestReceipt?.recordAudioLifecycle("resume", at: now)
        }
    }

    func advanceDemo() {
        let scenario = demoController.currentScenario
        let tickIndex = demoController.tickIndex
        demoController.advanceOneTick()
        if let scenario, tickIndex < scenario.ticks.count {
            let tick = scenario.ticks[tickIndex]
            let timestamp = movementEngine.currentSession?.routePoints.last?.timestamp ?? fieldTestNow()
            let snapshot = MovementSnapshot(
                timestamp: timestamp,
                speed: tick.speed,
                distanceDelta: max(0, tick.speed * tick.delta),
                isMoving: tick.speed > 0.1
            )
            activeFieldTestReceipt?.recordMovementSnapshot(snapshot)
            recordObservedMovementState(snapshot.isMoving ? .moving : .paused, at: timestamp)
        }
        if let event = demoController.currentEvent {
            activeFieldTestReceipt?.recordWorldEvent(event)
        }
        if let cue = demoController.currentAudioCue {
            activeFieldTestReceipt?.recordAudioCue(
                cue,
                at: movementEngine.currentSession?.routePoints.last?.timestamp ?? fieldTestNow()
            )
            audioPlayer.handle([cue])
        }
    }

    func runDemoToEnd() {
        guard let scenario = demoController.currentScenario else { return }
        while demoController.tickIndex < scenario.ticks.count {
            advanceDemo()
        }
    }

    func endDemo() {
        lastClosingPhrase = activePresencePresentation.closingPhrase
        let endedAt = fieldTestNow()
        let didCompleteScenario = demoController.currentScenario.map {
            demoController.tickIndex >= $0.ticks.count
        } ?? false
        audioPlayer.stopAll(fadeOut: true)
        activeFieldTestReceipt?.recordAudioLifecycle("stop", at: endedAt)
        let (session, result, summary) = demoController.end()
        guard let result = result, let summary = summary else {
            finishFieldTestReceipt(
                session: session,
                outcome: .invalidState,
                endingBond: companion.bondLevel,
                memoryWritten: false,
                persistence: .notAttempted,
                errorCategory: .invalidState,
                endedAt: endedAt
            )
            return
        }

        var updated = companion
        updated.bondLevel += result.bondDelta
        let mem = SessionMemory(sessionID: summary.sessionID, text: result.memoryText)

        do {
            let receipt = try persistenceStore.saveMemory(mem)
            try persistenceStore.saveCompanion(updated)
            updated.memories.append(mem)
            companion = updated
            lastSummary = summary
            lastSavedMemoryID = receipt.recordID.uuidString
            demoMessage = "Session ended: \(result.outcome). Bond +\(result.bondDelta)"
            persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0
            refreshRecommendation()
            path.append(AppRoute.summary(summary.id))
            finishFieldTestReceipt(
                session: session,
                outcome: didCompleteScenario ? .completed : .userEnded,
                endingBond: updated.bondLevel,
                memoryWritten: true,
                persistence: .succeeded,
                endedAt: endedAt
            )
        } catch {
            demoMessage = "Persistence failed: \(error)"
            persistenceLoadState = .failed
            finishFieldTestReceipt(
                session: session,
                outcome: .persistenceFailed,
                endingBond: companion.bondLevel,
                memoryWritten: false,
                persistence: .failed,
                errorCategory: .persistence,
                endedAt: endedAt
            )
        }
    }

    func returnHome() { path = NavigationPath() }

    // MARK: - Real physical walk support (COMPANION_WALK)
    func startRealCompanionWalk() {
        guard realWalkState == .idle || realWalkState == .completed || realWalkState == .failed else {
            demoMessage = "A walk is already in progress."
            return
        }
        if fieldTestReceiptStore != nil {
            activeFieldTestReceipt = FieldTestReceiptBuilder(
                sessionID: UUID(),
                mode: .physical,
                startedAt: fieldTestNow(),
                startingBond: companion.bondLevel
            )
        }
        guard realLocationProvider.locationServicesEnabled else {
            failRealWalk(
                message: "Location Services are unavailable. Demo Walk is still available.",
                outcome: .providerFailed,
                errorCategory: .locationServicesDisabled
            )
            return
        }

        switch realLocationProvider.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginAuthorizedRealWalk()
        case .notDetermined:
            realWalkState = .requestingPermission
            activeFieldTestReceipt?.recordSessionTransition(from: .idle, to: .requestingPermission, at: fieldTestNow())
            activeFieldTestReceipt?.recordPermission("notDetermined", at: fieldTestNow())
            liveSignalState = .waitingForAuthorization
            realLocationProvider.requestAuthorization()
        case .denied, .restricted:
            activeFieldTestReceipt?.recordPermission(
                realLocationProvider.authorizationStatus == .denied ? "denied" : "restricted",
                at: fieldTestNow()
            )
            failRealWalk(
                message: "Location access is required for a real walk. Demo Walk is still available.",
                outcome: .permissionDenied,
                errorCategory: .permissionDenied
            )
        @unknown default:
            failRealWalk(
                message: "Location authorization is unavailable. Demo Walk is still available.",
                outcome: .invalidState,
                errorCategory: .invalidState
            )
        }
    }

    private func beginAuthorizedRealWalk() {
        guard realWalkState != .active && realWalkState != .paused else { return }
        do {
            audioPlayer.stopAll(fadeOut: false)
            try movementEngine.startSession(activity: .walk, experienceID: "companion_walk")
            try movementEngine.resumeSession()
            if let session = movementEngine.currentSession {
                activeFieldTestReceipt?.attachSessionID(session.id)
                activeFieldTestReceipt?.recordSessionTransition(
                    from: realWalkState == .requestingPermission ? .requestingPermission : .idle,
                    to: .active,
                    at: session.startedAt
                )
                lastObservedMovementState = .idle
            }
            realLocationProvider.startUpdatingLocation()
            realWalkState = .active
            lifecycleSuspendedRealWalk = false
            liveSignalState = .waitingForFirstFix
            liveAcceptedCount = 0
            liveRejectedCount = 0
            let context = ExperienceContext(
                timeOfDay: selectedTimeContext,
                activity: .walk,
                bondLevel: companion.bondLevel
            )
            realExperienceContext = context
            realExperienceState = CompanionWalkExperience().start(context: context)
            realCompanionRuntime = CompanionRuntime()
            lastClosingPhrase = ""
            demoMessage = "Waiting for a reliable location fix..."
            path.append(AppRoute.activeSession(.calmDayWalk))
        } catch {
            failRealWalk(
                message: "The real walk could not start. Demo Walk is still available.",
                outcome: .invalidState,
                errorCategory: .invalidState
            )
        }
    }

    func pauseRealSession() {
        guard realWalkState == .active else { return }
        do {
            try movementEngine.pauseSession()
            realLocationProvider.stopUpdatingLocation()
            audioPlayer.pauseAll()
            let now = fieldTestNow()
            activeFieldTestReceipt?.recordSessionTransition(from: .active, to: .paused, at: now)
            activeFieldTestReceipt?.recordAudioLifecycle("pause", at: now)
            realWalkState = .paused
            lifecycleSuspendedRealWalk = false
        } catch {
            failRealWalk(message: "The real walk could not be paused safely.", outcome: .invalidState, errorCategory: .invalidState)
        }
    }

    func resumeRealSession() {
        guard realWalkState == .paused else { return }
        do {
            try movementEngine.resumeSession()
            realLocationProvider.startUpdatingLocation()
            liveSignalState = .waitingForFirstFix
            audioPlayer.resumeAll()
            let now = fieldTestNow()
            activeFieldTestReceipt?.recordSessionTransition(from: .paused, to: .active, at: now)
            activeFieldTestReceipt?.recordAudioLifecycle("resume", at: now)
            realWalkState = .active
            lifecycleSuspendedRealWalk = false
        } catch {
            failRealWalk(message: "The real walk could not resume safely.", outcome: .invalidState, errorCategory: .invalidState)
        }
    }

    func endRealSession() {
        guard isLiveSessionActive else { return }
        lastClosingPhrase = activePresencePresentation.closingPhrase
        let endedAt = fieldTestNow()
        activeFieldTestReceipt?.recordSessionTransition(from: fieldTestState(for: realWalkState), to: .ending, at: endedAt)
        realWalkState = .ending
        realLocationProvider.stopUpdatingLocation()
        audioPlayer.stopAll(fadeOut: true)
        activeFieldTestReceipt?.recordAudioLifecycle("stop", at: endedAt)
        let ended: MovementSession
        do {
            ended = try movementEngine.endSession()
        } catch {
            failRealWalk(
                message: "The real walk could not end cleanly.",
                outcome: .invalidState,
                errorCategory: .invalidState
            )
            return
        }

        realWalkState = .completed
        lifecycleSuspendedRealWalk = false
        realExperienceState = nil
        realExperienceContext = nil

        let summary = SessionSummary(
                id: UUID(),
                sessionID: ended.id,
                activity: ended.activityType,
                experience: ended.experienceID,
                variant: "physical_device_unverified",
                duration: ended.elapsedTime,
                activeTime: ended.activeTime,
                distanceMeters: ended.distanceMeters,
                averageSpeed: ended.averageSpeedMetersPerSecond,
                outcome: "COMPLETED",
                bondDelta: 1,
                memory: SessionMemory(sessionID: ended.id, text: "Lira stayed close during a real walk. Physical GPS and audio behavior remain unverified.")
        )
        lastSummary = summary

        let mem = SessionMemory(sessionID: summary.sessionID, text: summary.memory.text)
        do {
            let receipt = try persistenceStore.saveMemory(mem)
            lastSavedMemoryID = receipt.recordID.uuidString
            persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0

            path.append(AppRoute.summary(summary.id))
            finishFieldTestReceipt(
                session: ended,
                outcome: .userEnded,
                endingBond: companion.bondLevel,
                memoryWritten: true,
                persistence: .succeeded,
                endedAt: endedAt
            )
        } catch {
            demoMessage = "The walk ended, but its memory could not be saved."
            persistenceLoadState = .failed
            finishFieldTestReceipt(
                session: ended,
                outcome: .persistenceFailed,
                endingBond: companion.bondLevel,
                memoryWritten: false,
                persistence: .failed,
                errorCategory: .persistence,
                endedAt: endedAt
            )
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        activeFieldTestReceipt?.recordLifecycle(String(describing: phase), at: fieldTestNow())
        switch phase {
        case .active:
            if lifecycleSuspendedRealWalk && realWalkState == .paused {
                resumeRealSession()
            } else if shouldResumeAudio {
                audioPlayer.resumeAll()
            }
        case .inactive, .background:
            let wasActiveRealWalk = realWalkState == .active
            suspendRealWalkForLifecycle()
            if !wasActiveRealWalk {
                audioPlayer.pauseAll()
            }
        @unknown default:
            let wasActiveRealWalk = realWalkState == .active
            suspendRealWalkForLifecycle()
            if !wasActiveRealWalk {
                audioPlayer.pauseAll()
            }
        }
    }

    func handleAudioSessionInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        switch type {
        case .began:
            activeFieldTestReceipt?.recordInterruption("audioInterruptionBegan", at: fieldTestNow())
            activeFieldTestReceipt?.recordAudioLifecycle("pause", at: fieldTestNow())
            audioPlayer.pauseAll()
        case .ended:
            activeFieldTestReceipt?.recordInterruption("audioInterruptionEnded", at: fieldTestNow())
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume), shouldResumeAudio {
                activeFieldTestReceipt?.recordAudioLifecycle("resume", at: fieldTestNow())
                audioPlayer.resumeAll()
            }
        @unknown default:
            audioPlayer.pauseAll()
        }
    }

    private var shouldResumeAudio: Bool {
        let demoIsMoving = demoController.isRunning && !demoController.isPaused
        let realIsMoving = isLiveSessionActive && movementEngine.currentSession?.movementState == .moving
        return demoIsMoving || realIsMoving
    }

    private func configureRealLocationCallbacks() {
        realLocationProvider.onLocationSample = { [weak self] sample in
            guard let self, self.realWalkState == .active else { return }
            let result = self.movementEngine.ingestRealLocationSample(sample)
            self.activeFieldTestReceipt?.recordMovement(result.diagnostic)
            self.liveAcceptedCount = self.movementEngine.acceptedSampleCount
            self.liveRejectedCount = self.movementEngine.rejectedSampleCount

            guard let snapshot = result.snapshot,
                  let state = self.realExperienceState,
                  let context = self.realExperienceContext else { return }

            self.liveSignalState = .active
            self.demoMessage = "Walking with Lira..."
            let update = CompanionWalkExperience().update(
                previousState: state,
                movement: snapshot,
                context: context
            )
            self.realExperienceState = update.state
            update.companionCommands.forEach { self.realCompanionRuntime.apply(command: $0) }
            self.recordObservedMovementState(snapshot.isMoving ? .moving : .paused, at: snapshot.timestamp)
            if case .companionWalk(let walkState) = update.state.runtimeState {
                self.realCompanionRuntime.apply(event: walkState.lastEvent)
                if let event = walkState.lastEvent {
                    self.activeFieldTestReceipt?.recordWorldEvent(event)
                }
            }
            update.semanticAudioCues.forEach {
                self.activeFieldTestReceipt?.recordAudioCue($0, at: snapshot.timestamp)
            }
            self.audioPlayer.handle(update.semanticAudioCues)
        }

        realLocationProvider.onAuthorizationChange = { [weak self] status in
            guard let self else { return }
            self.activeFieldTestReceipt?.recordPermission(String(describing: status), at: self.fieldTestNow())
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.realWalkState == .requestingPermission {
                    self.beginAuthorizedRealWalk()
                }
            case .denied, .restricted:
                if self.realWalkState == .requestingPermission || self.isLiveSessionActive {
                    self.failRealWalk(
                        message: "Location access is required for a real walk. Demo Walk is still available.",
                        outcome: .permissionDenied,
                        errorCategory: .permissionDenied
                    )
                }
            case .notDetermined:
                break
            @unknown default:
                self.failRealWalk(
                    message: "Location authorization is unavailable. Demo Walk is still available.",
                    outcome: .invalidState,
                    errorCategory: .invalidState
                )
            }
        }

        realLocationProvider.onSignalStateChange = { [weak self] state in
            guard let self else { return }
            self.liveSignalState = state
            switch state {
            case .failed:
                self.activeFieldTestReceipt?.recordProviderFailure(.providerUnavailable, at: self.fieldTestNow())
                self.failRealWalk(
                    message: "Location became unavailable. The walk was stopped safely.",
                    outcome: .providerFailed,
                    errorCategory: .providerUnavailable
                )
            case .unavailable:
                if self.isLiveSessionActive {
                    self.activeFieldTestReceipt?.recordProviderFailure(.providerUnavailable, at: self.fieldTestNow())
                    self.failRealWalk(
                        message: "Location access is unavailable. The walk was stopped safely.",
                        outcome: .providerFailed,
                        errorCategory: .providerUnavailable
                    )
                }
            case .degraded:
                self.demoMessage = "Location signal is temporarily weak."
            case .waitingForAuthorization, .waitingForFirstFix, .active:
                break
            }
        }
    }

    private func suspendRealWalkForLifecycle() {
        guard realWalkState == .active else { return }
        do {
            try movementEngine.pauseSession()
            realLocationProvider.stopUpdatingLocation()
            audioPlayer.pauseAll()
            let now = fieldTestNow()
            activeFieldTestReceipt?.recordSessionTransition(from: .active, to: .paused, at: now)
            activeFieldTestReceipt?.recordAudioLifecycle("pause", at: now)
            realWalkState = .paused
            lifecycleSuspendedRealWalk = true
        } catch {
            failRealWalk(
                message: "The real walk was stopped safely after an interruption.",
                outcome: .interrupted,
                errorCategory: .invalidState
            )
        }
    }

    private func failRealWalk(
        message: String,
        outcome: FieldTestOutcome,
        errorCategory: FieldTestErrorCategory
    ) {
        let endedAt = fieldTestNow()
        let priorState = realWalkState
        realLocationProvider.stopUpdatingLocation()
        audioPlayer.stopAll(fadeOut: false)
        activeFieldTestReceipt?.recordAudioLifecycle("stop", at: endedAt)
        activeFieldTestReceipt?.recordSessionTransition(from: fieldTestState(for: priorState), to: .failed, at: endedAt)
        let endedSession: MovementSession?
        if movementEngine.currentSession != nil {
            endedSession = try? movementEngine.endSession()
        } else {
            endedSession = nil
        }
        realExperienceState = nil
        realExperienceContext = nil
        lifecycleSuspendedRealWalk = false
        realWalkState = .failed
        demoMessage = message
        finishFieldTestReceipt(
            session: endedSession,
            outcome: outcome,
            endingBond: companion.bondLevel,
            memoryWritten: false,
            persistence: .notAttempted,
            errorCategory: errorCategory,
            endedAt: endedAt
        )
    }

    private func recordObservedMovementState(_ state: MovementState, at timestamp: Date) {
        activeFieldTestReceipt?.recordMovementStateTransition(
            from: lastObservedMovementState,
            to: state,
            at: timestamp
        )
        lastObservedMovementState = state
    }

    private func finishFieldTestReceipt(
        session: MovementSession?,
        outcome: FieldTestOutcome,
        endingBond: Int,
        memoryWritten: Bool,
        persistence: FieldTestPersistenceResult,
        errorCategory: FieldTestErrorCategory? = nil,
        endedAt: Date
    ) {
        guard let builder = activeFieldTestReceipt else { return }
        activeFieldTestReceipt = nil
        let receipt = builder.finish(
            session: session,
            outcome: outcome,
            endingBond: endingBond,
            memoryWritten: memoryWritten,
            persistence: persistence,
            errorCategory: errorCategory,
            endedAt: endedAt
        )
        guard let fieldTestReceiptStore else { return }
        do {
            latestFieldTestReceiptURL = try fieldTestReceiptStore.save(receipt)
            fieldTestReceiptError = nil
        } catch let error as FieldTestReceiptStoreError {
            fieldTestReceiptError = error
        } catch {
            fieldTestReceiptError = .writeFailed
        }
    }

    private func fieldTestState(for state: RealWalkSessionState) -> FieldTestSessionState {
        switch state {
        case .idle: .idle
        case .requestingPermission: .requestingPermission
        case .active: .active
        case .paused: .paused
        case .ending: .ending
        case .completed: .completed
        case .failed: .failed
        }
    }
}


// MARK: - Views

struct HomeView: View {
    @Environment(WaykinAppModel.self) private var appModel
    @Query(sort: \SessionMemoryRecord.createdAt, order: .reverse)
    private var memoryRecords: [SessionMemoryRecord]

    var body: some View {
        VStack(spacing: 16) {
            Text("Waykin").font(.largeTitle.bold()).accessibilityIdentifier("waykin.home")
            Text("Companion: \(appModel.companion.name) • Bond \(appModel.companion.bondLevel)")

            if let lastMemory = memoryRecords.first {
                Text(lastMemory.text)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("waykin.memory.latest")
            }

            if !appModel.demoMessage.isEmpty {
                Text(appModel.demoMessage)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("waykin.status")
            }

            Button("Begin Walk") { appModel.startDemo(.calmDayWalk) }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("waykin.beginWalk")

            if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                Text("Demo Mode")
                    .font(.caption)
                    .accessibilityIdentifier("waykin.demo.mode")
            }

            Button("Memory History") { appModel.path.append(AppRoute.memoryHistory) }
                .accessibilityIdentifier("waykin.memory.open")

            // Real device entry point for physical validation (COMPANION_WALK)
            Button("Start Real Walk") {
                appModel.startRealCompanionWalk()
            }
            .accessibilityIdentifier("waykin.real.open")
            .accessibilityIdentifier("waykin.real.activity.walk")
            .accessibilityIdentifier("waykin.real.experience.companionWalk")

            if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location: \(appModel.realLocationProvider.authorizationStatus).description)")
                        .accessibilityIdentifier("waykin.location.authorization")
                    Text("Signal: \(appModel.liveSignalState).description)").accessibilityIdentifier("waykin.location.status")
                    Text("Live: \(appModel.isLiveSessionActive)").accessibilityIdentifier("waykin.session.live")
                        .accessibilityIdentifier("waykin.location.signalState")
                    Text("Accepted: \(appModel.liveAcceptedCount) Rejected: \(appModel.liveRejectedCount)")
                        .accessibilityIdentifier("waykin.location.acceptedCount")
                }
                .font(.caption2)
            }

            if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                VStack {
                    Text("Persistence: \(appModel.persistenceMode)").accessibilityIdentifier("waykin.persistence.mode")
                    Text("State: \(appModel.persistenceLoadState).description)").accessibilityIdentifier("waykin.persistence.state")
                    Text("MemCount: \(appModel.persistenceMemoryCount)").accessibilityIdentifier("waykin.persistence.queryMemoryCount")
                    Text("PathHash: \(appModel.persistenceStorePathHash)").accessibilityIdentifier("waykin.persistence.storePathHash")
                }.font(.caption2)
            }
        }.padding()
    }
}

struct ActiveSessionView: View {
    @Environment(WaykinAppModel.self) private var appModel
    let scenario: DemoScenarioID

    var body: some View {
        let presentation = appModel.activePresencePresentation

        ZStack {
            CompanionPresenceStyle.background(for: presentation.pressureIntensity)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: CompanionPresenceStyle.sectionSpacing) {
                    CompanionPresenceView(presentation: presentation)

                    HStack(spacing: 12) {
                        if presentation.isPaused {
                            Button {
                                appModel.isLiveSessionActive ? appModel.resumeRealSession() : appModel.resumeDemo()
                            } label: {
                                Label("Resume", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("waykin.session.resume")
                        } else {
                            Button {
                                appModel.isLiveSessionActive ? appModel.pauseRealSession() : appModel.pauseDemo()
                            } label: {
                                Label("Pause", systemImage: "pause.fill")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("waykin.session.pause")
                        }

                        Button(role: .destructive) {
                            appModel.isLiveSessionActive ? appModel.endRealSession() : appModel.endDemo()
                        } label: {
                            Label("End", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("waykin.session.end")
                    }

                    if !appModel.isLiveSessionActive {
                        Button("Run to End") { appModel.runDemoToEnd() }
                            .font(.caption)
                            .accessibilityIdentifier("waykin.session.runToEnd")
                    } else {
                        Text("Signal: \(appModel.liveSignalState).description)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("waykin.session.liveSignal")
                    }

                    CompactSessionMap(
                        latitude: presentation.latitude,
                        longitude: presentation.longitude
                    )
                }
                .padding(.horizontal, CompanionPresenceStyle.horizontalPadding)
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    @Environment(WaykinAppModel.self) private var appModel

    var body: some View {
        VStack {
            Text("Session Summary").font(.title).accessibilityIdentifier("waykin.summary.screen")
            if !appModel.lastClosingPhrase.isEmpty {
                Text(appModel.lastClosingPhrase)
                    .font(.headline)
                    .accessibilityIdentifier("waykin.session.closing")
            }
            Text(summary.memory.text).accessibilityIdentifier("waykin.summary.memory")
            Button("Back to Home") { appModel.returnHome() }.accessibilityIdentifier("waykin.summary.home")
        }.padding()
    }
}

// MARK: - Dedicated Memory Row for stable XCUI identity
struct MemoryRowView: View {
    let record: SessionMemoryRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.text)
                .accessibilityIdentifier("waykin.memory.text.\(record.id.uuidString)")

            if let scenario = record.scenarioID {
                Text(scenario)
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("waykin.memory.item.\(record.id.uuidString)")
        .accessibilityValue(record.id.uuidString)
    }
}

// MARK: - Query-backed MemoryHistoryView (canonical source)
struct MemoryHistoryView: View {
    @Environment(WaykinAppModel.self) private var appModel
    @Query(sort: \SessionMemoryRecord.createdAt, order: .reverse)
    private var memoryRecords: [SessionMemoryRecord]

    private var queryState: String {
        memoryRecords.isEmpty ? "EMPTY" : "POPULATED"
    }

    var body: some View {
        VStack {
            Text("Memory History")
                .font(.title)
                .accessibilityIdentifier("waykin.memory.screen")

            if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                Text(String(memoryRecords.count))
                    .accessibilityIdentifier("waykin.persistence.queryMemoryCount")
                Text(memoryRecords.map { $0.id.uuidString }.joined(separator: ","))
                    .accessibilityIdentifier("waykin.persistence.queryMemoryIDs")
                Text(queryState)
                    .accessibilityIdentifier("waykin.memory.queryState")
                Text(appModel.persistenceStorePathHash)
                    .accessibilityIdentifier("waykin.persistence.storePathHash")
            }

            if memoryRecords.isEmpty {
                Text("No memories yet")
                    .accessibilityIdentifier("waykin.memory.empty")
            } else {
                List(memoryRecords) { rec in
                    MemoryRowView(record: rec)
                }
            }
        }
        .padding()
    }
}
