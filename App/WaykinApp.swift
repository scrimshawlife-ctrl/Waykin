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
            .wkThemed()
            .liraSkin(appModel.selectedLiraSkin)
            .preferredColorScheme(appModel.appearancePreference.preferredColorScheme)
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
final class WaykinAppModel: CanonicalARCommandSource {
    let movementEngine: MovementEngine
    let persistenceStore: PersistenceStore
    let recommendationEngine = RecommendationEngine()
    let demoController: DemoSessionController
    let audioPlayer: any AudioCuePlaying
    let fieldTestReceiptStore: (any FieldTestReceiptStoring)?
    let fieldTestNow: @MainActor () -> Date

    let realLocationProvider: any RealLocationProviding
    let pathProgressEngine = PathProgressEngine()
    let healthMetricsProvider: any HealthMetricsProviding
    /// Glasses glance presentation surface (#115). Default-off Null adapter.
    let glassesGlanceAdapter: any GlassesGlanceAdapter

    var companion: Companion
    var activeRecommendation: ExperienceRecommendation?
    var lastSummary: SessionSummary?
    var lastClosingPhrase = ""
    var demoMessage = ""
    var selectedTimeContext: String = "day"
    /// Cosmetic Lira skin (Dawn default). Materials only — no unlock economy.
    var selectedLiraSkin: LiraSkin = .dawn {
        didSet { UserDefaults.standard.set(selectedLiraSkin.rawValue, forKey: LiraSkin.storageKey) }
    }
    /// Appearance force for Echo day/night (system default).
    var appearancePreference: AppearancePreference = .system {
        didSet { UserDefaults.standard.set(appearancePreference.rawValue, forKey: AppearancePreference.storageKey) }
    }
    var path = NavigationPath()
    var showsSettings = false

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
    /// Presentation-only breadcrumb of the current real walk (#121):
    /// derived from accepted movement fixes, capped, reset per session,
    /// never persisted.
    private(set) var walkPathTrace = WalkPathTrace()
    var liveAcceptedCount: Int = 0
    var liveRejectedCount: Int = 0
    /// Semantic path progress (demo + real). No coordinates.
    private(set) var pathProgress: PathProgressSnapshot = .empty
    /// Optional HealthKit enrichment; empty in Demo Mode / deny / unavailable.
    private(set) var activityEnrichment: ActivityEnrichment = .empty
    private var realExperienceState: ExperienceSessionState?
    private var realExperienceContext: ExperienceContext?
    /// Test seam for HealthKit ordering / energy apply (#104).
    var test_realExperienceContext: ExperienceContext? { realExperienceContext }
    private(set) var realCompanionRuntime = CompanionRuntime()
    @ObservationIgnored private var arWorldCommandHandler: (([ARWorldCommand]) -> Void)?
    @ObservationIgnored private var arWorldCommandHandlerOwner: UUID?
    private var lifecycleSuspendedRealWalk = false
    /// Cancels in-flight / periodic HealthKit refresh when walk pauses or ends (#104).
    @ObservationIgnored private var healthRefreshGeneration: UInt64 = 0
    @ObservationIgnored private var healthRefreshTask: Task<Void, Never>?
    /// Bounded periodic re-query interval while a real walk is active.
    static let healthRefreshIntervalNanoseconds: UInt64 = 120_000_000_000
    private var activeFieldTestReceipt: FieldTestReceiptBuilder?
    private var lastObservedMovementState: MovementState = .idle
    /// Wall-clock pause accounting for **presentation** elapsed (#128). Core `session.elapsedTime` stays sample-driven.
    @ObservationIgnored private var accumulatedRealPausedDuration: TimeInterval = 0
    @ObservationIgnored private var currentRealPauseStartedAt: Date?
    /// Presentation start (fieldTestNow), not MovementEngine.startedAt, so HUD clock is continuous even when GPS samples are sparse.
    @ObservationIgnored private var presentationSessionStartedAt: Date?
    /// Path soft-audio coupling (#140): last relation and session elapsed when path cue accepted.
    @ObservationIgnored private var lastPathRelationForAudio: PathRelation = .establishing
    @ObservationIgnored private var lastPathAudioElapsed: TimeInterval?

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
            elapsedSeconds: presentationElapsedSeconds(session: session, usesPhysicalRuntime: usesPhysicalRuntime),
            distanceMeters: session?.distanceMeters ?? 0,
            isPaused: usesPhysicalRuntime ? realWalkState == .paused : demoController.isPaused,
            isOpening: usesPhysicalRuntime ? liveAcceptedCount == 0 : demoController.tickIndex == 0,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            pathRelation: pathProgress.relation,
            pathIntegrityPressure: pathProgress.integrityPressure,
            energyHint: activityEnrichment.energyHint
        )
    }

    /// Smooth HUD clock for real walks (wall time − pauses). Demo keeps sample/tick elapsed.
    func presentationElapsedSeconds(
        session: MovementSession? = nil,
        usesPhysicalRuntime: Bool? = nil,
        now: Date? = nil
    ) -> TimeInterval {
        let session = session ?? movementEngine.currentSession
        let physical = usesPhysicalRuntime ?? isLiveSessionActive
        let now = now ?? fieldTestNow()
        guard physical, session != nil, let started = presentationSessionStartedAt else {
            return session?.elapsedTime ?? 0
        }
        var paused = accumulatedRealPausedDuration
        if realWalkState == .paused, let pauseStart = currentRealPauseStartedAt {
            paused += max(0, now.timeIntervalSince(pauseStart))
        }
        return max(0, now.timeIntervalSince(started) - paused)
    }

    private func resetPresentationElapsedClock() {
        accumulatedRealPausedDuration = 0
        currentRealPauseStartedAt = nil
        presentationSessionStartedAt = nil
    }

    private func beginPresentationPause(at now: Date) {
        currentRealPauseStartedAt = now
    }

    private func endPresentationPause(at now: Date) {
        if let pauseStart = currentRealPauseStartedAt {
            accumulatedRealPausedDuration += max(0, now.timeIntervalSince(pauseStart))
        }
        currentRealPauseStartedAt = nil
    }

    init(
        persistenceStore: PersistenceStore,
        audioPlayer: (any AudioCuePlaying)? = nil,
        movementEngine: MovementEngine = MovementEngine(),
        realLocationProvider: any RealLocationProviding = RealLocationProvider(),
        healthMetricsProvider: (any HealthMetricsProviding)? = nil,
        glassesGlanceAdapter: (any GlassesGlanceAdapter)? = nil,
        fieldTestReceiptStore: (any FieldTestReceiptStoring)? = FileFieldTestReceiptStore.applicationSupport(),
        fieldTestNow: @escaping @MainActor () -> Date = Date.init
    ) {
        self.persistenceStore = persistenceStore
        self.movementEngine = movementEngine
        self.demoController = DemoSessionController(movementEngine: movementEngine)
        self.audioPlayer = audioPlayer ?? AppAudioCuePlayer()
        self.realLocationProvider = realLocationProvider
        // UI tests / default: null provider so Demo Mode never depends on HealthKit.
        if let healthMetricsProvider {
            self.healthMetricsProvider = healthMetricsProvider
        } else if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
            self.healthMetricsProvider = NullHealthMetricsProvider()
        } else {
            self.healthMetricsProvider = HealthKitMetricsProvider()
        }
        // Glasses glance: default-off; prefer mock when UI testing so no Meta claims.
        if let glassesGlanceAdapter {
            self.glassesGlanceAdapter = glassesGlanceAdapter
        } else if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
            self.glassesGlanceAdapter = GlassesGlanceAdapterFactory.make(
                enabled: GlassesGlanceFeature.isEnabled,
                preferMockTransport: true
            )
        } else {
            self.glassesGlanceAdapter = GlassesGlanceAdapterFactory.make()
        }
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
            UserDefaults.standard.removeObject(forKey: LiraSkin.storageKey)
            UserDefaults.standard.removeObject(forKey: AppearancePreference.storageKey)
        }

        if let loaded = try? persistenceStore.loadCompanion() {
            self.companion = loaded
        } else {
            self.companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
            _ = try? persistenceStore.saveCompanion(self.companion)
        }
        if shouldReset {
            self.selectedLiraSkin = .dawn
            self.appearancePreference = .system
        } else if let raw = UserDefaults.standard.string(forKey: LiraSkin.storageKey),
                  let skin = LiraSkin(rawValue: raw) {
            self.selectedLiraSkin = skin
        } else {
            self.selectedLiraSkin = .dawn
        }
        if !shouldReset,
           let raw = UserDefaults.standard.string(forKey: AppearancePreference.storageKey),
           let appearance = AppearancePreference(rawValue: raw) {
            self.appearancePreference = appearance
        } else if !shouldReset {
            self.appearancePreference = .system
        }
        persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0
        persistenceStorePathHash = String((try? PersistenceConfiguration.persistentStoreURL().path.hashValue) ?? 0)
        if let appAudioPlayer = self.audioPlayer as? AppAudioCuePlayer {
            appAudioPlayer.setDiagnosticHandler { [weak self] diagnostic in
                self?.activeFieldTestReceipt?.recordAudioDiagnostic(diagnostic)
            }
        }
        configureRealLocationCallbacks()
        refreshRecommendation()
    }

    /// Home-stage presentation: Lira in guide pose for presence (not a live session).
    var homePresencePresentation: CompanionPresencePresentation {
        CompanionPresencePresentation(
            companionName: companion.name,
            bondLevel: companion.bondLevel,
            behavior: .follow,
            pursuitState: .inactive,
            eventKind: nil,
            audioCueKind: nil,
            elapsedSeconds: 0,
            distanceMeters: 0,
            isPaused: false,
            isOpening: false,
            latitude: nil,
            longitude: nil
        )
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
            pathProgressEngine.reset(isDemo: true)
            pathProgress = pathProgressEngine.snapshot
            lastPathRelationForAudio = pathProgress.relation
            lastPathAudioElapsed = nil
            activityEnrichment = .empty
            try demoController.start(scenarioID: scenario)
            emitARWorldCommands(arCommandMapper.spawn(
                companionRuntime: demoController.companionRuntime
            ))
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
            Task { await self.startGlassesGlanceSession() }
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
        publishGlassesGlance()
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
        publishGlassesGlance()
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
            pathProgressEngine.recordAccepted(snapshot)
            pathProgress = pathProgressEngine.snapshot
            activeFieldTestReceipt?.recordMovementSnapshot(snapshot)
            recordObservedMovementState(snapshot.isMoving ? .moving : .paused, at: timestamp)
        }
        if let event = demoController.currentEvent {
            activeFieldTestReceipt?.recordWorldEvent(event)
        }
        var playedEventOrBehaviorCue = false
        if let cue = demoController.currentAudioCue {
            activeFieldTestReceipt?.recordAudioCue(
                cue,
                at: movementEngine.currentSession?.routePoints.last?.timestamp ?? fieldTestNow()
            )
            audioPlayer.handle([cue])
            playedEventOrBehaviorCue = true
        }
        if !playedEventOrBehaviorCue {
            playPathSoftAudioIfNeeded(
                pursuitState: demoController.companionWalkState?.pursuitState ?? .inactive,
                sessionElapsed: movementEngine.currentSession?.elapsedTime ?? Double(demoController.tickIndex),
                at: movementEngine.currentSession?.routePoints.last?.timestamp ?? fieldTestNow()
            )
        } else {
            lastPathRelationForAudio = pathProgress.relation
        }
        if let scenario, tickIndex < scenario.ticks.count {
            emitARWorldCommands(arCommandMapper.update(
                companionRuntime: demoController.companionRuntime,
                event: demoController.currentEvent,
                pursuitState: demoController.companionWalkState?.pursuitState ?? .inactive,
                pathRelation: pathProgress.relation,
                pathIntegrityPressure: pathProgress.integrityPressure
            ))
        }
        publishGlassesGlance()
    }

    func runDemoToEnd() {
        guard let scenario = demoController.currentScenario else { return }
        while demoController.tickIndex < scenario.ticks.count {
            advanceDemo()
        }
    }

    func endDemo() {
        emitARWorldCommands(arCommandMapper.clear())
        endGlassesGlanceSession()
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
        let surfacedMemoryText = WalkPathCopy.appendingMemorySuffix(
            to: result.memoryText,
            relation: pathProgress.relation
        )
        let surfacedSummary = summary.withWalkSurfacing(
            path: pathProgress,
            enrichment: activityEnrichment,
            memoryText: surfacedMemoryText
        )
        let mem = SessionMemory(sessionID: surfacedSummary.sessionID, text: surfacedMemoryText)

        do {
            let receipt = try persistenceStore.saveMemory(mem)
            try persistenceStore.saveCompanion(updated)
            updated.memories.append(mem)
            companion = updated
            lastSummary = surfacedSummary
            lastSavedMemoryID = receipt.recordID.uuidString
            demoMessage = "Session ended: \(result.outcome). Bond +\(result.bondDelta)"
            persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0
            refreshRecommendation()
            path.append(AppRoute.summary(surfacedSummary.id))
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
        walkPathTrace.reset()
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
            pathProgressEngine.reset(isDemo: false)
            pathProgress = pathProgressEngine.snapshot
            lastPathRelationForAudio = pathProgress.relation
            lastPathAudioElapsed = nil
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
            resetPresentationElapsedClock()
            presentationSessionStartedAt = fieldTestNow()
            // Context must exist before async Health enrichment can apply energy (#104 race).
            let context = ExperienceContext(
                timeOfDay: selectedTimeContext,
                activity: .walk,
                bondLevel: companion.bondLevel
            )
            realExperienceContext = context
            realExperienceState = CompanionWalkExperience().start(context: context)
            realCompanionRuntime = CompanionRuntime()
            emitARWorldCommands(arCommandMapper.spawn(companionRuntime: realCompanionRuntime))
            lastClosingPhrase = ""
            demoMessage = "Waiting for a reliable location fix..."
            path.append(AppRoute.activeSession(.calmDayWalk))
            scheduleHealthRefreshForRealWalk(periodic: true)
            Task { await self.startGlassesGlanceSession() }
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
            beginPresentationPause(at: now)
            realWalkState = .paused
            lifecycleSuspendedRealWalk = false
            cancelHealthRefresh()
            publishGlassesGlance()
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
            endPresentationPause(at: now)
            realWalkState = .active
            lifecycleSuspendedRealWalk = false
            scheduleHealthRefreshForRealWalk(periodic: true)
            publishGlassesGlance()
        } catch {
            failRealWalk(message: "The real walk could not resume safely.", outcome: .invalidState, errorCategory: .invalidState)
        }
    }

    func endRealSession() {
        guard isLiveSessionActive else { return }
        cancelHealthRefresh()
        endGlassesGlanceSession()
        emitARWorldCommands(arCommandMapper.clear())
        lastClosingPhrase = activePresencePresentation.closingPhrase
        let endedAt = fieldTestNow()
        if realWalkState == .paused {
            endPresentationPause(at: endedAt)
        }
        activeFieldTestReceipt?.recordSessionTransition(from: fieldTestState(for: realWalkState), to: .ending, at: endedAt)
        realWalkState = .ending
        resetPresentationElapsedClock()
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

        let experienceResult = realExperienceState.map {
            CompanionWalkExperience().finish(state: $0, session: ended)
        }
        let physicalBondDelta = 1
        let baseMemoryText = experienceResult?.memoryText
            ?? "Lira stayed close during a quiet \(Int(ended.distanceMeters))m walk."
        let memoryText = WalkPathCopy.appendingMemorySuffix(
            to: baseMemoryText,
            relation: pathProgress.relation
        )
        var updatedCompanion = companion
        updatedCompanion.bondLevel += physicalBondDelta

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
            bondDelta: physicalBondDelta,
            memory: SessionMemory(sessionID: ended.id, text: memoryText),
            pathRelation: pathProgress.relation.rawValue,
            pathMetersAlongPath: pathProgress.metersAlongPath,
            activityCadenceBand: activityEnrichment.stepCadenceBand == .unknown
                ? nil
                : activityEnrichment.stepCadenceBand.rawValue
        )
        lastSummary = summary

        let mem = SessionMemory(sessionID: summary.sessionID, text: summary.memory.text)
        do {
            let receipt = try persistenceStore.saveMemory(mem)
            try persistenceStore.saveCompanion(updatedCompanion)
            companion = updatedCompanion
            lastSavedMemoryID = receipt.recordID.uuidString
            persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0

            path.append(AppRoute.summary(summary.id))
            finishFieldTestReceipt(
                session: ended,
                outcome: .userEnded,
                endingBond: updatedCompanion.bondLevel,
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

            if let snapshot = result.snapshot {
                self.pathProgressEngine.recordAccepted(snapshot)
                if let point = self.movementEngine.currentSession?.routePoints.last {
                    self.walkPathTrace.append(latitude: point.latitude, longitude: point.longitude)
                }
            } else if result.diagnostic.disposition != .awaitingFreshAnchor {
                self.pathProgressEngine.recordRejected()
            }
            self.pathProgress = self.pathProgressEngine.snapshot
            self.publishGlassesGlance()

            // Path soft audio can fire on reject-only ticks (GPS strain) without a world update (#140).
            let pursuitForPath: PursuitState = {
                if case .companionWalk(let walk) = self.realExperienceState?.runtimeState {
                    return walk.pursuitState
                }
                return .inactive
            }()
            let pathSessionElapsed: TimeInterval = {
                if case .companionWalk(let walk) = self.realExperienceState?.runtimeState {
                    return walk.movementSeconds
                }
                return self.movementEngine.currentSession?.elapsedTime ?? 0
            }()

            guard let snapshot = result.snapshot,
                  let state = self.realExperienceState,
                  let context = self.realExperienceContext else {
                self.playPathSoftAudioIfNeeded(
                    pursuitState: pursuitForPath,
                    sessionElapsed: pathSessionElapsed,
                    at: self.fieldTestNow()
                )
                return
            }

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
                let event = update.narrativeEvents.isEmpty ? nil : walkState.lastEvent
                self.realCompanionRuntime.apply(event: event)
                if let event {
                    self.activeFieldTestReceipt?.recordWorldEvent(event)
                }
                self.emitARWorldCommands(self.arCommandMapper.update(
                    companionRuntime: self.realCompanionRuntime,
                    event: event,
                    pursuitState: walkState.pursuitState,
                    pathRelation: self.pathProgress.relation,
                    pathIntegrityPressure: self.pathProgress.integrityPressure
                ))
                if update.semanticAudioCues.isEmpty {
                    self.playPathSoftAudioIfNeeded(
                        pursuitState: walkState.pursuitState,
                        sessionElapsed: walkState.movementSeconds,
                        at: snapshot.timestamp
                    )
                } else {
                    self.lastPathRelationForAudio = self.pathProgress.relation
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
        emitARWorldCommands(arCommandMapper.clear())
        let endedAt = fieldTestNow()
        let priorState = realWalkState
        cancelHealthRefresh()
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
        if priorState == .paused {
            endPresentationPause(at: endedAt)
        }
        resetPresentationElapsedClock()
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

    /// Optional HealthKit enrichment for real walks only. Never blocks Demo Mode.
    private func cancelHealthRefresh() {
        healthRefreshGeneration &+= 1
        healthRefreshTask?.cancel()
        healthRefreshTask = nil
    }

    private func scheduleHealthRefreshForRealWalk(periodic: Bool) {
        cancelHealthRefresh()
        let generation = healthRefreshGeneration
        healthRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performHealthEnrichmentIfCurrent(generation: generation)
            guard periodic else { return }
            while !Task.isCancelled,
                  generation == self.healthRefreshGeneration,
                  self.realWalkState == .active {
                try? await Task.sleep(nanoseconds: Self.healthRefreshIntervalNanoseconds)
                guard !Task.isCancelled,
                      generation == self.healthRefreshGeneration,
                      self.realWalkState == .active else { return }
                await self.performHealthEnrichmentIfCurrent(generation: generation)
            }
        }
    }

    private func performHealthEnrichmentIfCurrent(generation: UInt64) async {
        guard generation == healthRefreshGeneration else { return }
        guard realWalkState == .active else { return }
        // Context must already exist (set before schedule on start).
        await healthMetricsProvider.requestAuthorizationIfNeeded()
        guard generation == healthRefreshGeneration, realWalkState == .active else { return }
        let enrichment = await healthMetricsProvider.refreshEnrichment()
        guard generation == healthRefreshGeneration, realWalkState == .active else { return }
        activityEnrichment = enrichment
        applyActivityEnergyHintToExperienceContext()
    }

    private func applyActivityEnergyHintToExperienceContext() {
        guard let context = realExperienceContext else { return }
        realExperienceContext = ExperienceContext(
            timeOfDay: context.timeOfDay,
            activity: context.activity,
            bondLevel: context.bondLevel,
            eventSeed: context.eventSeed,
            activityEnergyHint: activityEnrichment.energyHint
        )
    }

    private var arCommandMapper: CanonicalARWorldCommandMapper {
        CanonicalARWorldCommandMapper(
            companionID: companion.id,
            companionName: companion.name
        )
    }

    @discardableResult
    func attachARWorldCommandHandler(_ handler: @escaping ([ARWorldCommand]) -> Void) -> UUID {
        let owner = UUID()
        arWorldCommandHandlerOwner = owner
        arWorldCommandHandler = handler
        if isLiveSessionActive {
            let walkState: CompanionWalkState? = if case .companionWalk(let state) = realExperienceState?.runtimeState {
                state
            } else {
                nil
            }
            handler(arCommandMapper.snapshot(
                companionRuntime: realCompanionRuntime,
                pursuitState: walkState?.pursuitState ?? .inactive,
                lastEvent: walkState?.lastEvent,
                pathRelation: pathProgress.relation,
                pathIntegrityPressure: pathProgress.integrityPressure
            ))
        } else if demoController.isRunning {
            handler(arCommandMapper.snapshot(
                companionRuntime: demoController.companionRuntime,
                pursuitState: demoController.companionWalkState?.pursuitState ?? .inactive,
                lastEvent: demoController.currentEvent,
                pathRelation: pathProgress.relation,
                pathIntegrityPressure: pathProgress.integrityPressure
            ))
        }
        return owner
    }

    /// Soft path cues when experience/event audio is silent (#140).
    private func playPathSoftAudioIfNeeded(
        pursuitState: PursuitState,
        sessionElapsed: TimeInterval,
        at timestamp: Date
    ) {
        let previous = lastPathRelationForAudio
        let next = pathProgress.relation
        defer { lastPathRelationForAudio = next }
        guard let cue = PathAudioCoupling.cue(
            from: previous,
            to: next,
            pursuitState: pursuitState,
            sessionElapsed: sessionElapsed,
            lastPathAudioElapsed: lastPathAudioElapsed
        ) else { return }
        lastPathAudioElapsed = sessionElapsed
        activeFieldTestReceipt?.recordAudioCue(cue, at: timestamp)
        audioPlayer.handle([cue])
    }

    func detachARWorldCommandHandler(owner: UUID) {
        guard arWorldCommandHandlerOwner == owner else { return }
        arWorldCommandHandlerOwner = nil
        arWorldCommandHandler = nil
    }

    // MARK: - Glasses glance (#115)

    private func startGlassesGlanceSession() async {
        guard glassesGlanceAdapter.isEnabled else { return }
        await glassesGlanceAdapter.startSession()
        publishGlassesGlance()
    }

    private func publishGlassesGlance() {
        guard glassesGlanceAdapter.isEnabled else { return }
        // Only publish during an active walk surface (demo or live).
        let sessionLive = demoController.isRunning || isLiveSessionActive
        guard sessionLive else { return }
        glassesGlanceAdapter.publish(GlassesGlanceSnapshot.from(activePresencePresentation))
    }

    private func endGlassesGlanceSession() {
        glassesGlanceAdapter.endSession()
    }

    private func emitARWorldCommands(_ commands: [ARWorldCommand]) {
        guard !commands.isEmpty else { return }
        arWorldCommandHandler?(commands)
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
            endedAt: endedAt,
            pathProgress: pathProgress,
            activityEnrichment: activityEnrichment
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
    @Environment(\.wkTheme) private var theme
    @Query(sort: \SessionMemoryRecord.createdAt, order: .reverse)
    private var memoryRecords: [SessionMemoryRecord]

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
            VStack(spacing: 16) {
                HStack {
                    WKBondFilamentMark(size: 40)
                    Spacer()
                    Button {
                        appModel.showsSettings = true
                    } label: {
                        WKIconView(icon: .settings, size: 22)
                            .foregroundStyle(theme.textSecondary)
                            .frame(minWidth: 48, minHeight: 48)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("waykin.home.settings")
                }
                .padding(.top, 4)

                Text("Waykin")
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.textPrimary)
                    .accessibilityIdentifier("waykin.home")

                // Companion presence stage
                LiraSessionFigure(presentation: appModel.homePresencePresentation)
                    .frame(maxHeight: 200)
                    .accessibilityIdentifier("waykin.home.lira")

                HStack(spacing: 10) {
                    LiraGlyphView(size: 36, skin: appModel.selectedLiraSkin)
                    Text("\(appModel.companion.name) • Bond \(appModel.companion.bondLevel)")
                        .foregroundStyle(theme.bondText)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Companion \(appModel.companion.name), Bond \(appModel.companion.bondLevel)")
                .accessibilityIdentifier("waykin.home.bondRow")

                // Cosmetic skin picker (no unlock economy)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Form")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textTertiary)
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: 8) {
                        ForEach(LiraSkin.allCases) { skin in
                            Button {
                                appModel.selectedLiraSkin = skin
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(skin.bodyBase(theme: theme))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    appModel.selectedLiraSkin == skin
                                                        ? theme.focus
                                                        : theme.textTertiary.opacity(0.35),
                                                    lineWidth: appModel.selectedLiraSkin == skin ? 2 : 1
                                                )
                                        )
                                    Text(skin.displayName)
                                        .font(.caption2.weight(appModel.selectedLiraSkin == skin ? .semibold : .regular))
                                        .foregroundStyle(
                                            appModel.selectedLiraSkin == skin
                                                ? theme.textPrimary
                                                : theme.textSecondary
                                        )
                                }
                                .frame(minWidth: 64, minHeight: 48)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(skin.displayName) form")
                            .accessibilityAddTraits(appModel.selectedLiraSkin == skin ? .isSelected : [])
                            .accessibilityIdentifier("waykin.home.skin.\(skin.rawValue)")
                        }
                    }
                    Text(appModel.selectedLiraSkin.unlockLine)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("waykin.home.skin.line")
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if let lastMemory = memoryRecords.first {
                    Text(lastMemory.text)
                        .font(.callout)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("waykin.memory.latest")
                } else {
                    Text("Walk with Lira to write your first memory.")
                        .font(.callout)
                        .foregroundStyle(theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("waykin.memory.emptyInvite")
                }

                if !appModel.demoMessage.isEmpty {
                    Text(appModel.demoMessage)
                        .font(.callout)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("waykin.status")
                }

                // #126: product priority — real walk is primary CTA; demo is secondary.
                Button {
                    appModel.startRealCompanionWalk()
                } label: {
                    WKIconLabel(title: realWalkButtonTitle, icon: .beginSession)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.guide)
                .disabled(realWalkButtonDisabled)
                .accessibilityLabel(realWalkButtonTitle)
                .accessibilityIdentifier("waykin.real.open")
                .accessibilityIdentifier("waykin.real.activity.walk")
                .accessibilityIdentifier("waykin.real.experience.companionWalk")
                .accessibilityIdentifier("waykin.home.beginWalk.real")

                Button {
                    appModel.startDemo(.calmDayWalk)
                } label: {
                    WKIconLabel(title: "Demo Walk", icon: .beginSession)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .tint(theme.guide)
                .accessibilityLabel("Demo Walk")
                .accessibilityIdentifier("waykin.beginWalk")

                if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                    Text("Demo Mode")
                        .font(.caption)
                        .foregroundStyle(theme.textTertiary)
                        .accessibilityIdentifier("waykin.demo.mode")
                }

                Button("Memory History") { appModel.path.append(AppRoute.memoryHistory) }
                    .foregroundStyle(theme.guideText)
                    .frame(minHeight: 48)
                    .accessibilityIdentifier("waykin.memory.open")

                if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location: \(String(describing: appModel.realLocationProvider.authorizationStatus))")
                            .accessibilityIdentifier("waykin.location.authorization")
                        Text("Signal: \(String(describing: appModel.liveSignalState))")
                            .accessibilityIdentifier("waykin.location.status")
                        Text("Live: \(appModel.isLiveSessionActive)")
                            .accessibilityIdentifier("waykin.session.live")
                            .accessibilityIdentifier("waykin.location.signalState")
                        Text("Accepted: \(appModel.liveAcceptedCount) Rejected: \(appModel.liveRejectedCount)")
                            .accessibilityIdentifier("waykin.location.acceptedCount")
                    }
                    .font(.caption2)
                    .foregroundStyle(theme.textTertiary)
                }

                if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                    VStack {
                        Text("Persistence: \(appModel.persistenceMode)")
                            .accessibilityIdentifier("waykin.persistence.mode")
                        Text("State: \(appModel.persistenceLoadState.rawValue)")
                            .accessibilityIdentifier("waykin.persistence.state")
                        Text("MemCount: \(appModel.persistenceMemoryCount)")
                            .accessibilityIdentifier("waykin.persistence.queryMemoryCount")
                        Text("PathHash: \(appModel.persistenceStorePathHash)")
                            .accessibilityIdentifier("waykin.persistence.storePathHash")
                        Text(appModel.selectedLiraSkin.rawValue)
                            .accessibilityIdentifier("waykin.home.skin.selected")
                        Text(appModel.appearancePreference.rawValue)
                            .accessibilityIdentifier("waykin.home.appearance.selected")
                        Text(appModel.pathProgress.relation.rawValue)
                            .accessibilityIdentifier("waykin.path.relation")
                        Text(String(format: "%.2f", appModel.pathProgress.integrityPressure))
                            .accessibilityIdentifier("waykin.path.pressure")
                        Text(appModel.activityEnrichment.stepCadenceBand.rawValue)
                            .accessibilityIdentifier("waykin.health.cadence")
                    }
                    .font(.caption2)
                    .foregroundStyle(theme.textTertiary)
                }
            }
            .padding(24)
            }
        }
        .sheet(isPresented: Binding(
            get: { appModel.showsSettings },
            set: { appModel.showsSettings = $0 }
        )) {
            SettingsView()
                .environment(appModel)
                .wkThemed()
                .liraSkin(appModel.selectedLiraSkin)
                .preferredColorScheme(appModel.appearancePreference.preferredColorScheme)
        }
    }

    /// Inline real-walk CTA feedback (#126) — state lives on the button, not a missed status line.
    private var realWalkButtonTitle: String {
        switch appModel.realWalkState {
        case .requestingPermission:
            return "Allow Location…"
        case .active, .paused:
            return "Walk in Progress"
        case .ending:
            return "Ending Walk…"
        case .failed:
            return "Try Walk Again"
        case .idle, .completed:
            return "Begin Walk"
        }
    }

    private var realWalkButtonDisabled: Bool {
        switch appModel.realWalkState {
        case .requestingPermission, .active, .paused, .ending:
            return true
        case .idle, .completed, .failed:
            return false
        }
    }
}

