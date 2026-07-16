import SwiftUI
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
    case idle
    case loading
    case loaded
    case failed
}

@main
struct WaykinApp: App {
    @State private var appModel = WaykinAppModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $appModel.path) {
                HomeView(appModel: appModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .demoList:
                            DemoScenarioListView(appModel: appModel)
                        case .activeSession(let scenario):
                            ActiveSessionView(appModel: appModel, scenario: scenario)
                        case .summary(let id):
                            if let summary = appModel.lastSummary, summary.id == id {
                                SessionSummaryView(summary: summary, appModel: appModel)
                            } else {
                                Text("Summary not found")
                            }
                        case .memoryHistory:
                            MemoryHistoryView(appModel: appModel)
                        }
                    }
            }
        }
    }
}

@MainActor
@Observable
final class WaykinAppModel {
    let movementEngine = MovementEngine()
    let persistenceStore: PersistenceStore
    let recommendationEngine = RecommendationEngine()
    let demoController: DemoSessionController

    var companion: Companion
    var activeRecommendation: ExperienceRecommendation?
    var lastSummary: SessionSummary?
    var demoMessage = ""
    var selectedTimeContext: String = "day"
    var path = NavigationPath()

    // Persistence diagnostics (exposed for UI tests)
    var persistenceMode: String = "UNKNOWN"
    var persistenceLoadState: PersistenceLoadState = .idle
    var persistenceMemoryCount: Int = 0
    var lastSavedMemoryID: String = ""
    var memories: [SessionMemory] = []

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING")
        let shouldResetArg = ProcessInfo.processInfo.arguments
        let shouldReset = shouldResetArg.contains("-WAYKIN_RESET_STATE") && 
                          !shouldResetArg.contains("-WAYKIN_RESET_STATE NO")

        persistenceLoadState = .loading

        var container: ModelContainer?
        do {
            if isUITesting {
                // UI tests must use file-backed store
                container = try PersistenceStore.makeFileBackedContainer(reset: shouldReset)
                persistenceMode = "FILE_BACKED"
            } else {
                let url = try PersistenceConfiguration.persistentStoreURL()
                let config = ModelConfiguration(url: url)
                container = try ModelContainer(for: CompanionRecord.self, SessionMemoryRecord.self, configurations: config)
                persistenceMode = "FILE_BACKED"
            }
        } catch {
            print("SwiftData file-backed init failed: \(error)")
            // In UI testing we must not silently fall back
            if isUITesting {
                persistenceMode = "FAILED_FILE_BACKED"
            } else {
                persistenceMode = "IN_MEMORY_FALLBACK"
            }
        }

        if let c = container {
            self.persistenceStore = PersistenceStore(modelContainer: c)
        } else {
            self.persistenceStore = PersistenceStore()
            if isUITesting {
                persistenceMode = "FAILED_FILE_BACKED"
            }
        }

        self.demoController = DemoSessionController(movementEngine: movementEngine)

        // Only reset when explicitly requested
        if shouldReset {
            persistenceStore.resetDemoData()
        }

        if let loaded = persistenceStore.loadCompanion() {
            var c = loaded
            c.memories = persistenceStore.loadMemories()
            self.companion = c
            self.memories = c.memories
        } else {
            self.companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
            persistenceStore.saveCompanion(self.companion)
            self.memories = []
        }

        persistenceMemoryCount = persistenceStore.memoryCount()
        persistenceLoadState = .loaded
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
            demoMessage = "Running \(scenario.rawValue)..."
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
        if let result = result, let summary = summary {
            var updated = companion
            updated.bondLevel += result.bondDelta
            let mem = SessionMemory(sessionID: summary.sessionID, text: result.memoryText)

            // Save and verify durability before navigation
            let receipt = persistenceStore.saveMemory(mem)
            persistenceStore.saveCompanion(updated)

            updated.memories.append(mem)
            companion = updated
            lastSummary = summary
            demoMessage = "Session ended: \(result.outcome). Bond +\(result.bondDelta)"

            if let r = receipt {
                lastSavedMemoryID = r.recordID.uuidString
            }
            persistenceMemoryCount = persistenceStore.memoryCount()
            refreshRecommendation()

            // Only navigate after save
            path.append(AppRoute.summary(summary.id))
        }
    }

    func resetDemoData() {
        persistenceStore.resetDemoData()
        companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
        persistenceStore.saveCompanion(companion)
        lastSummary = nil
        demoMessage = "Data reset"
        persistenceMemoryCount = 0
        lastSavedMemoryID = ""
        path = NavigationPath()
    }

    func returnHome() {
        path = NavigationPath()
    }
}

// MARK: - Views (minimal changes for diagnostics)

struct HomeView: View {
    @Bindable var appModel: WaykinAppModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Waykin")
                .font(.largeTitle.bold())
                .accessibilityIdentifier("waykin.home")

