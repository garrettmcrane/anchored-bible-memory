import SwiftUI

struct VerseRowView: View {
    let verse: Verse
    var showsChevron: Bool = true
    var selectionState: SelectionState? = nil
    private static let uncategorizedFolderName = "Uncategorized"

    struct SelectionState {
        let isSelected: Bool
    }

    private var status: VerseMasteryStatus {
        verse.masteryStatus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                if let selectionState {
                    selectionIndicator(isSelected: selectionState.isSelected)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(verse.reference)
                        .font(.headline)

                    Text(verse.text)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 8) {
                        Text(folderName)
                            .font(.caption2)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.75))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, showsChevron ? 84 : 64)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
        }
        .padding(.vertical, 1)
        .overlay(alignment: .topTrailing) {
            statusBadge
                .padding(.top, -2)
                .padding(.trailing, -8)
        }
    }

    private var statusBadge: some View {
        Text(status.badgeTitle)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(status.subtleFillColor))
            .foregroundStyle(status.tintColor)
            .lineLimit(1)
            .fixedSize()
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
