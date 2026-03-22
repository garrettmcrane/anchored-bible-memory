import SwiftUI

struct MainScreenTopBar: View {
    let title: String
    let onNotificationsTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ShellCircularIconButton(systemImage: "bell.badge") {
                onNotificationsTap()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            ShellCircularIconButton(systemImage: "gearshape") {
                onSettingsTap()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 44)
    }
}
