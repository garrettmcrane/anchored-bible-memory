import SwiftUI

struct ProgressiveWordHidingReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var hidingState: ProgressiveWordHidingState

    init(verses: [Verse], onUpdate: @escaping (Verse) -> Void) {
        self.verses = verses
        self.onUpdate = onUpdate

        let initialText = verses.first?.text ?? ""
        _hidingState = State(initialValue: ProgressiveWordHidingState(text: initialText))
    }

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if verses.isEmpty {
                    Spacer()

                    Text("No learning verses to review.")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Spacer()
                } else {
                    VStack(spacing: 10) {
                        Text("Verse \(currentIndex + 1) of \(verses.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(currentVerse.reference)
                            .font(.title2)
                            .fontWeight(.semibold)
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
                                    .fill(Color(.secondarySystemBackground))
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
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        Button {
                            recordReview(result: .correct)
                        } label: {
                            Text("Got It")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 32)
            .navigationTitle("Review Session")
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
            for: currentVerse,
            method: .progressiveWordHiding,
            result: result
        )

        onUpdate(updatedVerse)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            let nextIndex = currentIndex + 1
            currentIndex = nextIndex
            hidingState = ProgressiveWordHidingState(text: verses[nextIndex].text)
        } else {
            dismiss()
        }
    }
}

#Preview {
    let verse1 = Verse(
        reference: "John 3:16",
        text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life."
    )

    let verse2 = Verse(
        reference: "Romans 8:28",
        text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose."
    )

    return ProgressiveWordHidingReviewSessionView(verses: [verse1, verse2], onUpdate: { _ in })
}
