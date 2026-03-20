import SwiftUI
import UIKit

struct FirstLetterTypingToken: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let normalizedLeadingLetter: Character?

    var isRevealable: Bool {
        normalizedLeadingLetter != nil
    }
}

struct FirstLetterTypingVersePerformance: Identifiable, Equatable {
    let verseID: String
    let reference: String
    let totalPrompts: Int
    let incorrectAttempts: Int
    let correctReveals: Int

    var id: String {
        verseID
    }

    var scorePercent: Int {
        let totalAttempts = correctReveals + incorrectAttempts
        guard totalAttempts > 0 else {
            return 0
        }

        return Int(((Double(correctReveals) / Double(totalAttempts)) * 100).rounded())
    }

    var qualityLabel: String {
        switch resultTier {
        case .perfect:
            return "Perfect"
        case .imperfect:
            return "Strong"
        case .missed:
            return "Needs Work"
        }
    }

    var summaryText: String {
        switch resultTier {
        case .perfect:
            return "Perfect recall"
        case .imperfect:
            return "\(scorePercent)% accurate"
        case .missed:
            return "A few misses"
        }
    }

    var reviewResult: ReviewResult {
        resultTier == .missed ? .missed : .correct
    }

    var resultTier: FirstLetterTypingResultTier {
        switch scorePercent {
        case 100:
            return .perfect
        case 80...99:
            return .imperfect
        default:
            return .missed
        }
    }

    var tintColor: Color {
        switch resultTier {
        case .perfect:
            return .green
        case .imperfect:
            return Color(red: 0.78, green: 0.58, blue: 0.10)
        case .missed:
            return .red
        }
    }

    var backgroundTint: Color {
        tintColor.opacity(0.12)
    }
}

enum FirstLetterTypingResultTier {
    case perfect
    case imperfect
    case missed
}

struct FirstLetterTypingState {
    let tokens: [FirstLetterTypingToken]
    private(set) var revealedWordCount: Int = 0
    private(set) var incorrectAttempts: Int = 0

    init(text: String) {
        self.tokens = FirstLetterTypingSupport.tokens(for: text)
    }

    var isComplete: Bool {
        revealedWordCount >= revealableWordCount
    }

    var currentPrompt: String {
        isComplete ? "Verse completed. Score your recall." : "Type the first letter of the next word."
    }

    var progressText: String {
        "\(revealedWordCount) of \(revealableWordCount) words revealed"
    }

    func isRevealed(_ token: FirstLetterTypingToken) -> Bool {
        guard token.isRevealable else {
            return false
        }

        var revealableIndex = 0

        for currentToken in tokens where currentToken.isRevealable {
            if currentToken.id == token.id {
                return revealableIndex < revealedWordCount
            }

            revealableIndex += 1
        }

        return false
    }

    mutating func submit(_ input: String) -> Bool {
        guard let expectedLetter = nextExpectedLetter,
              let typedLetter = FirstLetterTypingSupport.normalizedLeadingLetter(from: input) else {
            return false
        }

        guard typedLetter == expectedLetter else {
            incorrectAttempts += 1
            return false
        }

        revealedWordCount += 1
        return true
    }

    func performance(for verse: Verse) -> FirstLetterTypingVersePerformance {
        FirstLetterTypingVersePerformance(
            verseID: verse.id,
            reference: verse.reference,
            totalPrompts: revealableWordCount,
            incorrectAttempts: incorrectAttempts,
            correctReveals: revealedWordCount
        )
    }

    private var nextExpectedLetter: Character? {
        var revealableIndex = 0

        for token in tokens where token.isRevealable {
            if revealableIndex == revealedWordCount {
                return token.normalizedLeadingLetter
            }

            revealableIndex += 1
        }

        return nil
    }

    private var revealableWordCount: Int {
        tokens.filter(\.isRevealable).count
    }
}

