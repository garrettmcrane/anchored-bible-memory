import SwiftUI

struct FirstLetterTypingReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isResponseFieldFocused: Bool

    let verse: Verse
    let onUpdate: (Verse) -> Void

    @State private var typedResponse = ""
    @State private var evaluationResult: ReviewResult? = nil

    private var firstLetterPattern: String {
        FirstLetterTypingSupport.pattern(for: verse.text)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text(verse.reference)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("Use the first-letter pattern to type the verse from memory, then score your recall.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    promptCard
                    responseCard

                    if let evaluationResult {
                        feedbackCard(for: evaluationResult)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Target Verse")
                                .font(.headline)

                            Text(verse.text)
                                .font(.system(.body, design: .serif))
                                .lineSpacing(6)
                                .foregroundStyle(.primary)
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
                            evaluationResult = FirstLetterTypingSupport.evaluateResponse(typedResponse, against: verse.text)
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
                isResponseFieldFocused = true
            }
        }
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("First-Letter Pattern")
                .font(.headline)

            Text(firstLetterPattern)
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
