import SwiftUI

struct ShellCircularIconLabel: View {
    static let diameter: CGFloat = 40
    static let iconSize: CGFloat = 16

    let systemImage: String
    var tint: Color = AppColors.textPrimary

    var body: some View {
        Image(systemName: systemImage)
            .font(AnchoredFont.ui(CGFloat(Self.iconSize), weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: Self.diameter, height: Self.diameter)
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
        .glassEffect(.regular.interactive(), in: .circle)
    }
}
