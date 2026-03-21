import SwiftUI

struct AppColors {
    enum Brand {
        static let blue = Color(hex: "#253141")
        static let gold = Color(hex: "#E6D19E")
    }

    enum Light {
        static let background = Color(hex: "#F5F5F5")
        static let surface = Color(hex: "#FFFFFF")
        static let primary = Color(hex: "#253141")
        static let accent = Color(hex: "#E6D19E")
        static let textPrimary = Color(hex: "#121212")
        static let textSecondary = Color(hex: "#6B6B6B")
        static let divider = Color(hex: "#E0E0E0")
    }

    enum Dark {
        static let background = Color(hex: "#253141")
        static let surface = Color(hex: "#2F2F2F")
        static let elevated = Color(hex: "#3A3A3A")
        static let primary = Color(hex: "#E6D19E")
        static let textPrimary = Color(hex: "#F5F5F5")
        static let textSecondary = Color(hex: "#A1A1A1")
        static let divider = Color(hex: "#3A3A3A")
    }

    static let brandBlue = Brand.blue
    static let brandGold = Brand.gold

    static let lightBackground = Light.background
    static let lightSurface = Light.surface
    static let lightPrimary = Light.primary
    static let lightAccent = Light.accent
    static let lightTextPrimary = Light.textPrimary
    static let lightTextSecondary = Light.textSecondary
    static let lightDivider = Light.divider

    static let darkBackground = Dark.background
    static let darkSurface = Dark.surface
    static let darkElevated = Dark.elevated
    static let darkPrimary = Dark.primary
    static let darkTextPrimary = Dark.textPrimary
    static let darkTextSecondary = Dark.textSecondary
    static let darkDivider = Dark.divider

    static let gold = Brand.gold
}

extension Color {
    init(hex: String) {
        let sanitizedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitizedHex).scanHexInt64(&int)

        let alpha: UInt64
        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch sanitizedHex.count {
        case 3:
            alpha = 255
            red = ((int >> 8) & 0xF) * 17
            green = ((int >> 4) & 0xF) * 17
            blue = (int & 0xF) * 17
        case 6:
            alpha = 255
            red = int >> 16
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
        case 8:
            alpha = int >> 24
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
        default:
            alpha = 255
            red = 0
            green = 0
            blue = 0
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
