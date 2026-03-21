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
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text("Hide more words as you recite, then score your recall.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.lightTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                ScrollView {
                    Text(hidingState.displayedText)
                        .font(.system(.title3, design: .serif))
                        .lineSpacing(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppColors.lightSurface)
                        )
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        hidingState.hideMoreWords()
                    } label: {
                        Text("Hide More Words")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hidingState.canHideMoreWords)

                    Button {
                        hidingState.reset()
                    } label: {
                        Text("Reset")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hidingState.hasHiddenWords)
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button {
                        recordReview(result: .missed)
                    } label: {
                        Text("Missed")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.gold.opacity(0.15))
                            .foregroundStyle(AppColors.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Button {
                        recordReview(result: .correct)
                    } label: {
                        Text("Got It")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.gold.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
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
