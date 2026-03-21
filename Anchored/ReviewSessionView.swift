import SwiftUI

struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let descriptor: ReviewSessionDescriptor
    let verses: [Verse]
    let onUpdate: (Verse) -> Void
    let groupID: String?

    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false
    @State private var endedEarly = false
    @State private var showingEndEarlyConfirmation = false
    @State private var sessionStartDate = Date()

    init(
        descriptor: ReviewSessionDescriptor,
        verses: [Verse],
        onUpdate: @escaping (Verse) -> Void,
        groupID: String? = nil
    ) {
        self.descriptor = descriptor
        self.verses = verses
        self.onUpdate = onUpdate
        self.groupID = groupID
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
        let updatedVerse: Verse

        if let groupID {
            ReviewRepository.shared.recordGroupReview(
                for: currentVerse,
                groupID: groupID,
                method: .flashcard,
                result: result
            )
            updatedVerse = currentVerse
        } else {
            updatedVerse = ReviewRepository.shared.recordReview(
                for: currentVerse,
                method: .flashcard,
                result: result
            )
        }

        onUpdate(updatedVerse)
        summary.record(result, reference: currentVerse.reference)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentIndex += 1
                showingAnswer = false
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
        showingAnswer = false
        summary = ReviewSessionSummary()
        endedEarly = false
        isSessionComplete = false
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
                .padding(.vertical, 16)
                .id(currentVerse.id)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private var verseCard: some View {
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
        text: "For God so loved the world, that he gave his only Son..."
    )

    let verse2 = Verse(
        reference: "Romans 8:28",
        text: "And we know that for those who love God all things work together for good..."
    )

    return ReviewSessionView(
        descriptor: ReviewSessionDescriptor(title: "Smart Review", method: .flashcard),
        verses: [verse1, verse2],
        onUpdate: { _ in }
    )
}
