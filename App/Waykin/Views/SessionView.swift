import SwiftUI
import WaykinCore

/// Live session: AR companion on top, experience HUD below.
struct SessionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let experienceID: String

    @State private var locationService = LocationService()
    @State private var runner: ExperienceRunner?
    @State private var registration: ExperienceEngine.Registration?
    @State private var behavior: CompanionBehavior = .idle
    @State private var dialogue: String = ""
    @State private var threat: Double?
    @State private var ghostGap: Double?
    @State private var milestone: String?
    @State private var started = false
    @State private var isMoving = true
    private let receiptBuilder = SessionReceiptBuilder(
        mode: ProcessInfo.processInfo.arguments.contains("--demo-autostart") ? .simulated : .physical)

    var body: some View {
        ZStack(alignment: .bottom) {
            ARCompanionView(species: appState.companionEngine!.companion.species,
                            behavior: $behavior)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                if let milestone {
                    Label(milestone, systemImage: "star.fill")
                        .font(.headline)
                        .padding(8)
                        .background(.yellow.opacity(0.85), in: Capsule())
                }
                if !dialogue.isEmpty {
                    Text(dialogue)
                        .font(.callout)
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                if started {
                    Text(PresenceNarrator.phrase(
                        companionName: appState.companionEngine!.companion.name,
                        behavior: behavior, threat: threat,
                        ghostGapMeters: ghostGap, isMoving: isMoving))
                        .font(.footnote.italic())
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("waykin.session.phrase")
                }
                hud
                controls
            }
            .padding()
        }
        .navigationBarBackButtonHidden(started)
        .onAppear {
            prepare()
            if ProcessInfo.processInfo.arguments.contains("--demo-autostart"), !started {
                start()
            }
        }
        .onDisappear { _ = locationService.endSession() }
    }

    private var hud: some View {
        HStack(spacing: 20) {
            if let update = locationService.latestUpdate {
                metric("Distance", String(format: "%.2f km", update.distanceMeters / 1000))
                metric("Time", format(seconds: update.elapsedSeconds))
                if let pace = update.paceSecondsPerKm {
                    metric("Pace", format(seconds: pace) + "/km")
                }
            } else {
                Text(started ? "Waiting for GPS…" : "Ready")
                    .foregroundStyle(.secondary)
            }
            if let threat {
                metric("Threat", String(format: "%.0f%%", threat * 100))
                    .foregroundStyle(threat > 0.65 ? .red : .primary)
            }
            if let ghostGap {
                metric("Ghost", String(format: "%+.0f m", ghostGap))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var controls: some View {
        Group {
            if started {
                Button(role: .destructive) {
                    finish()
                } label: {
                    Text("End session").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("waykin.session.end")
            } else {
                Button {
                    start()
                } label: {
                    Text("Start \(registration?.name ?? "")").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(runner == nil)
                .accessibilityIdentifier("waykin.session.start")
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func prepare() {
        locationService.requestPermission()
        guard registration == nil,
              let reg = appState.experiences.available.first(where: { $0.id == experienceID }),
              let experience = appState.experiences.makeExperience(id: experienceID),
              let brain = appState.companionEngine else { return }
        registration = reg
        let hour = Calendar.current.component(.hour, from: Date())
        let visits = appState.memoryEngine.locationMemory(named: locationService.locationName)?.visitCount ?? 0
        runner = ExperienceRunner(
            experience: experience,
            context: ExperienceContext(companion: brain.companion,
                                       locationName: locationService.locationName,
                                       timeOfDay: .from(hour: hour),
                                       weather: .clear,
                                       placeFamiliarity: min(1, Double(visits) / 3)))
    }

    private func start() {
        guard let runner else { return }
        started = true
        handle(events: runner.begin())
        locationService.onUpdate = { update in
            Task { @MainActor in
                handle(events: runner.handle(update))
            }
        }
        locationService.startSession(activity: nil)
    }

    private func finish() {
        guard let runner, let registration,
              let session = locationService.endSession() else { dismiss(); return }
        let outcome = runner.finish(session: session)
        let summary = appState.completeSession(session, outcome: outcome,
                                               registration: registration,
                                               locationName: locationService.locationName)
        let receipt = receiptBuilder.finalize(
            session: session, outcome: outcome,
            companionName: appState.companionEngine?.companion.name ?? "?",
            experienceID: registration.id, experienceName: registration.name,
            locationName: locationService.locationName,
            memory: summary?.memory)
        try? AppState.receiptStore.save(receipt)
        dismiss()
    }

    private func handle(events: [ExperienceEvent]) {
        receiptBuilder.record(events)
        if let latest = locationService.latestUpdate { isMoving = latest.isMoving }
        for event in events {
            switch event {
            case .dialogue(let line): dialogue = line
            case .companionBehavior(let newBehavior): behavior = newBehavior
            case .threatLevel(let level): threat = level
            case .ghostDistance(let gap): ghostGap = gap
            case .milestone(let text):
                milestone = text
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    if milestone == text { milestone = nil }
                }
            case .audio(let cue):
                AudioService.shared.play(cue)
            }
        }
    }

    private func format(seconds: TimeInterval) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
