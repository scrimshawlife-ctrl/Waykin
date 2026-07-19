import SwiftUI
import UIKit

/// Session still LOD names. When an imageset exists in the asset catalog, prefer it over the Canvas puppet.
enum LiraStillCatalog {
    static func imageName(pose: LiraSessionPose, skin: LiraSkin) -> String? {
        // Time-cut stills: guide/hunter/sanctuary for Dawn; guide for Veil/Rupture.
        switch (pose, skin) {
        case (.guide, .dawn): return "Lira_Session_Guide_Dawn"
        case (.hunter, .dawn): return "Lira_Session_Hunter_Dawn"
        case (.sanctuary, .dawn): return "Lira_Session_Sanctuary_Dawn"
        case (.guide, .veil): return "Lira_Session_Guide_Veil"
        case (.guide, .rupture): return "Lira_Session_Guide_Rupture"
        default: return nil
        }
    }

    static func hasStill(pose: LiraSessionPose, skin: LiraSkin) -> Bool {
        guard let name = imageName(pose: pose, skin: skin) else { return false }
        return UIImage(named: name) != nil
    }
}
