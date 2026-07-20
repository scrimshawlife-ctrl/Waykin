import Foundation

/// Human-readable AR chrome hints derived from placement continuity notes (#147 / #125).
/// Presentation only — never invents tracking or gameplay truth.
enum ARContinuityHint {
    /// Quiet directional copy for operators; nil when presence is fine.
    static func message(from continuityNote: String) -> String? {
        let note = continuityNote.lowercased()
        if note == "none" || note == "cleared" { return nil }
        if note.hasPrefix("ok_present") { return nil }
        // Prefer final plant modality over intermediate reason tokens.
        if note.contains("planted_camera") || note.contains("camera_fallback") {
            return "Holding Lira near you (no ground yet)"
        }
        if note.contains("ground_raycast_failed") {
            return "Looking for the ground"
        }
        if note.contains("replant_missing") {
            return "Looking for Lira again"
        }
        if note.contains("replant_far") {
            return "Lira was far — re-planting ahead"
        }
        if note.contains("replant") {
            return "Re-planting Lira ahead"
        }
        return nil
    }
}
