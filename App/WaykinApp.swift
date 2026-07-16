import SwiftUI
import WaykinCore

@main
struct WaykinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
    @State private var demoRunning = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Waykin MPOC")
                    .font(.largeTitle)
                Text("Companion: \(companion.name) • Bond \(companion.bondLevel)")
                Button("Run Demo Session (Simulated)") {
                    runDemo()
                }
                .buttonStyle(.borderedProminent)

                if demoRunning {
                    Text("Demo complete. Check console or memory history.")
                }

                NavigationLink("Start Real Session (Map/AR placeholder)") {
                    SessionView()
                }
            }
            .padding()
        }
    }

    func runDemo() {
        // In real app this would launch the full engines
        demoRunning = true
        // Call into WaykinDemo logic or MovementEngine here
    }
}

struct SessionView: View {
    var body: some View {
        Text("Active Session View (PHONE_MAP + AR stub)")
            .navigationTitle("Session")
    }
}
