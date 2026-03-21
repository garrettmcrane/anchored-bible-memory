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

struct ReviewStartConfiguration: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let verses: [Verse]
}

struct ReviewSessionDescriptor {
    let title: String
    let method: ReviewMethod
}

struct ReviewStartSheet: View {
    @Environment(\.dismiss) private var dismiss

    let configuration: ReviewStartConfiguration
    let onStart: (ReviewMethod) -> Void

    @State private var selectedMethod: ReviewMethod = .flashcard

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                topBar

                sessionOverview

                methodOptionsSection

                Spacer(minLength: 0)

                startButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.trailing, 4)
    }

    private var sessionOverview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(configuration.title)
                .font(.title2.weight(.semibold))

            if let description = configuration.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text("\(configuration.verses.count) verse\(configuration.verses.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var methodOptionsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Review Method")
                .font(.subheadline.weight(.semibold))

            ForEach(ReviewMethod.allCases) { method in
                methodOption(for: method)
            }
        }
    }

    private var startButton: some View {
        Button("Start Review") {
            onStart(selectedMethod)
            dismiss()
        }
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.blue)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func methodOption(for method: ReviewMethod) -> some View {
        let isSelected = selectedMethod == method
        let backgroundColor = isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemBackground)
        let strokeColor = isSelected ? Color.blue.opacity(0.22) : Color.primary.opacity(0.06)
        let iconName = isSelected ? "checkmark.circle.fill" : "circle"
        let iconColor = isSelected ? Color.blue : Color(uiColor: .tertiaryLabel)
        let description = condensedPromptDescription(for: method)

        return Button {
            selectedMethod = method
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: iconName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func condensedPromptDescription(for method: ReviewMethod) -> String {
        switch method {
        case .flashcard:
            return "Recite first, then reveal and score."
        case .progressiveWordHiding:
            return "Hide more words as you recite."
        case .firstLetterTyping:
            return "Type with first-letter prompts."
        case .voiceRecitation:
            return "Recite aloud and compare the transcript."
        }
    }
}

#Preview("Review Start Sheet") {
    ReviewStartSheet(
        configuration: ReviewStartConfiguration(
            title: "Smart Review",
            description: "Prioritizes weaker verses and learning passages first.",
            verses: [
                Verse(reference: "John 3:16", text: "For God so loved the world..."),
                Verse(reference: "Romans 8:28", text: "And we know that for those who love God...")
            ]
        ),
        onStart: { _ in }
    )
}

struct FirstLetterTypingSessionCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let descriptor: ReviewSessionDescriptor
    let summary: ReviewSessionSummary
    let verseReports: [FirstLetterTypingVersePerformance]
    let totalVerseCount: Int
    let endedEarly: Bool
    let duration: TimeInterval
    let onReviewAgain: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ReviewSessionSummaryHero(
                    descriptor: descriptor,
                    summary: summary,
                    totalVerseCount: totalVerseCount,
                    endedEarly: endedEarly,
                    duration: duration
                )

                ReviewSessionMetricsSection(summary: summary, duration: duration)

                ReviewSessionNeedsWorkSection(references: summary.missedReferences)

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

                ReviewSessionActionBar(
                    onDone: { dismiss() },
                    onReviewAgain: onReviewAgain
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}

struct ReviewSessionSummary {
    var reviewedCount = 0
    var correctCount = 0
    var missedCount = 0
    var missedReferences: [String] = []

    mutating func record(_ result: ReviewResult, reference: String? = nil) {
        reviewedCount += 1

        switch result {
        case .correct:
            correctCount += 1
        case .missed:
            missedCount += 1
            if let reference {
                missedReferences.append(reference)
            }
        }
    }
}

struct ReviewSessionProgressHeader: View {
    let descriptor: ReviewSessionDescriptor
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
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(descriptor.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(descriptor.method.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 12)

                Text("\(currentIndex + 1) of \(totalCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.blue.opacity(0.08))
                    )
            }

            ProgressView(value: progressValue)
                .tint(.blue)

