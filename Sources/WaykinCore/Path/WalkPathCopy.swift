import Foundation

/// Privacy-safe human copy for path progress and activity bands.
/// No coordinates, no raw step counts, no medical claims.
public enum WalkPathCopy {
    /// One-line path status for session summary / diagnostics.
    public static func pathLine(relation: PathRelation, metersAlongPath: Double) -> String {
        let meters = max(0, Int(metersAlongPath.finiteOrZero))
        let meterText = "\(meters) m along the path"
        switch relation {
        case .establishing:
            return meters == 0 ? "Path establishing" : "Path establishing · \(meterText)"
        case .onPath:
            return "Path held steady · \(meterText)"
        case .strained:
            return "Path felt strained · \(meterText)"
        case .offPath:
            return "Path slipped · \(meterText)"
        case .recovered:
            return "Path found again · \(meterText)"
        }
    }

    /// Optional cadence line; nil when unknown so UI can hide it.
    public static func cadenceLine(band: StepCadenceBand) -> String? {
        switch band {
        case .unknown:
            return nil
        case .low:
            return "Steps felt light"
        case .moderate:
            return "Steps felt steady"
        case .high:
            return "Steps felt strong"
        }
    }

    /// Short memory clause (no period); nil when nothing distinctive to say.
    public static func memorySuffix(relation: PathRelation) -> String? {
        switch relation {
        case .establishing:
            return nil
        case .onPath:
            return "the path held steady"
        case .strained:
            return "the path felt strained"
        case .offPath:
            return "the path slipped for a while"
        case .recovered:
            return "the path found you again"
        }
    }

    /// Append a path clause to an existing memory sentence.
    public static func appendingMemorySuffix(to memory: String, relation: PathRelation) -> String {
        guard let suffix = memorySuffix(relation: relation) else { return memory }
        let trimmed = memory.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Lira stayed close; \(suffix)." }
        if trimmed.hasSuffix(".") {
            let without = String(trimmed.dropLast())
            return "\(without); \(suffix)."
        }
        return "\(trimmed); \(suffix)."
    }
}
