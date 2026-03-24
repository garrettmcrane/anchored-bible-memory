import SwiftUI

struct NotificationsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notifications")
                        .font(AnchoredFont.editorial(30, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("This space is reserved for reminders, app updates, and important announcements.")
                        .font(AnchoredFont.uiSubheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    placeholderRow(title: "Reminders", subtitle: "Stay on top of the verses you want to revisit.")
                    placeholderRow(title: "Updates", subtitle: "See what is new in Anchored as the app evolves.")
                    placeholderRow(title: "Announcements", subtitle: "Receive brief, relevant messages when needed.")
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func placeholderRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AnchoredFont.ui(17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AnchoredFont.uiSubheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }
}
