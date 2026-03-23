import SwiftUI

struct ProgressProfileHeroSectionView: View {
    let displayName: String
    let leadingInsightTitle: String
    let leadingInsightMessage: String
    let memorizedCount: Int
    let practicingCount: Int
    let libraryCount: Int
    let weeklyReviewCount: Int
    let strongestFolderName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(displayName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                Text(leadingInsightTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.scriptureAccent)

                Text(leadingInsightMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                ProfileHighlightPill(title: "Memorized", value: memorizedCount.formatted())
                ProfileHighlightPill(title: "Practicing", value: practicingCount.formatted())
                ProfileHighlightPill(title: "Library", value: libraryCount.formatted())
            }

            HStack(spacing: 10) {
                ProgressProfileDetailView(label: "This week", value: "\(weeklyReviewCount) reviews")
                ProgressProfileDetailView(label: "Top folder", value: strongestFolderName ?? "None yet")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.elevatedSurface,
                            AppColors.secondarySurface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }
}

struct ProgressSectionView<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            content
        }
    }
}

private struct ProgressProfileDetailView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.7))
        )
    }
}
