import SwiftUI

struct ProgressiveWordHidingReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let descriptor: ReviewSessionDescriptor
    let verses: [Verse]
    let onUpdate: (Verse) -> Void

    @State private var currentIndex = 0
    @State private var hidingState: ProgressiveWordHidingState
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false
    @State private var endedEarly = false
    @State private var showingEndEarlyConfirmation = false
    @State private var sessionStartDate = Date()

    init(descriptor: ReviewSessionDescriptor, verses: [Verse], onUpdate: @escaping (Verse) -> Void) {
        self.descriptor = descriptor
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
            sessionContent
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .navigationTitle(descriptor.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .confirmationDialog("End session early?", isPresented: $showingEndEarlyConfirmation, titleVisibility: .visible) {
                Button("End Review") {
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
        summary.record(result, reference: currentVerse.reference)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            let nextIndex = currentIndex + 1
            withAnimation(.easeInOut(duration: 0.22)) {
                currentIndex = nextIndex
                hidingState = ProgressiveWordHidingState(text: verses[nextIndex].text)
            }
        } else {
            isSessionComplete = true
        }
    }

    private var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartDate)
    }

    private func resetSession() {
        currentIndex = 0
        hidingState = ProgressiveWordHidingState(text: verses.first?.text ?? "")
        summary = ReviewSessionSummary()
        isSessionComplete = false
        endedEarly = false
        sessionStartDate = Date()
    }

    @ViewBuilder
    private var sessionContent: some View {
        if verses.isEmpty {
            emptyState
        } else if isSessionComplete {
            completionContent
        } else {
            reviewContent
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()

            Text("No verses to review.")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var completionContent: some View {
        let reviewAgainAction: (() -> Void)? = verses.isEmpty ? nil : { resetSession() }

        return ReviewSessionCompletionView(
            descriptor: descriptor,
            summary: summary,
            totalVerseCount: verses.count,
            endedEarly: endedEarly,
            duration: sessionDuration,
            onReviewAgain: reviewAgainAction
        )
    }

    private var reviewContent: some View {
        VStack(spacing: 20) {
            ReviewSessionProgressHeader(
                descriptor: descriptor,
                currentIndex: currentIndex,
                totalCount: verses.count,
                reference: currentVerse.reference
            )

            verseCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(currentVerse.id)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private var verseCard: some View {
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
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if !isSessionComplete {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") {
                    showingEndEarlyConfirmation = true
                }
            }
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

    return ProgressiveWordHidingReviewSessionView(
        descriptor: ReviewSessionDescriptor(title: "Smart Review", method: .progressiveWordHiding),
        verses: [verse1, verse2],
        onUpdate: { _ in }
    )
}
