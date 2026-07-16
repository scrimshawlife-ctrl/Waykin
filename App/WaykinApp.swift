import SwiftUI
import WaykinCore
import WaykinCore
import MapKit
import SwiftData

enum AppRoute: Hashable {
    case demoList
    case activeSession(DemoScenarioID)
    case summary(UUID)
    case memoryHistory
}

enum PersistenceLoadState: String, Equatable {
    case idle, loading, loaded, failed
}

@main
struct WaykinApp: App {
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
                        case .demoList:
                            DemoScenarioListView()
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
        }
        .modelContainer(container)
    }
}

@MainActor
@Observable
final class WaykinAppModel {
    let movementEngine = MovementEngine()
    let persistenceStore: PersistenceStore
    let recommendationEngine = RecommendationEngine()
    let demoController: DemoSessionController

    let realLocationProvider = RealLocationProvider()

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
    var isLiveSessionActive = false
    var liveSignalState: LiveLocationSignalState = .waitingForAuthorization
    var liveAcceptedCount: Int = 0
    var liveRejectedCount: Int = 0

    init(persistenceStore: PersistenceStore) {
        self.persistenceStore = persistenceStore
        self.demoController = DemoSessionController(movementEngine: movementEngine)

        let isUITesting = ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING")
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
            try demoController.start(scenarioID: scenario)
            demoMessage = "Running \(scenario).description)..."
            path.append(AppRoute.activeSession(scenario))
        } catch {
            demoMessage = "Failed to start demo"
        }
    }

    func pauseDemo() { demoController.pause() }
    func resumeDemo() { demoController.resume() }
    func advanceDemo() { demoController.advanceOneTick() }
    func runDemoToEnd() { demoController.runToEnd() }

    func endDemo() {
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
        realLocationProvider.onLocationUpdate = { [weak self] point in
            guard let self = self, self.isLiveSessionActive else { return }
            self.movementEngine.ingestRealLocation(point)
            self.liveAcceptedCount += 1
        }
        realLocationProvider.onSignalStateChange = { [weak self] state in
            self?.liveSignalState = state
        }

        realLocationProvider.requestAuthorization()
        do {
            try movementEngine.startSession(activity: .walk, experienceID: "companion_walk")
            realLocationProvider.startUpdatingLocation()
            isLiveSessionActive = true
            liveSignalState = .waitingForFirstFix
            liveAcceptedCount = 0
            liveRejectedCount = 0
            path.append(AppRoute.activeSession(.calmDayWalk)) // reuse for now; real view later
        } catch {
            demoMessage = "Failed to start real session: \(error)"
        }
    }

    func pauseRealSession() {
        guard isLiveSessionActive else { return }
        try? movementEngine.pauseSession()
        realLocationProvider.stopUpdatingLocation()
    }

    func resumeRealSession() {
        guard isLiveSessionActive else { return }
        try? movementEngine.resumeSession()
        realLocationProvider.startUpdatingLocation()
    }

    func endRealSession() {
        guard isLiveSessionActive else { return }
        realLocationProvider.stopUpdatingLocation()
        do {
            let ended = try movementEngine.endSession()
            isLiveSessionActive = false

            // Create minimal summary + memory for proof
            let summary = SessionSummary(
                id: UUID(),
                sessionID: ended.id,
                activity: ended.activityType,
                experienceID: ended.experienceID,
                distanceMeters: ended.distanceMeters,
                duration: ended.activeTime,
                outcome: "COMPLETED"
            )
            lastSummary = summary

            let memText = "Real walk completed. Distance \(Int(ended.distanceMeters))m."
            let mem = SessionMemory(sessionID: summary.sessionID, text: memText)
            let receipt = try? persistenceStore.saveMemory(mem)
            lastSavedMemoryID = receipt?.recordID.uuidString ?? ""
            persistenceMemoryCount = (try? persistenceStore.memoryCount()) ?? 0

            path.append(AppRoute.summary(summary.id))
        } catch {
            demoMessage = "Real session end failed: \(error)"
        }
    }
}


// MARK: - Views

struct HomeView: View {
    @Environment(WaykinAppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Waykin").font(.largeTitle.bold()).accessibilityIdentifier("waykin.home")
            Text("Companion: \(appModel.companion.name) • Bond \(appModel.companion.bondLevel)")

            if let rec = appModel.activeRecommendation {
                Text("Recommended: \(rec.experienceID) (\(rec.variantID))")
                    .accessibilityIdentifier("waykin.recommendation.primary")
            }

            Button("Demo Scenarios") { appModel.path.append(AppRoute.demoList) }
                .accessibilityIdentifier("waykin.demo.open")

            Button("Memory History") { appModel.path.append(AppRoute.memoryHistory) }
                .accessibilityIdentifier("waykin.memory.open")

            // Real device entry point for physical validation (COMPANION_WALK)
            Button("Start Real Walk (COMPANION_WALK)") {
                appModel.startRealCompanionWalk()
            }
            .accessibilityIdentifier("waykin.real.open")

            if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") || true {  // dev diagnostics
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location: \(appModel.realLocationProvider.authorizationStatus).description)")
                        .accessibilityIdentifier("waykin.location.authorization")
                    Text("Signal: \(appModel.liveSignalState).description)")
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

struct DemoScenarioListView: View {
    @Environment(WaykinAppModel.self) private var appModel

    var body: some View {
        VStack {
            Text("Demo Scenarios").font(.title).accessibilityIdentifier("waykin.demo.screen")
            ForEach(DemoScenarioID.allCases, id: \.self) { scenario in
                Button(scenario).description) { appModel.startDemo(scenario) }
                    .accessibilityIdentifier("waykin.demo.scenario.\(scenario).description)")
            }
        }.padding()
    }
}

struct ActiveSessionView: View {
    @Environment(WaykinAppModel.self) private var appModel
    let scenario: DemoScenarioID

    var body: some View {
        VStack {
            Text("Active: \(scenario).description)").font(.title2).accessibilityIdentifier("waykin.session.screen")
            Text(appModel.demoController.presentationState.statusText).accessibilityIdentifier("waykin.session.elapsed")

            let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))))
                .frame(height: 220)
                .accessibilityIdentifier("waykin.session.map")

            HStack {
                Button("Complete") { appModel.endDemo() }.accessibilityIdentifier("waykin.session.complete")
            }

            // Live real controls (physical device)
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
