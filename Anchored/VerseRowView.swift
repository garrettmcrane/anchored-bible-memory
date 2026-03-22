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
        metadataItems ?? [MetadataItem(text: folderName)]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let selectionState {
                selectionIndicator(isSelected: selectionState.isSelected)
                    .padding(.top, 12)
            }

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(statusTint)
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text(verse.reference)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(verse.text)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !resolvedMetadataItems.isEmpty {
                    metadataRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColors.textSecondary)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(resolvedMetadataItems.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Circle()
                        .fill(AppColors.textSecondary.opacity(0.28))
                        .frame(width: 3, height: 3)
                }

                Text(item.text)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.82))
                    .lineLimit(1)
            }
        }
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
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(width: 26, height: 26)
        .animation(.snappy(duration: 0.18), value: isSelected)
    }

    private var folderName: String {
        let trimmedFolderName = verse.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsedWhitespaceFolderName.isEmpty else {
            return Self.uncategorizedFolderName
        }

        return collapsedWhitespaceFolderName.lowercased().localizedCapitalized
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