struct SettingsView: View {
    @Environment(WaykinAppModel.self) private var appModel
    @Environment(\.wkTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(AppearancePreference.allCases) { preference in
                        Button {
                            appModel.appearancePreference = preference
                        } label: {
                            HStack {
                                Text(preference.displayName)
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if appModel.appearancePreference == preference {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(theme.guide)
                                }
                            }
                            .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("waykin.settings.appearance.\(preference.rawValue)")
                    }
                }

                Section("Form") {
                    Text(appModel.selectedLiraSkin.displayName)
                        .foregroundStyle(theme.textSecondary)
                    Text("Change Lira’s form on Home. Cosmetics only.")
                        .font(.caption)
                        .foregroundStyle(theme.textTertiary)
                }

                Section {
                    Text("Day and night use Echo tokens (not a simple invert). Outdoor glare still needs a device walk.")
                        .font(.caption)
                        .foregroundStyle(theme.textTertiary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("waykin.settings.done")
                }
            }
        }
    }
}

struct ActiveSessionView: View {
    @Environment(WaykinAppModel.self) private var appModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.wkTheme) private var theme
    @State private var showsARCompanion = false
    let scenario: DemoScenarioID

    var body: some View {
        // Live real walks: refresh HUD ~1 Hz so elapsed advances smoothly (#128).
        // Demo ticks still drive demo elapsed via model mutations.
        Group {
            if appModel.isLiveSessionActive && appModel.realWalkState == .active {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    sessionContent
                }
            } else {
                sessionContent
            }
        }
    }

    private var sessionContent: some View {
        let presentation = appModel.activePresencePresentation

        return ZStack {
            CompanionPresenceStyle.background(for: presentation.pressureIntensity, theme: theme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: CompanionPresenceStyle.sectionSpacing) {
                    CompanionPresenceView(presentation: presentation)
                        .liraSkin(appModel.selectedLiraSkin)

                    // #126: AR beside Pause/End for one-handed reach (continuity re-entry).
                    AnyLayout(dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(spacing: 12))
                        : AnyLayout(HStackLayout(spacing: 12))) {
                        if presentation.isPaused {
                            Button {
                                appModel.isLiveSessionActive ? appModel.resumeRealSession() : appModel.resumeDemo()
                            } label: {
                                WKIconLabel(title: "Resume", icon: .resume)
                                    .frame(minWidth: 48, minHeight: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(theme.guide)
                            .accessibilityLabel("Resume walk")
                            .accessibilitySortPriority(2)
                            .accessibilityIdentifier("waykin.session.resume")
                        } else {
                            Button {
                                appModel.isLiveSessionActive ? appModel.pauseRealSession() : appModel.pauseDemo()
                            } label: {
                                WKIconLabel(title: "Pause", icon: .pause)
                                    .frame(minWidth: 48, minHeight: 48)
                            }
                            .buttonStyle(.bordered)
                            .tint(theme.pause)
                            .accessibilityLabel("Pause walk")
                            .accessibilitySortPriority(2)
                            .accessibilityIdentifier("waykin.session.pause")
                        }

                        // End is calm/neutral — never alarm red (design: stop is always okay)
                        Button {
                            appModel.isLiveSessionActive ? appModel.endRealSession() : appModel.endDemo()
                        } label: {
                            WKIconLabel(title: "End", icon: .stop)
                                .frame(minWidth: 48, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.textSecondary)
                        .accessibilityLabel("End walk")
                        .accessibilitySortPriority(1.9)
                        .accessibilityIdentifier("waykin.session.end")

                        Button {
                            showsARCompanion = true
                        } label: {
                            Label("AR", systemImage: "viewfinder")
                                .frame(minWidth: 48, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.guide)
                        .accessibilityLabel("Open AR companion")
                        .accessibilitySortPriority(1.8)
                        .accessibilityIdentifier("waykin.session.openARCompanion")
                    }
                    .frame(maxWidth: .infinity)

                    if !appModel.isLiveSessionActive {
                        Button { appModel.runDemoToEnd() } label: {
                            Text("Run to End")
                                .frame(minWidth: 48, minHeight: 48)
                        }
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .accessibilitySortPriority(1)
                        .accessibilityIdentifier("waykin.session.runToEnd")
                    } else {
                        let signal = GPSSignalPresentation(state: appModel.liveSignalState)
                        SessionStatusChip(
                            title: signal.label,
                            systemImage: signal.symbolName,
                            tone: signal.isProblem ? .caution : .calm,
                            accessibilityLabelText: "GPS status",
                            accessibilityValueText: signal.accessibilityValue,
                            accessibilityIdentifier: "waykin.session.liveSignal"
                        )
                        .accessibilitySortPriority(1)
                    }

                    CompactSessionMap(
                        latitude: presentation.latitude,
                        longitude: presentation.longitude,
                        trace: appModel.walkPathTrace
                    )
                }
                .padding(.horizontal, CompanionPresenceStyle.horizontalPadding)
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(appModel.demoController.isRunning || appModel.isLiveSessionActive)
        // #126: full-screen cover, not swipe-dismissible sheet over Pause/End.
        .fullScreenCover(isPresented: $showsARCompanion) {
            CanonicalARSessionView(
                appModel: appModel,
                liraSkin: appModel.selectedLiraSkin,
                isPaused: appModel.activePresencePresentation.isPaused,
                onPause: {
                    appModel.isLiveSessionActive ? appModel.pauseRealSession() : appModel.pauseDemo()
                },
                onResume: {
                    appModel.isLiveSessionActive ? appModel.resumeRealSession() : appModel.resumeDemo()
                },
                onEnd: {
                    showsARCompanion = false
                    appModel.isLiveSessionActive ? appModel.endRealSession() : appModel.endDemo()
                }
            )
            .interactiveDismissDisabled()
        }
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    @Environment(WaykinAppModel.self) private var appModel
    @Environment(\.wkTheme) private var theme

    var body: some View {
        ZStack {
            theme.backgroundWarm.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Session Summary")
                        .font(.title)
                        .foregroundStyle(theme.textPrimary)
                        .accessibilityIdentifier("waykin.summary.screen")

                    // #148: skin-correct still + bond delta.
                    LiraSessionFigure(presentation: summaryPresencePresentation)
                        .frame(maxHeight: 160)
                        .liraSkin(appModel.selectedLiraSkin)
                        .accessibilityIdentifier("waykin.summary.lira")

                    HStack(spacing: 10) {
                        WKBondFilamentMark(size: 28)
                        Text(bondDeltaText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(theme.bondText)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Bond change")
                    .accessibilityValue(bondDeltaText)
                    .accessibilityIdentifier("waykin.summary.bondDelta")

                    if !appModel.lastClosingPhrase.isEmpty {
                        Text(appModel.lastClosingPhrase)
                            .font(.headline)
                            .foregroundStyle(theme.bondText)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("waykin.session.closing")
                    }
                    Text(summary.memory.text)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("waykin.summary.memory")

                    HStack(spacing: 24) {
                        summaryMetric(
                            value: elapsedSummaryText,
                            label: "Time",
                            identifier: "waykin.summary.elapsed"
                        )
                        summaryMetric(
                            value: distanceSummaryText,
                            label: "Distance",
                            identifier: "waykin.summary.distance"
                        )
                    }
                    .accessibilityIdentifier("waykin.summary.stats")

                    if let pathLine = summary.pathPresentationLine {
                        Text(pathLine)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.guide)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("waykin.summary.path")
                    }
                    if let cadenceLine = summary.cadencePresentationLine {
                        Text(cadenceLine)
                            .font(.caption)
                            .foregroundStyle(theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("waykin.summary.cadence")
                    }
                    if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                        Text(appModel.persistenceMemoryCount > 0 ? "WRITTEN" : "MISSING")
                            .accessibilityIdentifier("waykin.summary.memoryWrite")
                        Text(appModel.latestFieldTestReceiptURL.map {
                            FileManager.default.fileExists(atPath: $0.path) ? "WRITTEN" : "MISSING"
                        } ?? "MISSING")
                        .accessibilityIdentifier("waykin.summary.receiptWrite")
                    }
                    Button("Back to Home") { appModel.returnHome() }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.guide)
                        .frame(minHeight: 48)
                        .accessibilityIdentifier("waykin.summary.home")
                }
                .padding(24)
            }
        }
    }

    private var bondDeltaText: String {
        let delta = summary.bondDelta
        if delta > 0 { return "Bond +\(delta)" }
        if delta < 0 { return "Bond \(delta)" }
        return "Bond held"
    }

    private var elapsedSummaryText: String {
        let total = max(0, Int(summary.duration.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var distanceSummaryText: String {
        let meters = max(0, Int(summary.distanceMeters.rounded()))
        return "\(meters) m"
    }

    /// Settled presence for summary art (#148) — celebrate lean when bond grew.
    private var summaryPresencePresentation: CompanionPresencePresentation {
        CompanionPresencePresentation(
            companionName: appModel.companion.name,
            bondLevel: appModel.companion.bondLevel,
            behavior: summary.bondDelta > 0 ? .celebrate : .rest,
            pursuitState: .inactive,
            eventKind: summary.bondDelta > 0 ? .bondMoment : .quietInterval,
            audioCueKind: nil,
            elapsedSeconds: summary.duration,
            distanceMeters: summary.distanceMeters,
            isPaused: false,
            isOpening: false,
            latitude: nil,
            longitude: nil,
            pathRelation: PathRelation(rawValue: summary.pathRelation ?? "") ?? .onPath,
            pathIntegrityPressure: 0,
            energyHint: 0
        )
    }

    private func summaryMetric(value: String, label: String, identifier: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityIdentifier(identifier)
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
