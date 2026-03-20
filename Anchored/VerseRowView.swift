import SwiftUI

struct VerseRowView: View {
    let verse: Verse
    private static let uncategorizedFolderName = "Uncategorized"

    private var progressTint: Color {
        switch verse.urgencyLevel {
        case .fresh:
            return Color(red: 0.34, green: 0.69, blue: 0.48)
        case .atRisk:
            return Color(red: 0.85, green: 0.72, blue: 0.31)
        case .needsReview:
            return Color(red: 0.78, green: 0.39, blue: 0.37)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
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

                        ProgressView(value: verse.progress)
                            .tint(progressTint)
                            .scaleEffect(x: 1, y: 0.7, anchor: .center)

                        Text(verse.isMastered ? "Memorized" : verse.progressText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 1)
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
