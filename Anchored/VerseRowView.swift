import SwiftUI

struct VerseRowView: View {
    let verse: Verse
    var showsChevron: Bool = true
    var selectionState: SelectionState? = nil
    private static let uncategorizedFolderName = "Uncategorized"

    struct SelectionState {
        let isSelected: Bool
    }

    private var strength: Double {
        VerseStrengthService.currentStrength(for: verse)
    }

    private var progressTint: Color {
        switch VerseStrengthService.band(for: strength) {
        case .strong:
            return Color(red: 0.34, green: 0.69, blue: 0.48)
        case .steady:
            return Color(red: 0.56, green: 0.78, blue: 0.40)
        case .warning:
            return Color(red: 0.85, green: 0.72, blue: 0.31)
        case .weak:
            return Color(red: 0.78, green: 0.39, blue: 0.37)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                if let selectionState {
                    selectionIndicator(isSelected: selectionState.isSelected)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(verse.reference)
                        .font(.headline)

                    Text(verse.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 8) {
                        Text(folderName)
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.75))
                            .lineLimit(1)

                        ProgressView(value: strength)
                            .tint(progressTint)
                            .scaleEffect(x: 1, y: 0.7, anchor: .center)

                        Text(verse.masteryStatus.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 10)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 1)
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.3),
                    lineWidth: 1.5
                )
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
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
