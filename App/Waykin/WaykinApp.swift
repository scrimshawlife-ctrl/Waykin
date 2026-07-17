import SwiftUI
import SwiftData
import WaykinCore

@main
struct WaykinApp: App {
    let container: ModelContainer
    @State private var appState: AppState

    init() {
        do {
            container = try ModelContainer(
                for: StoredCompanion.self, StoredMemory.self, StoredLocationMemory.self)
        } catch {
            fatalError("Failed to open SwiftData store: \(error)")
        }
        _appState = State(initialValue: AppState(context: ModelContext(container)))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.companionEngine == nil {
            OnboardingView()
        } else {
            HomeView()
        }
    }
}
