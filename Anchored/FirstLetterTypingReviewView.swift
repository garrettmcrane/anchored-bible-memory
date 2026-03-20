import SwiftUI

struct FirstLetterTypingReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isStepFieldFocused: Bool

    let verse: Verse
    let onUpdate: (Verse) -> Void

    @State private var reconstructionState: FirstLetterTypingState
    @State private var stepInput = ""
    @State private var showIncorrectHint = false
    @State private var incorrectFlashToken = 0

    init(verse: Verse, onUpdate: @escaping (Verse) -> Void) {
        self.verse = verse
        self.onUpdate = onUpdate
        _reconstructionState = State(initialValue: FirstLetterTypingState(text: verse.text))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text(verse.reference)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text(reconstructionState.currentPrompt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    FirstLetterTypingVerseCard(state: reconstructionState)

                    if reconstructionState.isComplete {
                        FirstLetterTypingPerformanceCard(performance: reconstructionState.performance(for: verse))

                        ReviewResultButtons(
                            onMissed: { recordReview(result: .missed) },
                            onCorrect: { recordReview(result: .correct) }
                        )
                    } else {
                        inputCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isStepFieldFocused = true
            }
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

    private var shakeOffset: CGFloat {
        incorrectFlashToken.isMultiple(of: 2) ? -6 : 6
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

    private func recordReview(result: ReviewResult) {
        let updatedVerse = ReviewRepository.shared.recordReview(
            for: verse,
            method: .firstLetterTyping,
            result: result
        )

        onUpdate(updatedVerse)
        dismiss()
    }
}

#Preview {
    FirstLetterTypingReviewView(
        verse: Verse(
            reference: "Genesis 1:1",
            text: "In the beginning, God created the heavens and the earth."
        ),
        onUpdate: { _ in }
    )
}
