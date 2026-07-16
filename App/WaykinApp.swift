import SwiftUI
import WaykinCore

@main
struct WaykinApp: App {
    @State private var appModel = AppModel()

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
final class AppModel {
    let movementEngine = MovementEngine()
    let memoryEngine = MemoryEngine()
    let recommendationEngine = RecommendationEngine()
    let persistence = PersistenceStore()

    var companion: Companion
    var currentRecommendation: ExperienceRecommendation?
    var lastMemory: SessionMemory?
    var isInDemo = false
    var demoMessage = ""

    init() {
        // Try to load persisted companion or create default
        if let loaded = persistence.loadCompanion() {
            self.companion = loaded
        } else {
            self.companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
            persistence.saveCompanion(self.companion)
        }
        self.currentRecommendation = recommendationEngine.recommend(for: "day", lastExperience: nil, activity: .walk).first
        self.lastMemory = persistence.loadMemories().first
    }

    func startNativeDemo() {
        isInDemo = true
        demoMessage = "Demo Mode: Simulating NIGHT_ORC_PURSUIT..."

        // Use the real engine
        try? movementEngine.startSession(activity: .walk, experienceID: "orc_pursuit")

        // Simulate a short session
        for _ in 0..<8 {
            movementEngine.simulate(deltaSeconds: 10, speed: Double.random(in: 1.5...3.0))
        }

        guard let session = movementEngine.currentSession else { return }

        let exp = OrcPursuitExperience()
        let context = ExperienceContext(timeOfDay: "night", activity: .walk)
        let state = exp.start(context: context)
        let result = exp.finish(state: state, session: session)

        let memory = memoryEngine.createMemory(session: session, result: result, companion: companion)
        persistence.saveMemory(memory)

        companion.bondLevel += result.bondDelta
        companion.memories.append(memory)
        persistence.saveCompanion(companion)

        lastMemory = memory
        demoMessage = "Demo complete. Memory saved. Bond now \(companion.bondLevel)."
        isInDemo = false
    }

    func refreshRecommendation() {
        currentRecommendation = recommendationEngine.recommend(for: "day", lastExperience: companion.lastSessionID?.uuidString, activity: .walk).first
    }
}

struct HomeView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Waykin")
                .font(.largeTitle.bold())

            Text("Companion: \(appModel.companion.name) • Bond \(appModel.companion.bondLevel)")
                .font(.headline)

            if let rec = appModel.currentRecommendation {
                VStack {
                    Text("Recommended: \(rec.experienceID)")
                    Text(rec.observedReasons.joined(separator: ", "))
                        .font(.caption)
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(12)
            }

            Button("Start Native Demo (NIGHT_ORC_PURSUIT)") {
                appModel.startNativeDemo()
            }
            .buttonStyle(.borderedProminent)

            if !appModel.demoMessage.isEmpty {
                Text(appModel.demoMessage)
                    .font(.caption)
            }

            if let mem = appModel.lastMemory {
                Text("Last Memory: \(mem.text)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Refresh Recommendation") {
                appModel.refreshRecommendation()
            }
        }
        .padding()
        .onAppear {
            appModel.refreshRecommendation()
        }
    }
}
