import SwiftUI
import WaykinCore

struct SummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let summary: SessionSummary

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: summary.outcome.succeeded ? "checkmark.seal.fill" : "figure.walk.motion")
                .font(.system(size: 56))
                .foregroundStyle(summary.outcome.succeeded ? .green : .orange)
            Text(summary.outcome.summaryLine)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                stat(String(format: "%.2f km", summary.session.distanceMeters / 1000), "Distance")
                stat(format(summary.session.durationSeconds), "Time")
                if let pace = summary.session.averagePaceSecondsPerKm {
                    stat(format(pace) + "/km", "Pace")
                }
            }

            VStack(spacing: 8) {
                Label("+\(summary.outcome.bondDelta) bond", systemImage: "heart.fill")
                    .foregroundStyle(.pink)
                if summary.levelAfter > summary.levelBefore {
                    Text("\(summary.levelBefore.displayName) → \(summary.levelAfter.displayName)")
                        .font(.headline)
                        .foregroundStyle(.pink)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("New memory")
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                Text("“\(summary.memory.text)”")
                    .font(.callout.italic())
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                dismiss()
            } label: {
                Text("Until next time").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func format(_ seconds: TimeInterval) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