            Text("Companion: \(appModel.companion.name) • Bond \(appModel.companion.bondLevel)")

            if let rec = appModel.activeRecommendation {
                VStack {
                    Text("Recommended: \(rec.experienceID) (\(rec.variantID))")
                        .accessibilityIdentifier("waykin.recommendation.primary")
                    let reason = (rec.observedReasons + rec.inferredReasons).first ?? rec.unavailableSignals.first ?? "Context based"
                    Text(reason)
                        .font(.caption)
                        .accessibilityIdentifier("waykin.recommendation.reason")
                }
            }

            Button("Demo Scenarios") {
                appModel.path.append(AppRoute.demoList)
            }
            .accessibilityIdentifier("waykin.demo.open")

            Button("Memory History") {
                appModel.path.append(AppRoute.memoryHistory)
            }
            .accessibilityIdentifier("waykin.memory.open")

            if ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING") {
                VStack {
                    Text("Persistence: \(appModel.persistenceMode)")
                        .accessibilityIdentifier("waykin.persistence.mode")
                    Text("State: \(appModel.persistenceLoadState.rawValue)")
                        .accessibilityIdentifier("waykin.persistence.state")
                    Text("MemCount: \(appModel.persistenceMemoryCount)")
                        .accessibilityIdentifier("waykin.persistence.memoryCount")
                }
                .font(.caption2)
            }

            Divider()

            Text("Time Context (for testing)")
            HStack {
                Button("Day") { appModel.setTimeContext("day") }
                Button("Night") { appModel.setTimeContext("night") }
            }

            if !appModel.demoMessage.isEmpty {
                Text(appModel.demoMessage)
            }
        }
        .padding()
    }
}

struct DemoScenarioListView: View {
    @Bindable var appModel: WaykinAppModel

    var body: some View {
        VStack {
            Text("Demo Scenarios")
                .font(.title)
                .accessibilityIdentifier("waykin.demo.screen")

            ForEach(DemoScenarioID.allCases, id: \.self) { scenario in
                Button(scenario.rawValue) {
                    appModel.startDemo(scenario)
                }
                .accessibilityIdentifier("waykin.demo.scenario.\(scenario.rawValue)")
            }
        }
        .padding()
    }
}

struct ActiveSessionView: View {
    @Bindable var appModel: WaykinAppModel
    let scenario: DemoScenarioID

    var body: some View {
        VStack {
            Text("Active: \(scenario.rawValue)")
                .font(.title2)
                .accessibilityIdentifier("waykin.session.screen")

            let ps = appModel.demoController.presentationState
            Text("Status: \(ps.statusText)")
                .accessibilityIdentifier("waykin.session.elapsed")

            let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))))
                .frame(height: 220)
                .accessibilityIdentifier("waykin.session.map")

            HStack {
                Button("Pause") { appModel.pauseDemo() }
                    .accessibilityIdentifier("waykin.session.pause")
                Button("Resume") { appModel.resumeDemo() }
                    .accessibilityIdentifier("waykin.session.resume")
                Button("Advance") { appModel.advanceDemo() }
                Button("Run to End") { appModel.runDemoToEnd() }
                Button("Complete") { appModel.endDemo() }
                    .accessibilityIdentifier("waykin.session.complete")
            }

            Text(ps.statusText)
                .accessibilityIdentifier("waykin.session.experienceState")
        }
        .padding()
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    @Bindable var appModel: WaykinAppModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Session Summary")
                .font(.title)
                .accessibilityIdentifier("waykin.summary.screen")

            Text("Experience: \(summary.experience)")
                .accessibilityIdentifier("waykin.summary.experience")

            Text("Outcome: \(summary.outcome)")
                .accessibilityIdentifier("waykin.summary.outcome")

            Text("Duration: \(Int(summary.duration))s")
                .accessibilityIdentifier("waykin.summary.duration")

            Text("Memory: \(summary.memory.text)")
                .accessibilityIdentifier("waykin.summary.memory")

            Button("Back to Home") {
                appModel.returnHome()
            }
            .accessibilityIdentifier("waykin.summary.home")
        }
        .padding()
    }
}

struct MemoryHistoryView: View {
    @Bindable var appModel: WaykinAppModel

    var body: some View {
        VStack {
            Text("Memory History")
                .font(.title)
                .accessibilityIdentifier("waykin.memory.screen")

            if appModel.memories.isEmpty {
                Text("No memories yet")
                    .accessibilityIdentifier("waykin.memory.empty")
            } else {
                List(appModel.memories, id: \.id) { mem in
                    Text(mem.text)
                        .accessibilityIdentifier("waykin.memory.item.\(mem.id.uuidString)")
                }
            }
        }
        .padding()
        .onAppear {
            appModel.memories = appModel.persistenceStore.loadMemories()
            appModel.persistenceMemoryCount = appModel.persistenceStore.memoryCount()
        }
    }
}
