import SwiftUI

enum GlassAppearance {
    static let privateAccent = Color(red: 1.0, green: 0.48, blue: 0.29)
    static let privateBackground = Color(red: 0.075, green: 0.035, blue: 0.035)

    static let presets = ["violet", "ocean", "emerald", "rose"]

    static func accent(for preset: String) -> Color {
        switch preset {
        case "ocean": return Color(red: 0.34, green: 0.72, blue: 1.0)
        case "emerald": return Color(red: 0.30, green: 0.86, blue: 0.64)
        case "rose": return Color(red: 1.0, green: 0.43, blue: 0.68)
        default: return Color(red: 0.68, green: 0.53, blue: 1.0)
        }
    }

    static func previewColors(for preset: String) -> [Color] {
        switch preset {
        case "ocean":
            return [Color(red: 0.035, green: 0.18, blue: 0.34), Color(red: 0.12, green: 0.48, blue: 0.68), Color(red: 0.22, green: 0.72, blue: 0.88)]
        case "emerald":
            return [Color(red: 0.025, green: 0.20, blue: 0.15), Color(red: 0.08, green: 0.48, blue: 0.34), Color(red: 0.30, green: 0.72, blue: 0.48)]
        case "rose":
            return [Color(red: 0.24, green: 0.045, blue: 0.16), Color(red: 0.62, green: 0.16, blue: 0.38), Color(red: 0.94, green: 0.38, blue: 0.58)]
        default:
            return [Color(red: 0.10, green: 0.055, blue: 0.24), Color(red: 0.34, green: 0.18, blue: 0.58), Color(red: 0.62, green: 0.38, blue: 0.90)]
        }
    }

    static func title(for preset: String) -> String {
        switch preset {
        case "ocean": return "Ocean"
        case "emerald": return "Emerald"
        case "rose": return "Rose"
        default: return "Violet"
        }
    }

    static func symbol(for preset: String) -> String {
        switch preset {
        case "ocean": return "water.waves"
        case "emerald": return "leaf.fill"
        case "rose": return "sparkles"
        default: return "circle.hexagongrid.fill"
        }
    }

    static var panelOpacity: Double {
        UserDefaults.standard.object(forKey: "glass.theme.panelOpacity") == nil
            ? 0.075 : UserDefaults.standard.double(forKey: "glass.theme.panelOpacity")
    }

    static var glow: Double {
        UserDefaults.standard.object(forKey: "glass.theme.glow") == nil
            ? 0.55 : UserDefaults.standard.double(forKey: "glass.theme.glow")
    }

    static var cornerRadius: Double {
        UserDefaults.standard.object(forKey: "glass.theme.cornerRadius") == nil
            ? 20 : UserDefaults.standard.double(forKey: "glass.theme.cornerRadius")
    }
}
