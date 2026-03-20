import SwiftUI

struct FirstLetterTypingReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isResponseFieldFocused: Bool

    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var typedResponse = ""
    @State private var evaluationResult: ReviewResult? = nil
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                if verses.isEmpty {
                    emptyState
                } else if isSessionComplete {
                    ReviewSessionCompletionView(summary: summary)
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
            promptCard
            responseCard

            if let evaluationResult {
                feedbackCard(for: evaluationResult)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Target Verse")
                        .font(.headline)

                    Text(currentVerse.text)
                        .font(.system(.body, design: .serif))
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                ReviewResultButtons(
                    onMissed: { recordReview(result: .missed) },
                    onCorrect: { recordReview(result: .correct) }
                )
            } else {
                Button {
                    evaluationResult = FirstLetterTypingSupport.evaluateResponse(typedResponse, against: currentVerse.text)
                    isResponseFieldFocused = false
                } label: {
                    Text("Check")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(FirstLetterTypingSupport.normalizedText(typedResponse).isEmpty)
            }
        }
        .onAppear {
            isResponseFieldFocused = true
        }
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("First-Letter Pattern")
                .font(.headline)

            Text(FirstLetterTypingSupport.pattern(for: currentVerse.text))
                .font(.system(.title3, design: .serif))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Response")
                .font(.headline)

            TextEditor(text: $typedResponse)
                .focused($isResponseFieldFocused)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func feedbackCard(for result: ReviewResult) -> some View {
        let isCorrect = result == .correct

        return VStack(alignment: .leading, spacing: 8) {
            Text(isCorrect ? "Close Enough" : "Needs Work")
                .font(.headline)
                .foregroundStyle(isCorrect ? .green : .red)

            Text(
                isCorrect
                ? "Your response matched closely enough after ignoring punctuation, case, and spacing noise."
                : "Your response did not match closely enough. Review the verse, then choose the score that best reflects your recall."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill((isCorrect ? Color.green : Color.red).opacity(0.1))
        )
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

    private func recordReview(result: ReviewResult) {
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
            currentIndex += 1
            typedResponse = ""
            evaluationResult = nil
            isResponseFieldFocused = true
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
