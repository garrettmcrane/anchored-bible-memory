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

    static let background = dynamic(light: Light.background, dark: Dark.background)
    static let surface = dynamic(light: Light.surface, dark: Dark.surface)
    static let elevatedSurface = dynamic(light: Light.surface, dark: Dark.elevated)
    static let secondarySurface = dynamic(light: Color(hex: "#EEEAE1"), dark: Dark.elevated)
    static let textPrimary = dynamic(light: Light.textPrimary, dark: Dark.textPrimary)
    static let textSecondary = dynamic(light: Light.textSecondary, dark: Dark.textSecondary)
    static let divider = dynamic(light: Light.divider, dark: Dark.divider)
    static let structuralAccent = dynamic(light: Light.primary, dark: Dark.textPrimary)
    static let scriptureAccent = dynamic(light: Brand.gold, dark: Brand.gold)
    static let subtleAccent = dynamic(light: Brand.gold.opacity(0.16), dark: Brand.gold.opacity(0.12))
    static let primaryButton = dynamic(light: Brand.blue, dark: Brand.blue)
    static let primaryButtonText = dynamic(light: Light.surface, dark: Dark.textPrimary)
    static let secondaryButton = dynamic(light: Brand.gold, dark: Brand.gold)
    static let secondaryButtonText = dynamic(light: Light.textPrimary, dark: Light.textPrimary)
    static let tertiaryButtonText = dynamic(light: Brand.blue, dark: Brand.gold)
    static let tabBarBackground = dynamic(light: Color(hex: "#FBFBF9"), dark: Dark.surface)
    static let selectionFill = dynamic(light: Brand.gold.opacity(0.18), dark: Brand.gold.opacity(0.20))
    static let fieldBackground = dynamic(light: Light.surface, dark: Dark.elevated)
    static let progressTrack = dynamic(light: Color(hex: "#E9E5DD"), dark: Color(hex: "#46505C"))
    static let success = dynamic(light: Color(hex: "#466C57"), dark: Color(hex: "#7FA287"))
    static let warning = dynamic(light: Color(hex: "#9C7840"), dark: Color(hex: "#D0AF72"))
    static let weakness = dynamic(light: Color(hex: "#A45F5B"), dark: Color(hex: "#C78882"))
    static let reviewCorrectButton = dynamic(light: Color(hex: "#466C57"), dark: Color(hex: "#6E9278"))
    static let reviewMissedButton = dynamic(light: Color(hex: "#A45F5B"), dark: Color(hex: "#C78882"))
    static let reviewResultButtonText = dynamic(light: Light.surface, dark: Dark.textPrimary)
    static let subtleMissed = dynamic(light: Color(hex: "#E8D4D2"), dark: Color(hex: "#5A4340"))
    static let statusPracticing = dynamic(light: Color(hex: "#8A8A8A"), dark: Color(hex: "#B0B0B0"))
    static let statusMemorized = dynamic(light: Color(hex: "#4D7A5A"), dark: Color(hex: "#88AF92"))
    static let folderPillFill = dynamic(light: Color(hex: "#EEE5D2"), dark: Brand.gold.opacity(0.14))
    static let folderPillText = dynamic(light: Color(hex: "#253141"), dark: Brand.gold)
    static let shadow = dynamic(light: Color(hex: "#000000").opacity(0.08), dark: Color(hex: "#000000").opacity(0.24))
    static let reviewPracticingActionBackground = primaryButton
    static let reviewPracticingActionText = primaryButtonText
    static let reviewAllActionBackground = secondaryButton
    static let reviewAllActionText = secondaryButtonText
    static let verseOfTheDayBadgeFill = dynamic(light: Color(hex: "#F1E7C8"), dark: Brand.gold.opacity(0.16))
    static let verseOfTheDayReference = dynamic(light: Color(hex: "#253141"), dark: Brand.gold)
    static let addComposerBackground = dynamic(light: Color(hex: "#F8F6F1"), dark: Color(hex: "#30343A"))
    static let addComposerBorder = dynamic(light: Color(hex: "#D8D2C4"), dark: Color(hex: "#4A4F56"))
    static let addHeroTint = dynamic(light: Color(hex: "#EEE5D2"), dark: Brand.gold.opacity(0.12))

    private static func dynamic(light: Color, dark: Color) -> Color {
        Color(
            uiColor: UIColor { traits in
                switch traits.userInterfaceStyle {
                case .dark:
                    return UIColor(dark)
                default:
                    return UIColor(light)
                }
            }
        )
    }
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

extension VerseMasteryStatus {
    var tintColor: Color {
        switch self {
        case .practicing:
            return AppColors.statusPracticing
        case .memorized:
            return AppColors.statusMemorized
        }
    }

    var subtleFillColor: Color {
        tintColor.opacity(0.14)
    }

    var badgeTitle: String {
        rawValue
    }

    var actionTitle: String {
        switch self {
        case .practicing:
            return "Mark Learning"
        case .memorized:
            return "Mark Memorized"
        }
    }

    var iconName: String {
        switch self {
        case .practicing:
            return "circle.dashed"
        case .memorized:
            return "checkmark.circle.fill"
        }
    }
}
