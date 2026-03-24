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
                    .font(AnchoredFont.editorial(30))
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
        .padding(20)
        .background(AnchoredCardBackground(elevated: true, cornerRadius: AnchoredSpacing.heroCornerRadius))
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
            AnchoredSectionHeader(
                title: "Review",
                subtitle: "Start from the verses this group is actively working on."
            )

            HStack(spacing: 10) {
                groupProgressTag(value: practicingAssignedCount, title: "Learning", tint: AppColors.statusPracticing)
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
        AnchoredSectionHeader(title: title, subtitle: subtitle)
    }
}

struct GroupBottomReviewBarView: View {
    let practicingReviewEnabled: Bool
    let reviewAllEnabled: Bool
    let onStartPracticingReview: () -> Void
    let onStartReviewAll: () -> Void

    var body: some View {
        AnchoredBottomActionDock {
            HStack(spacing: 10) {
                AnchoredReviewActionButton(
                    title: "Review Learning",
                    role: .primary,
                    isEnabled: practicingReviewEnabled,
                    action: onStartPracticingReview
                )

                AnchoredReviewActionButton(
                    title: "Review All",
                    role: .secondary,
                    isEnabled: reviewAllEnabled,
                    action: onStartReviewAll
                )
            }
        }
    }
}

struct GroupAssignedPassageCardView: View {
    let verse: Verse
    let isFirstInStack: Bool
    let isLastInStack: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    let onToggleMastery: () -> Void
    let toggleSystemImage: String
    let toggleTint: Color

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: onSelect) {
                VerseRowView(
                    verse: verse,
                    showsChevron: true,
                    statusTintOverride: verse.masteryStatus.tintColor
                )
            }
            .buttonStyle(.plain)

            Button("Remove", role: .destructive, action: onRemove)
                .font(AnchoredFont.uiSubheadline.weight(.semibold))
                .padding(.trailing, 2)
                .padding(.bottom, 1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onToggleMastery) {
                Image(systemName: toggleSystemImage)
            }
            .tint(toggleTint)
        }
    }

    private var cardBackground: some View {
        UnevenRoundedRectangle(cornerRadii: cardCornerRadii, style: .continuous)
            .fill(AppColors.surface)
    }

    private var cardCornerRadii: RectangleCornerRadii {
        let radius: CGFloat = 24
        return RectangleCornerRadii(
            topLeading: isFirstInStack ? radius : 0,
            bottomLeading: isLastInStack ? radius : 0,
            bottomTrailing: isLastInStack ? radius : 0,
            topTrailing: isFirstInStack ? radius : 0
        )
    }
}
