import SwiftUI
import WaykinCore

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var species: Companion.Species = .emberfox

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Waykin")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text("Every walk is a shared adventure.\nChoose who walks beside you.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Picker("Species", selection: $species) {
                ForEach(Companion.Species.allCases, id: \.self) { species in
                    Text(species.displayName).tag(species)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            CompanionAvatar(species: species, behavior: .idle)
                .frame(height: 140)

            TextField("Name your companion", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Button {
                appState.createCompanion(
                    name: name.trimmingCharacters(in: .whitespaces),
                    species: species)
            } label: {
                Text("Begin the journey")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
    }
}

/// 2D companion stand-in used outside AR (onboarding, home, HUD).
struct CompanionAvatar: View {
    let species: Companion.Species
    var behavior: CompanionBehavior = .idle
    @State private var bounce = false

    private var symbol: String {
        switch species {
        case .emberfox: return "flame.fill"
        case .mosswing: return "leaf.fill"
        case .tidewolf: return "water.waves"
        }
    }

    private var color: Color {
        switch species {
        case .emberfox: return .orange
        case .mosswing: return .green
        case .tidewolf: return .teal
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 72))
            .foregroundStyle(color.gradient)
            .scaleEffect(bounce ? 1.08 : 0.96)
            .rotationEffect(.degrees(behavior == .celebrate ? (bounce ? 8 : -8) : 0))
            .animation(.easeInOut(duration: animationPeriod).repeatForever(autoreverses: true), value: bounce)
            .onAppear { bounce = true }
    }

    private var animationPeriod: Double {
        switch behavior {
        case .run, .celebrate: return 0.3
        case .walk, .follow: return 0.6
        case .idle, .alert: return 1.2
        }
    }
}
