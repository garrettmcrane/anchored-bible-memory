import SwiftUI

struct CenteredScreenTitleBar<Leading: View, Trailing: View>: View {
    let title: String
    var sideContentWidth: CGFloat = ShellCircularIconLabel.diameter
    let leading: Leading
    let trailing: Trailing

    init(
        title: String,
        sideContentWidth: CGFloat = ShellCircularIconLabel.diameter,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.sideContentWidth = sideContentWidth
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                leading
                    .frame(width: sideContentWidth, alignment: .leading)

                Spacer(minLength: 0)

                trailing
                    .frame(width: sideContentWidth, alignment: .trailing)
            }
        }
        .frame(height: 44)
    }
}

struct MainScreenTopBar: View {
    let title: String
    let onNotificationsTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        CenteredScreenTitleBar(title: title) {
                ShellCircularIconButton(systemImage: "bell.badge") {
                    onNotificationsTap()
                }
        } trailing: {
                ShellCircularIconButton(systemImage: "gearshape") {
                    onSettingsTap()
                }
        }
    }
}
