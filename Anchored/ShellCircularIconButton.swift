import SwiftUI

struct ShellCircularIconLabel: View {
    static let diameter: CGFloat = 42
    static let iconSize: CGFloat = 16
    static let strokeWidth: CGFloat = 1

    let systemImage: String
    var tint: Color = AppColors.textPrimary

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: Self.iconSize, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(
                Circle()
                    .fill(AppColors.elevatedSurface)
            )
            .overlay {
                Circle()
                    .stroke(AppColors.divider, lineWidth: Self.strokeWidth)
            }
    }
}

struct ShellCircularIconButton: View {
    let systemImage: String
    var tint: Color = AppColors.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ShellCircularIconLabel(systemImage: systemImage, tint: tint)
        }
        .buttonStyle(.plain)
    }
}
