import SwiftUI
import WaykinCore
import MapKit
import SwiftData

@main
struct WaykinApp: App {
    @State private var appModel = WaykinAppModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(appModel: appModel)
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

    init() {
        if let container = try? ModelContainer(for: CompanionRecord.self, SessionMemoryRecord.self) {
            self.persistenceStore = PersistenceStore(modelContainer: container)
        } else {
            self.persistenceStore = PersistenceStore()
        }

        self.demoController = DemoSessionController(movementEngine: movementEngine)

        let isUITesting = ProcessInfo.processInfo.arguments.contains("-WAYKIN_UI_TESTING")
        let shouldReset = ProcessInfo.processInfo.arguments.contains("-WAYKIN_RESET_STATE")

        if shouldReset || isUITesting {
            persistenceStore.resetDemoData()
        }

        if let loaded = persistenceStore.loadCompanion() {
            self.companion = loaded
        } else {
            self.companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
            persistenceStore.saveCompanion(self.companion)
        }
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
            updated.memories.append(mem)
            persistenceStore.saveCompanion(updated)
            persistenceStore.saveMemory(mem)
            companion = updated
            lastSummary = summary
            demoMessage = "Session ended: \(result.outcome). Bond +\(result.bondDelta)"
            refreshRecommendation()
        }
    }

    func resetDemoData() {
        persistenceStore.resetDemoData()
        companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
        persistenceStore.saveCompanion(companion)
        lastSummary = nil
        demoMessage = "Data reset"
    }
}

// MARK: - Views

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

            NavigationLink("Demo Scenarios", value: "demoList")
                .accessibilityIdentifier("waykin.demo.open")

            NavigationLink("Memory History", value: "memory")
                .accessibilityIdentifier("waykin.memory.open")

            Divider()

            Text("Time Context (for testing)")
            HStack {
                Button("Day") { appModel.setTimeContext("day") }
                Button("Night") { appModel.setTimeContext("night") }
            }

            if !appModel.demoMessage.isEmpty {
                Text(appModel.demoMessage)
            }

            if let summary = appModel.lastSummary {
                VStack {
                    Text("Last Summary: \(summary.outcome) • +\(summary.bondDelta) bond")
                    Text(summary.memory.text).font(.caption2)
                }
            }

            Button("Reset Demo Data") {
                appModel.resetDemoData()
            }
            .foregroundStyle(.red)
        }
        .padding()
        .navigationDestination(for: String.self) { value in
            if value == "demoList" {
                DemoScenarioListView(appModel: appModel)
            } else if value == "memory" {
                MemoryHistoryView(appModel: appModel)
            }
        }
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
                NavigationLink(value: scenario) {
                    Text(scenario.rawValue)
                }
                .accessibilityIdentifier("waykin.demo.scenario.\(scenario.rawValue)")
            }
        }
        .navigationDestination(for: DemoScenarioID.self) { scenario in
            ActiveSessionView(appModel: appModel, scenario: scenario)
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

            // MapKit rendering (simple static region for smoke proof)
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
        .onAppear {
            if !appModel.demoController.isRunning {
                appModel.startDemo(scenario)
            }
        }
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    let memory: SessionMemory?

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

            if let memory = memory {
                Text("Memory: \(memory.text)")
                    .accessibilityIdentifier("waykin.summary.memory")
            }

            NavigationLink("Back to Home", value: "home")
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

            List(appModel.companion.memories, id: \.id) { mem in
                Text(mem.text)
                    .accessibilityIdentifier("waykin.memory.item")
            }
        }
        .padding()
    }
}
