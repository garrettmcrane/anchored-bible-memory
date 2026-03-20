import SwiftUI

enum FirstLetterTypingSupport {
    static func pattern(for text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { firstLetterToken(for: $0) }
            .joined(separator: " ")
    }

    static func normalizedText(_ text: String) -> String {
        let cleanedScalars = text.lowercased().unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }

            return " "
        }

        return String(cleanedScalars)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func evaluateResponse(_ response: String, against target: String) -> ReviewResult {
        normalizedText(response) == normalizedText(target) ? .correct : .missed
    }

    private static func firstLetterToken(for token: String) -> String {
        let characters = Array(token)

        guard let firstLetterIndex = characters.firstIndex(where: { $0.isLetter || $0.isNumber }) else {
            return token
        }

        let leading = String(characters[..<firstLetterIndex])
        let firstLetter = String(characters[firstLetterIndex])
        let trailingStart = characters.index(after: firstLetterIndex)
        let trailing = trailingStart < characters.endIndex ? String(characters[trailingStart...].filter { !$0.isLetter && !$0.isNumber }) : ""

        return leading + firstLetter + trailing
    }
}

struct ReviewSessionSummary {
    var reviewedCount = 0
    var correctCount = 0
    var missedCount = 0

    mutating func record(_ result: ReviewResult) {
        reviewedCount += 1

        switch result {
        case .correct:
            correctCount += 1
        case .missed:
            missedCount += 1
        }
    }
}

struct ReviewSessionProgressHeader: View {
    let currentIndex: Int
    let totalCount: Int
    let reference: String

    private var progressValue: Double {
        guard totalCount > 0 else {
            return 0
        }

        return Double(currentIndex + 1) / Double(totalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Verse \(currentIndex + 1) of \(totalCount)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(progressValue * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            ProgressView(value: progressValue)
                .tint(.blue)

            Text(reference)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ReviewResultButtons: View {
    let onMissed: () -> Void
    let onCorrect: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onMissed) {
                Text("Missed")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button(action: onCorrect) {
                Text("Got It")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
}

struct ReviewSessionCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let summary: ReviewSessionSummary

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.green)

                Text("Session Completed")
                    .font(.title2.weight(.semibold))

                Text("You reviewed \(summary.reviewedCount) verse\(summary.reviewedCount == 1 ? "" : "s").")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                completionMetric(title: "Correct", value: summary.correctCount, tint: .green)
                completionMetric(title: "Missed", value: summary.missedCount, tint: .red)
            }

            Spacer()

            Button("Return") {
                dismiss()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }

    private func completionMetric(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(value)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
