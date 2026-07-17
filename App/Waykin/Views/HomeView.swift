import SwiftUI
import WaykinCore

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedExperienceID: String?

    private var brain: CompanionEngine { appState.companionEngine! }

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingCard
                    recommendationSection
                    memoriesSection
                }
                .padding()
            }
            .navigationTitle("Waykin")
            .navigationDestination(item: $selectedExperienceID) { experienceID in
                SessionView(experienceID: experienceID)
            }
            .sheet(item: $appState.lastSummary) { summary in
                SummaryView(summary: summary)
            }
            .onAppear {
                // Dev/demo shortcut: `--demo-open <experience-id>` jumps
                // straight into a session screen.
                let arguments = ProcessInfo.processInfo.arguments
                if let flag = arguments.firstIndex(of: "--demo-open"),
                   arguments.indices.contains(flag + 1) {
                    selectedExperienceID = arguments[flag + 1]
                }
            }
        }
    }

    private var greetingCard: some View {
        VStack(spacing: 12) {
            CompanionAvatar(species: brain.companion.species)
                .frame(height: 100)
            Text(brain.companion.name)
                .font(.title2.bold())
            Text(brain.greeting(now: Date()))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label(brain.companion.relationship.level.displayName, systemImage: "heart.fill")
                Label("\(brain.companion.totalSessions) journeys", systemImage: "figure.walk")
                Label(String(format: "%.1f km", brain.companion.totalDistanceMeters / 1000),
                      systemImage: "map")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's adventures")
                .font(.headline)
            ForEach(appState.recommendations(), id: \.experienceID) { recommendation in
                Button {
                    selectedExperienceID = recommendation.experienceID
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendation.experienceName)
                                .font(.body.weight(.semibold))
                            Text(recommendation.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var memoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shared memories")
                .font(.headline)
            let memories = appState.memoryEngine.recentMemories(limit: 5)
            if memories.isEmpty {
                Text("No memories yet — your first journey together makes the first one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(memories) { memory in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("“\(memory.text)”")
                            .font(.callout)
                        Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}
