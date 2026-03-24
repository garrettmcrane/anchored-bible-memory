import SwiftUI

struct ProgressiveWordHidingReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let verse: Verse
    let onUpdate: (Verse) -> Void

    @State private var hidingState: ProgressiveWordHidingState

    init(verse: Verse, onUpdate: @escaping (Verse) -> Void) {
        self.verse = verse
        self.onUpdate = onUpdate
        _hidingState = State(initialValue: ProgressiveWordHidingState(text: verse.text))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text(verse.reference)
                        .font(AnchoredFont.editorial(30))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.scriptureAccent)

                    Text("Hide more words as you recite, then score your recall.")
                        .font(AnchoredFont.uiSubheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                ScrollView {
                    Text(hidingState.displayedText)
                        .font(AnchoredFont.scripture(24))
                        .lineSpacing(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppColors.surface)
                        )
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                Button {
                    hidingState.hideMoreWords()
                } label: {
                    Text("Hide More Words")
                }
                .buttonStyle(AnchoredPrimaryButtonStyle())
                .disabled(!hidingState.canHideMoreWords)

                Button {
                    hidingState.reset()
                } label: {
                    Text("Reset")
                }
                .buttonStyle(.glass)
                .disabled(!hidingState.hasHiddenWords)
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button {
                        recordReview(result: .missed)
                    } label: {
                        Text("Missed")
                    }
                    .buttonStyle(AnchoredMissedButtonStyle())

                    Button {
                        recordReview(result: .correct)
                    } label: {
                        Text("Got It")
                    }
                    .buttonStyle(AnchoredSuccessButtonStyle())
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 32)
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func recordReview(result: ReviewResult) {
        let updatedVerse = ReviewRepository.shared.recordReview(
            for: verse,
            method: .progressiveWordHiding,
            result: result
        )

        onUpdate(updatedVerse)
        dismiss()
    }
}

#Preview {
    ProgressiveWordHidingReviewView(
        verse: Verse(
            reference: "Psalm 119:11",
            text: "I have stored up your word in my heart, that I might not sin against you."
        ),
        onUpdate: { _ in }
    )
}
