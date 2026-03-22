import SwiftUI

struct MainScreenTopBar: View {
    private let sideControlWidth = ShellCircularIconLabel.diameter

    let title: String
    let onNotificationsTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                ShellCircularIconButton(systemImage: "bell.badge") {
                    onNotificationsTap()
                }
                .frame(width: sideControlWidth, alignment: .leading)

                Spacer(minLength: 0)

                ShellCircularIconButton(systemImage: "gearshape") {
                    onSettingsTap()
                }
                .frame(width: sideControlWidth, alignment: .trailing)
            }
        }
        .frame(height: 44)
    }
}
