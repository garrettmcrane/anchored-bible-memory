import SwiftUI

enum AnchoredSpacing {
    static let screenHorizontal: CGFloat = 20
    static let section: CGFloat = 18
    static let cardPadding: CGFloat = 18
    static let tightCardPadding: CGFloat = 14
    static let cardCornerRadius: CGFloat = 24
    static let heroCornerRadius: CGFloat = 28
}

enum AnchoredFont {
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static let uiTitleBar = editorial(20, weight: .bold)
    static let uiSectionTitle = ui(20, weight: .semibold)
    static let uiBody = ui(17)
    static let uiSubheadline = ui(15)
    static let uiLabel = ui(15, weight: .semibold)
    static let uiCaption = ui(12, weight: .medium)

    static func editorial(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(newsreaderName(for: weight, editorial: true), size: size)
    }

    static func scripture(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(newsreaderName(for: weight, editorial: false), size: size)
    }

    private static func newsreaderName(for weight: Font.Weight, editorial: Bool) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "NewsreaderRoman-Bold"
        case .medium:
            return "NewsreaderRoman-Medium"
        case .semibold:
            return "NewsreaderRoman-SemiBold"
        default:
            return editorial ? "Newsreader16pt-Regular" : "Newsreader16pt-Regular"
        }
    }
}

struct AnchoredCardBackground: View {
    var elevated = false
    var cornerRadius: CGFloat = AnchoredSpacing.cardCornerRadius

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(elevated ? AppColors.elevatedSurface : AppColors.surface)
    }
}

struct AnchoredCard<Content: View>: View {
    var elevated = false
    var cornerRadius: CGFloat = AnchoredSpacing.cardCornerRadius
    var padding: CGFloat = AnchoredSpacing.cardPadding
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AnchoredCardBackground(elevated: elevated, cornerRadius: cornerRadius))
    }
}

struct AnchoredSectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AnchoredFont.uiSectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(AnchoredFont.uiSubheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AnchoredPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(AppColors.primaryButtonText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .glassEffect(.regular.tint(AppColors.primaryButton).interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AnchoredSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(AppColors.secondaryButtonText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .glassEffect(.regular.tint(AppColors.secondaryButton).interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AnchoredCompactPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(AppColors.primaryButtonText)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
            .frame(minHeight: 40)
            .padding(.horizontal, 14)
            .glassEffect(.regular.tint(AppColors.primaryButton).interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AnchoredDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .glassEffect(.regular.tint(.red).interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AnchoredSuccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(AppColors.reviewResultButtonText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .glassEffect(.regular.tint(AppColors.reviewCorrectButton).interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AnchoredMissedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(AppColors.reviewResultButtonText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .glassEffect(.regular.tint(AppColors.reviewMissedButton).interactive(), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct AnchoredTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AnchoredFont.uiLabel)
            .foregroundStyle(AppColors.structuralAccent.opacity(configuration.isPressed ? 0.7 : 1))
    }
}

struct AnchoredReviewActionButton: View {
    let title: String
    let role: Role
    let isEnabled: Bool
    let action: () -> Void

    enum Role {
        case primary
        case secondary
    }

    var body: some View {
        buttonBody
            .opacity(isEnabled ? 1 : 0.45)
            .disabled(!isEnabled)
    }

    @ViewBuilder
    private var buttonBody: some View {
        if role == .primary {
            Button(action: action) {
                Text(title)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnchoredPrimaryButtonStyle())
        } else {
            Button(action: action) {
                Text(title)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnchoredSecondaryButtonStyle())
        }
    }
}

struct AnchoredCapsuleMenuLabel: View {
    let title: String
    var tint: Color = AppColors.textPrimary

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(AnchoredFont.uiCaption)
        }
        .font(AnchoredFont.uiLabel)
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

struct AnchoredBottomActionDock<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, AnchoredSpacing.screenHorizontal)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(.clear)
    }
}
