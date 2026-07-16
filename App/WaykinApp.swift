import SwiftUI
import WaykinCore

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
    let persistenceStore = PersistenceStore()
    let recommendationEngine = RecommendationEngine()
    let demoController: DemoSessionController
    
    var companion: Companion
    var activeRecommendation: ExperienceRecommendation?
    var lastSummary: SessionSummary?
    var demoMessage = ""
    
    init() {
        self.demoController = DemoSessionController(movementEngine: movementEngine)
        
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
            for: "day",
            lastExperience: companion.lastSessionID?.uuidString,
            activity: .walk
        ).first
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

struct HomeView: View {
    @Bindable var appModel: WaykinAppModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Waykin").font(.largeTitle.bold())
            
            Text("Companion: \(appModel.companion.name) • Bond \(appModel.companion.bondLevel)")
            
            if let rec = appModel.activeRecommendation {
                Text("Recommended: \(rec.experienceID) (\(rec.variantID))")
                    .font(.caption)
            }
            
            Divider()
            
            Text("Demo Scenarios")
            ForEach(DemoScenarioID.allCases, id: \.self) { scenario in
                Button("Start \(scenario.rawValue)") {
                    appModel.startDemo(scenario)
                }
            }
            
            if appModel.demoController.isRunning {
                VStack {
                    Text(appModel.demoController.presentationState.statusText)
                    HStack {
                        Button("Pause") { appModel.pauseDemo() }
                        Button("Resume") { appModel.resumeDemo() }
                        Button("Advance Tick") { appModel.advanceDemo() }
                        Button("Run to End") { appModel.runDemoToEnd() }
                        Button("End Session") { appModel.endDemo() }
                    }
                }
            }
            
            if !appModel.demoMessage.isEmpty {
                Text(appModel.demoMessage).font(.caption)
            }
            
            if let summary = appModel.lastSummary {
                VStack {
                    Text("Last Summary: \(summary.outcome) • +\(summary.bondDelta) bond")
                    Text(summary.memory.text).font(.caption2)
                }
            }
            
            Button("Reset Demo Data") { appModel.resetDemoData() }
                .foregroundStyle(.red)
        }
        .padding()
    }
}
