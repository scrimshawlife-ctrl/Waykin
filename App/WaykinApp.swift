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

    let realLocationProvider: any RealLocationProviding

    var companion: Companion
    var activeRecommendation: ExperienceRecommendation?
    var lastSummary: SessionSummary?
    var demoMessage = ""
    var selectedTimeContext: String = "day"
    var path = NavigationPath()

    // Diagnostics (UI-test only)
    var persistenceMode: String = "FILE_BACKED"
    var persistenceLoadState: PersistenceLoadState = .loaded
    var persistenceMemoryCount: Int = 0
    var lastSavedMemoryID: String = ""
    var persistenceStorePathHash: String = ""

    // Live real-session state (physical device)
    private(set) var realWalkState: RealWalkSessionState = .idle
    var isLiveSessionActive: Bool { realWalkState == .active || realWalkState == .paused }
    var liveSignalState: LiveLocationSignalState = .waitingForAuthorization
    var liveAcceptedCount: Int = 0
    var liveRejectedCount: Int = 0
    private var realExperienceState: ExperienceSessionState?
    private var realExperienceContext: ExperienceContext?
    private var lifecycleSuspendedRealWalk = false

    init(
        persistenceStore: PersistenceStore,
        audioPlayer: (any AudioCuePlaying)? = nil,
        movementEngine: MovementEngine = MovementEngine(),
        realLocationProvider: any RealLocationProviding = RealLocationProvider()
    ) {
        self.persistenceStore = persistenceStore
        self.movementEngine = movementEngine
        self.demoController = DemoSessionController(movementEngine: movementEngine)
        self.audioPlayer = audioPlayer ?? AppAudioCuePlayer()
        self.realLocationProvider = realLocationProvider

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
            audioPlayer.stopAll(fadeOut: false)
            try demoController.start(scenarioID: scenario)
            demoMessage = "Walking with Lira..."
            path.append(AppRoute.activeSession(scenario))
        } catch {
            demoMessage = "Failed to start demo"
        }
    }

    func pauseDemo() {
        demoController.pause()
        audioPlayer.pauseAll()
    }

    func resumeDemo() {
        demoController.resume()
        audioPlayer.resumeAll()
    }

    func advanceDemo() {
        demoController.advanceOneTick()
        if let cue = demoController.currentAudioCue {
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
        audioPlayer.stopAll(fadeOut: true)
        let (_, result, summary) = demoController.end()
        guard let result = result, let summary = summary else { return }

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
        } catch {
            demoMessage = "Persistence failed: \(error)"
            persistenceLoadState = .failed
        }
    }

    func returnHome() { path = NavigationPath() }

    // MARK: - Real physical walk support (COMPANION_WALK)
    func startRealCompanionWalk() {
        guard realWalkState == .idle || realWalkState == .completed || realWalkState == .failed else {
            demoMessage = "A walk is already in progress."
            return
        }
        guard realLocationProvider.locationServicesEnabled else {
            failRealWalk(message: "Location Services are unavailable. Demo Walk is still available.")
            return
        }

        switch realLocationProvider.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginAuthorizedRealWalk()
        case .notDetermined:
            realWalkState = .requestingPermission
            liveSignalState = .waitingForAuthorization
            realLocationProvider.requestAuthorization()
        case .denied, .restricted:
            failRealWalk(message: "Location access is required for a real walk. Demo Walk is still available.")
        @unknown default:
            failRealWalk(message: "Location authorization is unavailable. Demo Walk is still available.")
        }
    }

    private func beginAuthorizedRealWalk() {
        guard realWalkState != .active && realWalkState != .paused else { return }
        do {
            audioPlayer.stopAll(fadeOut: false)
            try movementEngine.startSession(activity: .walk, experienceID: "companion_walk")
            try movementEngine.resumeSession()
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
            demoMessage = "Waiting for a reliable location fix..."
            path.append(AppRoute.activeSession(.calmDayWalk))
        } catch {
            failRealWalk(message: "The real walk could not start. Demo Walk is still available.")
        }
    }

    func pauseRealSession() {
        guard realWalkState == .active else { return }
        do {
            try movementEngine.pauseSession()
            realLocationProvider.stopUpdatingLocation()
            audioPlayer.pauseAll()
            realWalkState = .paused
            lifecycleSuspendedRealWalk = false
        } catch {
            failRealWalk(message: "The real walk could not be paused safely.")
        }
    }

    func resumeRealSession() {
        guard realWalkState == .paused else { return }
        do {
            try movementEngine.resumeSession()
            realLocationProvider.startUpdatingLocation()
            liveSignalState = .waitingForFirstFix
            audioPlayer.resumeAll()
            realWalkState = .active
            lifecycleSuspendedRealWalk = false
        } catch {
            failRealWalk(message: "The real walk could not resume safely.")
        }
    }

    func endRealSession() {
        guard isLiveSessionActive else { return }
        realWalkState = .ending
        realLocationProvider.stopUpdatingLocation()
        audioPlayer.stopAll(fadeOut: true)
        do {
            let ended = try movementEngine.endSession()
            realWalkState = .completed
            lifecycleSuspendedRealWalk = false
            realExperienceState = nil
            realExperienceContext = nil

            // Create minimal summary + memory for proof
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

            let memText = summary.memory.text
            let mem = SessionMemory(sessionID: summary.sessionID, text: memText)
            let receipt = try persistenceStore.saveMemory(mem)
            lastSavedMemoryID = receipt.recordID.uuidString
            persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0

            path.append(AppRoute.summary(summary.id))
        } catch {
            failRealWalk(message: "The real walk could not end cleanly.")
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
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
            audioPlayer.pauseAll()
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume), shouldResumeAudio {
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
            self.audioPlayer.handle(update.semanticAudioCues)
        }

        realLocationProvider.onAuthorizationChange = { [weak self] status in
            guard let self else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.realWalkState == .requestingPermission {
                    self.beginAuthorizedRealWalk()
                }
            case .denied, .restricted:
                if self.realWalkState == .requestingPermission || self.isLiveSessionActive {
                    self.failRealWalk(message: "Location access is required for a real walk. Demo Walk is still available.")
                }
            case .notDetermined:
                break
            @unknown default:
                self.failRealWalk(message: "Location authorization is unavailable. Demo Walk is still available.")
            }
        }

        realLocationProvider.onSignalStateChange = { [weak self] state in
            guard let self else { return }
            self.liveSignalState = state
            switch state {
            case .failed:
                self.failRealWalk(message: "Location became unavailable. The walk was stopped safely.")
            case .unavailable:
                if self.isLiveSessionActive {
                    self.failRealWalk(message: "Location access is unavailable. The walk was stopped safely.")
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
            realWalkState = .paused
            lifecycleSuspendedRealWalk = true
        } catch {
            failRealWalk(message: "The real walk was stopped safely after an interruption.")
        }
    }

    private func failRealWalk(message: String) {
        realLocationProvider.stopUpdatingLocation()
        audioPlayer.stopAll(fadeOut: false)
        if movementEngine.currentSession != nil {
            _ = try? movementEngine.endSession()
        }
        realExperienceState = nil
        realExperienceContext = nil
        lifecycleSuspendedRealWalk = false
        realWalkState = .failed
        demoMessage = message
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
        VStack {
            Text("Active Walk").font(.title2).accessibilityIdentifier("waykin.session.screen")
            Text(appModel.demoController.presentationState.statusText).accessibilityIdentifier("waykin.session.elapsed")
            if let event = appModel.demoController.currentEvent {
                Text(event.kind.rawValue)
                    .accessibilityIdentifier("waykin.session.phenomenon")
            }
            if let cue = appModel.demoController.currentAudioCue {
                Text(cue.kind.rawValue)
                    .accessibilityIdentifier("waykin.session.audioCue")
            }

            let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))))
                .frame(height: 220)
                .accessibilityIdentifier("waykin.session.map")

            if appModel.isLiveSessionActive {
                HStack(spacing: 12) {
                    Button("Pause") { appModel.pauseRealSession() }
                        .accessibilityIdentifier("waykin.session.pause")
                    Button("Resume") { appModel.resumeRealSession() }
                        .accessibilityIdentifier("waykin.session.resume")
                    Button("End Real") { appModel.endRealSession() }
                        .accessibilityIdentifier("waykin.session.end")
                }
                Text("Live Signal: \(appModel.liveSignalState).description)")
                    .accessibilityIdentifier("waykin.session.liveSignal")
            } else {
                HStack {
                    Button("Pause") { appModel.pauseDemo() }
                        .accessibilityIdentifier("waykin.session.pause")
                    Button("Resume") { appModel.resumeDemo() }
                        .accessibilityIdentifier("waykin.session.resume")
                    Button("Run to End") { appModel.runDemoToEnd() }
                        .accessibilityIdentifier("waykin.session.runToEnd")
                    Button("End") { appModel.endDemo() }
                        .accessibilityIdentifier("waykin.session.end")
                }
            }
        }.padding()
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    @Environment(WaykinAppModel.self) private var appModel

    var body: some View {
        VStack {
            Text("Session Summary").font(.title).accessibilityIdentifier("waykin.summary.screen")
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
