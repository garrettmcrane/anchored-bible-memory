import SwiftUI
import UIKit

struct FirstLetterTypingReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isStepFieldFocused: Bool

    let descriptor: ReviewSessionDescriptor
    let verses: [Verse]
    let onUpdate: (Verse) -> Void
    let groupID: String?

    @State private var currentIndex = 0
    @State private var reconstructionState: FirstLetterTypingState
    @State private var stepInput = ""
    @State private var showIncorrectHint = false
    @State private var incorrectFlashToken = 0
    @State private var showVerseErrorFlash = false
    @State private var summary = ReviewSessionSummary()
    @State private var isSessionComplete = false
    @State private var verseReports: [FirstLetterTypingVersePerformance] = []
    @State private var endedEarly = false
    @State private var showingEndEarlyConfirmation = false
    @State private var sessionStartDate = Date()

    private var performance: FirstLetterTypingVersePerformance {
        reconstructionState.performance(for: currentVerse)
    }

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
        _reconstructionState = State(initialValue: FirstLetterTypingState(text: verses.first?.text ?? ""))
    }

    private var currentVerse: Verse {
        verses[currentIndex]
    }

    var body: some View {
        NavigationStack {
            sessionContent
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

    private var verseStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(reconstructionState.currentPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            FirstLetterTypingVerseCard(state: reconstructionState, isErrorFlashing: showVerseErrorFlash)

            if reconstructionState.isComplete {
                FirstLetterTypingPerformanceCard(performance: performance)

                Button(currentIndex + 1 < verses.count ? "Next Verse" : "Finish Session") {
                    recordReview()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                inputCard
            }
        }
        .onAppear {
            isStepFieldFocused = !reconstructionState.isComplete
            FirstLetterTypingFeedback.prepare()
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

    private var emptyState: some View {
        VStack {
            Spacer()

            Text("No verses to review.")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 32)
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

    private var shakeOffset: CGFloat {
        incorrectFlashToken.isMultiple(of: 2) ? -6 : 6
    }

    private func recordReview() {
        verseReports.append(performance)

        let updatedVerse: Verse

        if let groupID {
            ReviewRepository.shared.recordGroupReview(
                for: currentVerse,
                groupID: groupID,
                method: .firstLetterTyping,
                result: performance.reviewResult
            )
            updatedVerse = currentVerse
        } else {
            updatedVerse = ReviewRepository.shared.recordReview(
                for: currentVerse,
                method: .firstLetterTyping,
                result: performance.reviewResult
            )
        }

        onUpdate(updatedVerse)
        summary.record(performance.reviewResult, reference: currentVerse.reference)
        moveToNextVerseOrFinish()
    }

    private func moveToNextVerseOrFinish() {
        if currentIndex + 1 < verses.count {
            let nextIndex = currentIndex + 1
            withAnimation(.easeInOut(duration: 0.22)) {
                currentIndex = nextIndex
                reconstructionState = FirstLetterTypingState(text: verses[nextIndex].text)
                stepInput = ""
                showIncorrectHint = false
                incorrectFlashToken = 0
                showVerseErrorFlash = false
                isStepFieldFocused = true
            }
        } else {
            isSessionComplete = true
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

    private var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartDate)
    }

    private func resetSession() {
        currentIndex = 0
        reconstructionState = FirstLetterTypingState(text: verses.first?.text ?? "")
        stepInput = ""
        showIncorrectHint = false
        incorrectFlashToken = 0
        showVerseErrorFlash = false
        summary = ReviewSessionSummary()
        isSessionComplete = false
        verseReports = []
        endedEarly = false
        sessionStartDate = Date()
        isStepFieldFocused = true
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

    private var completionContent: some View {
        let reviewAgainAction: (() -> Void)? = verses.isEmpty ? nil : { resetSession() }

        return FirstLetterTypingSessionCompletionView(
            descriptor: descriptor,
            summary: summary,
            verseReports: verseReports,
            totalVerseCount: verses.count,
            endedEarly: endedEarly,
            duration: sessionDuration,
            onReviewAgain: reviewAgainAction
        )
    }

    private var reviewContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ReviewSessionProgressHeader(
                    descriptor: descriptor,
                    currentIndex: currentIndex,
                    totalCount: verses.count,
                    reference: currentVerse.reference
                )

                verseStep
                    .id(currentVerse.id)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
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
    FirstLetterTypingReviewSessionView(
        descriptor: ReviewSessionDescriptor(title: "Smart Review", method: .firstLetterTyping),
        verses: [
            Verse(reference: "Genesis 1:1", text: "In the beginning, God created the heavens and the earth."),
            Verse(reference: "Psalm 119:11", text: "I have stored up your word in my heart, that I might not sin against you.")
        ],
        onUpdate: { _ in }
    )
}
