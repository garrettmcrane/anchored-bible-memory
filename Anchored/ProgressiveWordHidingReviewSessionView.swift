import SwiftUI

struct ProgressiveWordHidingReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var hidingState: ProgressiveWordHidingState
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false
    @State private var endedEarly = false
    @State private var showingEndEarlyConfirmation = false

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
                    ReviewSessionCompletionView(
                        summary: summary,
                        totalVerseCount: verses.count,
                        endedEarly: endedEarly
                    )
                } else {
                    VStack(spacing: 20) {
                        ReviewSessionProgressHeader(
                            currentIndex: currentIndex,
                            totalCount: verses.count,
                            reference: currentVerse.reference
                        )

                        VStack(spacing: 20) {
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

                            ReviewResultButtons(
                                onMissed: { recordReview(result: .missed) },
                                onCorrect: { recordReview(result: .correct) }
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                if !isSessionComplete {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("End Early") {
                            showingEndEarlyConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog("End session early?", isPresented: $showingEndEarlyConfirmation, titleVisibility: .visible) {
                Button("Complete Early") {
                    endedEarly = true
                    isSessionComplete = true
                }

                Button("Keep Reviewing", role: .cancel) {}
            } message: {
                Text("You’ll still see results for the verses you’ve already reviewed.")
            }
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
            .animation(.easeInOut(duration: 0.2), value: isSessionComplete)
        }
    }

    private func recordReview(result: ReviewResult) {
        let updatedVerse = ReviewRepository.shared.recordReview(
            for: currentVerse,
            method: .progressiveWordHiding,
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
            hidingState = ProgressiveWordHidingState(text: verses[nextIndex].text)
        } else {
            isSessionComplete = true
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
