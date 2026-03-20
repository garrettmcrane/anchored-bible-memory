import SwiftUI

struct VerseRowView: View {
    let verse: Verse

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(verse.reference)
                    .font(.headline)

                Text(verse.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    ProgressView(value: verse.progressValue)
                        .tint(verse.isMastered ? .green : .blue)

                    Text(verse.isMastered ? "Mastered" : verse.progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
