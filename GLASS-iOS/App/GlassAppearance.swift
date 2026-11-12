import SwiftUI

enum GlassAppearance {
    static let presets = ["violet", "ocean", "emerald", "rose"]

    static func accent(for preset: String) -> Color {
        switch preset {
        case "ocean": return Color(red: 0.34, green: 0.72, blue: 1.0)
        case "emerald": return Color(red: 0.30, green: 0.86, blue: 0.64)
        case "rose": return Color(red: 1.0, green: 0.43, blue: 0.68)
        default: return Color(red: 0.68, green: 0.53, blue: 1.0)
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
