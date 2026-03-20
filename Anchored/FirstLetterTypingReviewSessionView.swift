import SwiftUI

struct FirstLetterTypingReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isStepFieldFocused: Bool

    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var reconstructionState: FirstLetterTypingState
    @State private var stepInput = ""
    @State private var showIncorrectHint = false
    @State private var incorrectFlashToken = 0
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false
    @State private var verseReports: [FirstLetterTypingVersePerformance] = []

    init(verses: [Verse], onUpdate: @escaping (Verse) -> Void) {
        self.verses = verses
        self.onUpdate = onUpdate
        _reconstructionState = State(initialValue: FirstLetterTypingState(text: verses.first?.text ?? ""))
    }

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                if verses.isEmpty {
                    emptyState
                } else if isSessionComplete {
                    FirstLetterTypingSessionCompletionView(summary: summary, verseReports: verseReports)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ReviewSessionProgressHeader(
                                currentIndex: currentIndex,
                                totalCount: verses.count,
                                reference: currentVerse.reference
                            )

                            verseStep
                                .id(currentVerse.id)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Review Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
            .animation(.easeInOut(duration: 0.2), value: isSessionComplete)
        }
    }

    private var verseStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(reconstructionState.currentPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            FirstLetterTypingVerseCard(state: reconstructionState)

            if reconstructionState.isComplete {
                FirstLetterTypingPerformanceCard(performance: reconstructionState.performance(for: currentVerse))

                ReviewResultButtons(
                    onMissed: { recordReview(result: .missed) },
                    onCorrect: { recordReview(result: .correct) }
                )
            } else {
                inputCard
            }
        }
        .onAppear {
            isStepFieldFocused = !reconstructionState.isComplete
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Next Letter")
                .font(.headline)

            TextField("Type the next first letter", text: $stepInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isStepFieldFocused)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(showIncorrectHint ? Color.red : Color(.separator), lineWidth: 1)
                )
                .offset(x: showIncorrectHint ? shakeOffset : 0)
                .onChange(of: stepInput) { _, newValue in
                    handleInputChange(newValue)
                }

            Text(showIncorrectHint ? "Try again" : "Enter one letter at a time to reveal the next word.")
                .font(.subheadline)
                .foregroundStyle(showIncorrectHint ? .red : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.12), value: incorrectFlashToken)
    }

    private var emptyState: some View {
        VStack {
            Spacer()

            Text("No verses to review.")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 32)
    }

    private func handleInputChange(_ newValue: String) {
        guard let typedLetter = FirstLetterTypingSupport.normalizedLeadingLetter(from: newValue) else {
            showIncorrectHint = false
            return
        }

        if reconstructionState.submit(String(typedLetter)) {
            stepInput = ""
            showIncorrectHint = false
            isStepFieldFocused = !reconstructionState.isComplete
        } else {
            showIncorrectHint = true
            incorrectFlashToken += 1
            stepInput = ""
            isStepFieldFocused = true
        }
    }

    private var shakeOffset: CGFloat {
        incorrectFlashToken.isMultiple(of: 2) ? -6 : 6
    }

    private func recordReview(result: ReviewResult) {
        verseReports.append(reconstructionState.performance(for: currentVerse))

        let updatedVerse = ReviewRepository.shared.recordReview(
            for: currentVerse,
            method: .firstLetterTyping,
            result: result
        )

        onUpdate(updatedVerse)
        summary.record(result)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            let nextIndex = currentIndex + 1
            currentIndex = nextIndex
            reconstructionState = FirstLetterTypingState(text: verses[nextIndex].text)
            stepInput = ""
            showIncorrectHint = false
            incorrectFlashToken = 0
            isStepFieldFocused = true
        } else {
            isSessionComplete = true
        }
    }
}

#Preview {
    FirstLetterTypingReviewSessionView(
        verses: [
            Verse(reference: "Genesis 1:1", text: "In the beginning, God created the heavens and the earth."),
            Verse(reference: "Psalm 119:11", text: "I have stored up your word in my heart, that I might not sin against you.")
        ],
        onUpdate: { _ in }
    )
}
