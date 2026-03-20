import SwiftUI

struct VerseRowView: View {
    let verse: Verse

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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verse.reference)
                        .font(.headline)

                    Text(verse.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(verse.folderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                ProgressView(value: verse.progress)
                    .tint(progressTint)

                Text(verse.isMastered ? "Memorized" : verse.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.vertical, 2)
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