enum FirstLetterTypingSupport {
    static func tokens(for text: String) -> [FirstLetterTypingToken] {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { token in
                FirstLetterTypingToken(
                    text: token,
                    normalizedLeadingLetter: normalizedLeadingLetter(from: token)
                )
            }
    }

    static func normalizedLeadingLetter(from text: String) -> Character? {
        text.lowercased().first(where: { $0.isLetter || $0.isNumber })
    }
}

enum FirstLetterTypingFeedback {
    private static let generator = UIImpactFeedbackGenerator(style: .light)
    private static var lastImpactTimestamp: TimeInterval = 0

    static func prepare() {
        generator.prepare()
    }

    static func triggerLightImpactIfNeeded() {
        let now = Date().timeIntervalSince1970

        guard now - lastImpactTimestamp > 0.12 else {
            return
        }

        lastImpactTimestamp = now
        generator.impactOccurred()
        generator.prepare()
    }
}

struct FirstLetterTypingVerseCard: View {
    let state: FirstLetterTypingState
    var isErrorFlashing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Verse Reconstruction")
                    .font(.headline)

                Spacer()

                Text(state.progressText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            FirstLetterTypingFlowingText(state: state)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isErrorFlashing ? Color.red.opacity(0.10) : Color(.secondarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.18), value: isErrorFlashing)
    }
}

struct FirstLetterTypingFlowingText: View {
    let state: FirstLetterTypingState

    var body: some View {
        visibleText
            .overlay(alignment: .topLeading) {
                skeletonText
                    .allowsHitTesting(false)
            }
            .font(.system(.title3, design: .serif))
            .lineSpacing(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120, alignment: .topLeading)
    }

    private var visibleText: some View {
        composedText(showAllWords: false)
            .foregroundStyle(.primary)
    }

    private var skeletonText: some View {
        composedText(showAllWords: true)
            .foregroundStyle(.clear)
    }

    private func composedText(showAllWords: Bool) -> Text {
        let content = state.tokens.enumerated().reduce(into: "") { partial, element in
            let index = element.offset
            let token = element.element
            let suffix = index == state.tokens.count - 1 ? "" : " "

            let visibleToken: String
            if token.isRevealable {
                visibleToken = showAllWords || state.isRevealed(token) ? token.text : ""
            } else {
                visibleToken = showAllWords || state.hasAnyRevealedWords ? token.text : ""
            }

            partial += visibleToken + suffix
        }

        return Text(content)
    }
}

private extension FirstLetterTypingState {
    var hasAnyRevealedWords: Bool {
        revealedWordCount > 0
    }
}

struct FirstLetterTypingPerformanceCard: View {
    let performance: FirstLetterTypingVersePerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(performance.qualityLabel)
                    .font(.headline)

                Spacer()

                Text("\(performance.scorePercent)%")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(performance.tintColor)
            }

            Text(performance.summaryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(performance.correctReveals) correct reveals, \(performance.incorrectAttempts) misses")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(performance.backgroundTint)
        )
    }
}

struct FirstLetterTypingSessionCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let summary: ReviewSessionSummary
    let verseReports: [FirstLetterTypingVersePerformance]
    let totalVerseCount: Int
    let endedEarly: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                    if endedEarly {
                        Text("Session ended early. \(summary.reviewedCount) of \(totalVerseCount) verses were completed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 12) {
                    completionMetric(title: "Correct", value: summary.correctCount, tint: .green)
                    completionMetric(title: "Missed", value: summary.missedCount, tint: .red)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Verse Report")
                        .font(.headline)

                    ForEach(verseReports) { report in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(report.reference)
                                    .font(.subheadline.weight(.semibold))

                                Text(report.qualityLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(report.scorePercent)%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(report.tintColor)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(report.backgroundTint)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
    let totalVerseCount: Int
    let endedEarly: Bool

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

                if endedEarly {
                    Text("Session ended early. \(summary.reviewedCount) of \(totalVerseCount) verses were completed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
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
