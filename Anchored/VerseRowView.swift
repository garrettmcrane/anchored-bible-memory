import SwiftUI

struct VerseRowView: View {
    struct MetadataItem: Identifiable {
        let text: String
        var id: String { text }
    }

    let verse: Verse
    var showsChevron: Bool = true
    var selectionState: SelectionState? = nil
    var metadataItems: [MetadataItem]? = nil
    var statusTintOverride: Color? = nil
    private static let uncategorizedFolderName = "Uncategorized"

    struct SelectionState {
        let isSelected: Bool
    }

    private var status: VerseMasteryStatus {
        verse.masteryStatus
    }

    private var statusTint: Color {
        statusTintOverride ?? status.tintColor
    }

    private var resolvedMetadataItems: [MetadataItem] {
        metadataItems ?? []
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let selectionState {
                selectionIndicator(isSelected: selectionState.isSelected)
            }

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(statusTint)
                .frame(width: 4)
                .padding(.vertical, 2)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verse.reference)
                        .font(AnchoredFont.ui(17, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(verse.text)
                        .font(AnchoredFont.uiSubheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)

                    if showsMetadataRow {
                        metadataRow
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(AnchoredFont.ui(12, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var showsMetadataRow: Bool {
        folderName != nil || lastReviewedText != nil || !resolvedMetadataItems.isEmpty
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            if let folderName {
                folderPill(folderName)
            }

            if let lastReviewedText {
                if folderName != nil {
                    metadataSeparator
                }

                Text(lastReviewedText)
                    .font(AnchoredFont.uiCaption)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.82))
                    .lineLimit(1)
            }

            ForEach(Array(resolvedMetadataItems.enumerated()), id: \.element.id) { index, item in
                if index > 0 || folderName != nil || lastReviewedText != nil {
                    metadataSeparator
                }

                Text(item.text)
                    .font(AnchoredFont.uiCaption)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.82))
                    .lineLimit(1)
            }
        }
    }

    private var metadataSeparator: some View {
        Circle()
            .fill(AppColors.textSecondary.opacity(0.28))
            .frame(width: 3, height: 3)
    }

    private func folderPill(_ title: String) -> some View {
        Text(title)
            .font(AnchoredFont.uiCaption.weight(.semibold))
            .foregroundStyle(AppColors.folderPillText)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.folderPillFill)
            )
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? AppColors.gold.opacity(0.16) : AppColors.textSecondary.opacity(0.3),
                    lineWidth: 1.5
                )
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.gold : Color.clear)
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(AnchoredFont.ui(11, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(width: 26, height: 26)
        .animation(.snappy(duration: 0.18), value: isSelected)
    }

    private var folderName: String? {
        let trimmedFolderName = verse.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsedWhitespaceFolderName.isEmpty else {
            return nil
        }

        let normalizedFolderName = collapsedWhitespaceFolderName.lowercased().localizedCapitalized
        guard normalizedFolderName != Self.uncategorizedFolderName else {
            return nil
        }

        return normalizedFolderName
    }

    private var lastReviewedText: String? {
        guard let lastReviewedAt = verse.lastReviewedAt else {
            return "Not reviewed yet"
        }

        let calendar = Calendar.current
        let daysAgo = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastReviewedAt),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        if daysAgo <= 0 {
            return "Reviewed today"
        }

        if daysAgo == 1 {
            return "Reviewed 1 day ago"
        }

        return "Reviewed \(daysAgo) days ago"
    }
}

#Preview {
    VerseRowView(
        verse: Verse(
            reference: "Romans 8:28",
            text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
            isMastered: false,
            correctCount: 1
        )
    )
    .padding()
}
