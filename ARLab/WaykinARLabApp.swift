import SwiftUI

@main
struct WaykinARLabApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ARSessionShellView()
                    .navigationTitle("Waykin AR Lab")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
