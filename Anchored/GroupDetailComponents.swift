import SwiftUI

struct GroupDetailHeaderView: View {
    let title: String
    let onBack: () -> Void
    let onShowOptions: () -> Void

    var body: some View {
        CenteredScreenTitleBar(title: title) {
            ShellCircularIconButton(systemImage: "chevron.left", action: onBack)
                .accessibilityLabel("Back")
        } trailing: {
            ShellCircularIconButton(systemImage: "ellipsis", action: onShowOptions)
                .accessibilityLabel("Group options")
        }
    }
}

struct GroupDetailHeroSectionView: View {
    let groupName: String
    let subtitle: String
    let assignedCount: Int
    let groupReviewStatus: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(groupName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                groupHeroAccentPill(
                    title: assignedCount == 1 ? "Assigned Passage" : "Assigned Passages",
                    value: assignedCount.formatted()
                )

                groupHeroAccentPill(
                    title: "Group Review",
                    value: groupReviewStatus
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private func groupHeroAccentPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.86))
        )
    }
}

struct GroupDetailReviewSectionView: View {
    let practicingAssignedCount: Int
    let memorizedAssignedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupSectionHeader(
                title: "Review",
                subtitle: "Start from the verses this group is actively working on."
            )

            HStack(spacing: 10) {
                groupProgressTag(value: practicingAssignedCount, title: "Practicing", tint: AppColors.statusPracticing)
                groupProgressTag(value: memorizedAssignedCount, title: "Memorized", tint: AppColors.statusMemorized)
            }
        }
    }

    private func groupProgressTag(value: Int, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text("\(value.formatted()) \(title)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
    }
}

struct GroupSectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct GroupBottomReviewBarView: View {
    let practicingReviewEnabled: Bool
    let reviewAllEnabled: Bool
    let onStartPracticingReview: () -> Void
    let onStartReviewAll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            groupReviewButton(
                title: "Review Practicing",
                tint: AppColors.reviewPracticingActionBackground,
                textColor: AppColors.reviewPracticingActionText,
                isEnabled: practicingReviewEnabled,
                action: onStartPracticingReview
            )

            groupReviewButton(
                title: "Review All",
                tint: AppColors.reviewAllActionBackground,
                textColor: AppColors.reviewAllActionText,
                isEnabled: reviewAllEnabled,
                action: onStartReviewAll
            )
        }
        .padding(.horizontal, 20)
    }

    private func groupReviewButton(
        title: String,
        tint: Color,
        textColor: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(isEnabled ? textColor : AppColors.textSecondary.opacity(0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(.glass(.regular.tint(isEnabled ? tint : AppColors.secondarySurface).interactive()))
        .disabled(!isEnabled)
    }
}

struct GroupAssignedPassageCardView: View {
    let verse: Verse
    let onSelect: () -> Void
    let onRemove: () -> Void
    let onToggleMastery: () -> Void
    let toggleSystemImage: String
    let toggleTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onSelect) {
                VerseRowView(
                    verse: verse,
                    showsChevron: true,
                    statusTintOverride: verse.masteryStatus.tintColor
                )
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, 17)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Button("Remove", role: .destructive, action: onRemove)
                .font(.subheadline.weight(.semibold))
                .padding(.leading, 17)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onToggleMastery) {
                Image(systemName: toggleSystemImage)
            }
            .tint(toggleTint)
        }
    }
}
