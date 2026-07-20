import SwiftUI
import UIKit

/// Session still LOD names. When an imageset exists in the asset catalog, prefer it over the Canvas puppet.
enum LiraStillCatalog {
    /// Which 2D graphics path is active for a pose×skin (outdoor QA / #133 diagnostics).
    enum GraphicsPath: String, Equatable, Sendable, CaseIterable {
        /// Spectral still loaded from `Assets.xcassets/LiraStills`.
        case catalogStill
        /// Procedural Canvas puppet (catalog miss or unloadable image).
        case canvasFallback

        /// Operator-facing diagnostic string (session HUD / a11y / receipts).
        var diagnosticLabel: String {
            switch self {
            case .catalogStill: return "still:catalog"
            case .canvasFallback: return "still:canvas_fallback"
            }
        }
    }

    /// Generated spectral art (non-mascot). Full 7×3 pose×skin matrix + glyphs; missing names fall back to Canvas puppet.
    static func imageName(pose: LiraSessionPose, skin: LiraSkin) -> String? {
        let poseToken: String
        switch pose {
        case .guide: poseToken = "Guide"
        case .rival: poseToken = "Rival"
        case .hunter: poseToken = "Hunter"
        case .sanctuary: poseToken = "Sanctuary"
        case .bond: poseToken = "Bond"
        case .dormant: poseToken = "Dormant"
        case .manifesting: poseToken = "Manifesting"
        }
        let skinToken: String
        switch skin {
        case .dawn: skinToken = "Dawn"
        case .veil: skinToken = "Veil"
        case .rupture: skinToken = "Rupture"
        }
        return "Lira_Session_\(poseToken)_\(skinToken)"
    }

    static func hasStill(pose: LiraSessionPose, skin: LiraSkin) -> Bool {
        guard let name = imageName(pose: pose, skin: skin) else { return false }
        return UIImage(named: name) != nil
    }

    /// Resolve whether catalog still or Canvas fallback will be used.
    static func graphicsPath(pose: LiraSessionPose, skin: LiraSkin) -> GraphicsPath {
        hasStill(pose: pose, skin: skin) ? .catalogStill : .canvasFallback
    }

    /// Full 7×3 matrix diagnostics (tests / field prep).
    static func catalogCoverage() -> (present: Int, missing: [(LiraSessionPose, LiraSkin)]) {
        var present = 0
        var missing: [(LiraSessionPose, LiraSkin)] = []
        for pose in LiraSessionPose.allCases {
            for skin in LiraSkin.allCases {
                if hasStill(pose: pose, skin: skin) {
                    present += 1
                } else {
                    missing.append((pose, skin))
                }
            }
        }
        return (present, missing)
    }

    static func glyphName(for skin: LiraSkin) -> String {
        switch skin {
        case .dawn: return "Lira_Glyph_Dawn"
        case .veil: return "Lira_Glyph_Veil"
        case .rupture: return "Lira_Glyph_Rupture"
        }
    }

    /// Back-compat
    static let glyphDawn = "Lira_Glyph_Dawn"
}

/// Compact glyph LOD (head + chest + filament tip).
struct LiraGlyphView: View {
    var size: CGFloat = 32
    var skin: LiraSkin = .dawn

    var body: some View {
        let name = LiraStillCatalog.glyphName(for: skin)
        Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                proceduralGlyph
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var proceduralGlyph: some View {
        Canvas { context, canvasSize in
            let u = min(canvasSize.width, canvasSize.height) / 64
            let body: Color
            let fringe: Color
            let bond: Color
            switch skin {
            case .dawn:
                body = Color(red: 0.91, green: 0.85, blue: 0.77)
                fringe = Color(red: 0.25, green: 0.56, blue: 0.54)
                bond = Color(red: 0.83, green: 0.64, blue: 0.35)
            case .veil:
                body = Color(red: 0.16, green: 0.18, blue: 0.22)
                fringe = Color(red: 0.48, green: 0.55, blue: 0.62)
                bond = Color(red: 0.79, green: 0.54, blue: 0.48)
            case .rupture:
                body = Color(red: 0.29, green: 0.27, blue: 0.35)
                fringe = Color(red: 0.54, green: 0.59, blue: 0.66)
                bond = Color(red: 0.83, green: 0.64, blue: 0.35)
            }
            var fil = Path()
            fil.move(to: CGPoint(x: 18 * u, y: 36 * u))
            fil.addCurve(
                to: CGPoint(x: 4 * u, y: 48 * u),
                control1: CGPoint(x: 10 * u, y: 34 * u),
                control2: CGPoint(x: 6 * u, y: 40 * u)
            )
            context.stroke(fil, with: .color(fringe), style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: 20 * u, y: 26 * u, width: 28 * u, height: 20 * u)), with: .color(body))
            context.fill(Path(ellipseIn: CGRect(x: 38 * u, y: 18 * u, width: 16 * u, height: 14 * u)), with: .color(body))
            context.fill(Path(ellipseIn: CGRect(x: 30 * u, y: 32 * u, width: 8 * u, height: 8 * u)), with: .color(bond))
        }
    }
}
