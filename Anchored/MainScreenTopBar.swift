import SwiftUI

struct MainScreenTopBar: View {
    let title: String
    let onNotificationsTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            iconButton(systemImage: "bell.badge") {
                onNotificationsTap()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            iconButton(systemImage: "gearshape") {
                onSettingsTap()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 44)
    }

    private func iconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(AppColors.elevatedSurface)
                )
                .overlay {
                    Circle()
                        .stroke(AppColors.divider, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
