import SwiftUI

struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                if verses.isEmpty {
                    VStack {
                        Spacer()

                        Text("No verses to review.")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                } else if isSessionComplete {
                    ReviewSessionCompletionView(summary: summary)
                } else {
                    VStack(spacing: 20) {
                        ReviewSessionProgressHeader(
                            currentIndex: currentIndex,
                            totalCount: verses.count,
                            reference: currentVerse.reference
                        )

                        VStack(spacing: 24) {
                            if showingAnswer {
                                Text(currentVerse.text)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                Text("Try to recite this verse before revealing it.")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            Spacer(minLength: 0)

                            if showingAnswer {
                                ReviewResultButtons(
                                    onMissed: { recordReview(result: .missed) },
                                    onCorrect: { recordReview(result: .correct) }
                                )
                                .padding(.horizontal)
                            } else {
                                Button {
                                    showingAnswer = true
                                } label: {
                                    Text("Reveal Verse")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 16)
                        .id(currentVerse.id)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
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

    private func recordReview(result: ReviewResult) {
        let updatedVerse = ReviewRepository.shared.recordReview(
            for: currentVerse,
            method: .flashcard,
            result: result
        )

        onUpdate(updatedVerse)
        summary.record(result)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            currentIndex += 1
            showingAnswer = false
        } else {
            isSessionComplete = true
        }
    }
}

#Preview {
    let verse1 = Verse(
        reference: "John 3:16",
        text: "For God so loved the world, that he gave his only Son..."
    )

    let verse2 = Verse(
        reference: "Romans 8:28",
        text: "And we know that for those who love God all things work together for good..."
    )

    return ReviewSessionView(verses: [verse1, verse2], onUpdate: { _ in })
}
