import SwiftUI
import UIKit

struct FirstLetterTypingReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isStepFieldFocused: Bool

    let verse: Verse
    let onUpdate: (Verse) -> Void

    @State private var reconstructionState: FirstLetterTypingState
    @State private var stepInput = ""
    @State private var showIncorrectHint = false
    @State private var incorrectFlashToken = 0
    @State private var showVerseErrorFlash = false

    private var performance: FirstLetterTypingVersePerformance {
        reconstructionState.performance(for: verse)
    }

    init(verse: Verse, onUpdate: @escaping (Verse) -> Void) {
        self.verse = verse
        self.onUpdate = onUpdate
        _reconstructionState = State(initialValue: FirstLetterTypingState(text: verse.text))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text(verse.reference)
                            .font(AnchoredFont.editorial(30))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.scriptureAccent)

                        Text(reconstructionState.currentPrompt)
                            .font(AnchoredFont.uiSubheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    FirstLetterTypingVerseCard(state: reconstructionState, isErrorFlashing: showVerseErrorFlash)

                    if reconstructionState.isComplete {
                        FirstLetterTypingPerformanceCard(performance: performance)

                        Button("Finish Review") {
                            recordReview()
                        }
                        .buttonStyle(AnchoredPrimaryButtonStyle())
                    } else {
                        inputCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppColors.structuralAccent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isStepFieldFocused = true
                FirstLetterTypingFeedback.prepare()
            }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Next Letter")
                .font(AnchoredFont.ui(17, weight: .semibold))

            TextField("Type the next first letter", text: $stepInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isStepFieldFocused)
                .font(AnchoredFont.ui(20, weight: .semibold))
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(showIncorrectHint ? AppColors.gold : AppColors.divider, lineWidth: 1)
                )
                .offset(x: showIncorrectHint ? shakeOffset : 0)
                .onChange(of: stepInput) { _, newValue in
                    handleInputChange(newValue)
                }

            Text(showIncorrectHint ? "Try again" : "Enter one letter at a time to reveal the next word.")
                .font(AnchoredFont.uiSubheadline)
                .foregroundStyle(showIncorrectHint ? AppColors.gold : AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
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
            triggerIncorrectFeedback()
            stepInput = ""
            isStepFieldFocused = true
        }
    }

    private func triggerIncorrectFeedback() {
        FirstLetterTypingFeedback.triggerLightImpactIfNeeded()

        withAnimation(.easeInOut(duration: 0.18)) {
            showVerseErrorFlash = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            showVerseErrorFlash = false
        }
    }

    private func recordReview() {
        let updatedVerse = ReviewRepository.shared.recordReview(
            for: verse,
            method: .firstLetterTyping,
            result: performance.reviewResult
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