            VStack(alignment: .leading, spacing: 6) {
                Text("Current Passage")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(reference)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.leading)
            }
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

    let descriptor: ReviewSessionDescriptor
    let summary: ReviewSessionSummary
    let totalVerseCount: Int
    let endedEarly: Bool
    let duration: TimeInterval
    let onReviewAgain: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ReviewSessionSummaryHero(
                    descriptor: descriptor,
                    summary: summary,
                    totalVerseCount: totalVerseCount,
                    endedEarly: endedEarly,
                    duration: duration
                )

                ReviewSessionMetricsSection(summary: summary, duration: duration)

                ReviewSessionNeedsWorkSection(references: summary.missedReferences)

                ReviewSessionActionBar(
                    onDone: { dismiss() },
                    onReviewAgain: onReviewAgain
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}

private struct ReviewSessionSummaryHero: View {
    let descriptor: ReviewSessionDescriptor
    let summary: ReviewSessionSummary
    let totalVerseCount: Int
    let endedEarly: Bool
    let duration: TimeInterval

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: endedEarly ? "pause.circle" : "checkmark.circle")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(endedEarly ? .orange : .green)

            Text(endedEarly ? "Review ended early" : "Session completed")
                .font(.title2.weight(.semibold))

            Text(descriptor.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(endedEarly ? "\(summary.reviewedCount) of \(totalVerseCount) reviewed" : "\(summary.reviewedCount) verse\(summary.reviewedCount == 1 ? "" : "s") reviewed")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if duration > 0 {
                Text(formattedDuration(duration))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ReviewSessionMetricsSection: View {
    let summary: ReviewSessionSummary
    let duration: TimeInterval

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ReviewSessionMetricCard(title: "Reviewed", value: summary.reviewedCount.formatted(), tint: .primary)
                ReviewSessionMetricCard(title: "Correct", value: summary.correctCount.formatted(), tint: .green)
            }

            HStack(spacing: 12) {
                ReviewSessionMetricCard(title: "Missed", value: summary.missedCount.formatted(), tint: .red)

                if duration > 0 {
                    ReviewSessionMetricCard(title: "Time", value: conciseDuration(duration), tint: .blue)
                } else {
                    ReviewSessionMetricCard(title: "Method", value: "Scored", tint: .blue)
                }
            }
        }
    }
}

private struct ReviewSessionMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
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

private struct ReviewSessionNeedsWorkSection: View {
    let references: [String]

    var body: some View {
        if !references.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Needs Work")
                    .font(.headline)

                ForEach(Array(references.enumerated()), id: \.offset) { entry in
                    Text(entry.element)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.red.opacity(0.08))
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ReviewSessionActionBar: View {
    let onDone: () -> Void
    let onReviewAgain: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Button("Done") {
                onDone()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let onReviewAgain {
                Button("Review Again") {
                    onReviewAgain()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private func conciseDuration(_ duration: TimeInterval) -> String {
    let components = durationComponents(duration)

    if components.hour ?? 0 > 0 {
        return "\(components.hour ?? 0)h \(components.minute ?? 0)m"
    }

    if components.minute ?? 0 > 0 {
        return "\(components.minute ?? 0)m"
    }

    return "\(max(components.second ?? 0, 1))s"
}

private func formattedDuration(_ duration: TimeInterval) -> String {
    let components = durationComponents(duration)
    var parts: [String] = []

    if let hour = components.hour, hour > 0 {
        parts.append("\(hour) hr")
    }

    if let minute = components.minute, minute > 0 {
        parts.append("\(minute) min")
    }

    if parts.isEmpty {
        parts.append("\(max(components.second ?? 0, 1)) sec")
    }

    return parts.joined(separator: " ")
}

private func durationComponents(_ duration: TimeInterval) -> DateComponents {
    let startDate = Date(timeIntervalSinceReferenceDate: 0)
    let endDate = startDate.addingTimeInterval(duration)
    return Calendar.current.dateComponents([.hour, .minute, .second], from: startDate, to: endDate)
}
