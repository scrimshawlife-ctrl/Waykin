import SwiftUI
import UIKit

/// Session still LOD names. When an imageset exists in the asset catalog, prefer it over the Canvas puppet.
enum LiraStillCatalog {
    static func imageName(pose: LiraSessionPose, skin: LiraSkin) -> String? {
        // Full Dawn matrix; Veil/Rupture guide stills; others fall back to puppet.
        switch (pose, skin) {
        case (.guide, .dawn): return "Lira_Session_Guide_Dawn"
        case (.hunter, .dawn): return "Lira_Session_Hunter_Dawn"
        case (.sanctuary, .dawn): return "Lira_Session_Sanctuary_Dawn"
        case (.rival, .dawn): return "Lira_Session_Rival_Dawn"
        case (.bond, .dawn): return "Lira_Session_Bond_Dawn"
        case (.dormant, .dawn): return "Lira_Session_Dormant_Dawn"
        case (.manifesting, .dawn): return "Lira_Session_Manifesting_Dawn"
        case (.guide, .veil): return "Lira_Session_Guide_Veil"
        case (.guide, .rupture): return "Lira_Session_Guide_Rupture"
        default: return nil
        }
    }

    static func hasStill(pose: LiraSessionPose, skin: LiraSkin) -> Bool {
        guard let name = imageName(pose: pose, skin: skin) else { return false }
        return UIImage(named: name) != nil
    }

    static let glyphDawn = "Lira_Glyph_Dawn"
}

/// Compact glyph LOD (head + chest + filament tip).
struct LiraGlyphView: View {
    var size: CGFloat = 32
    var skin: LiraSkin = .dawn

    var body: some View {
        Group {
            if skin == .dawn, UIImage(named: LiraStillCatalog.glyphDawn) != nil {
                Image(LiraStillCatalog.glyphDawn)
                    .resizable()
                    .scaledToFit()
            } else {
                // Procedural fallback glyph
                Canvas { context, canvasSize in
                    let u = min(canvasSize.width, canvasSize.height) / 64
                    var fil = Path()
                    fil.move(to: CGPoint(x: 18 * u, y: 36 * u))
                    fil.addCurve(
                        to: CGPoint(x: 4 * u, y: 48 * u),
                        control1: CGPoint(x: 10 * u, y: 34 * u),
                        control2: CGPoint(x: 6 * u, y: 40 * u)
                    )
                    context.stroke(fil, with: .color(Color(red: 0.25, green: 0.56, blue: 0.54)), style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                    context.fill(Path(ellipseIn: CGRect(x: 20 * u, y: 26 * u, width: 28 * u, height: 20 * u)), with: .color(Color(red: 0.91, green: 0.85, blue: 0.77)))
                    context.fill(Path(ellipseIn: CGRect(x: 38 * u, y: 18 * u, width: 16 * u, height: 14 * u)), with: .color(Color(red: 0.91, green: 0.85, blue: 0.77)))
                    context.fill(Path(ellipseIn: CGRect(x: 30 * u, y: 32 * u, width: 8 * u, height: 8 * u)), with: .color(Color(red: 0.83, green: 0.64, blue: 0.35)))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
