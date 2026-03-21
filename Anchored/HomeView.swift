import SwiftUI

struct HomeView: View {
    private struct QuickAddFeedback: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let systemImage: String
        let tint: Color
    }

    @State private var verses: [Verse] = []
    @State private var reviewQueue: [Verse] = []
    @State private var selectedBatchReviewMethod: ReviewMethod? = nil
    @State private var showingBatchReviewMethodPicker = false
    @State private var quickAddFeedback: QuickAddFeedback?
    @State private var feedbackDismissTask: Task<Void, Never>?
    @State private var verseOfTheDay = VerseOfTheDayContent(
        reference: VerseOfTheDayService.fallbackReference,
        text: "Loading today's verse..."
    )
    @State private var verseOfTheDayDayKey = ""
    @Environment(\.scenePhase) private var scenePhase

    private let reviewQueueBuilder = ReviewQueueBuilder()

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private var verseOfTheDayIsInLibrary: Bool {
        verses.contains { verse in
            verseMatchesVerseOfTheDay(verse)
        }
    }

    private var learningVerses: [Verse] {
        VerseQueries.learningVerses(verses)
    }

    private var memorizedCount: Int {
        VerseQueries.memorizedVerses(verses).count
    }

    private var learningCount: Int {
        learningVerses.count
    }

    private var needsAttentionCount: Int {
        verses.filter { VerseStrengthService.needsAttention(for: $0) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    header
                    verseCard
                    summarySection
                    reviewButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedBatchReviewMethod, onDismiss: clearReviewSession) { method in
            switch method {
            case .flashcard:
                ReviewSessionView(verses: reviewQueue) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewSessionView(verses: reviewQueue) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            case .firstLetterTyping:
                FirstLetterTypingReviewSessionView(verses: reviewQueue) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            }
        }
        .confirmationDialog("Choose Review Style", isPresented: $showingBatchReviewMethodPicker, titleVisibility: .visible) {
            ForEach(ReviewMethod.allCases) { method in
                Button(method.title) {
                    selectedBatchReviewMethod = method
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you want to review this session.")
        }
        .task {
            await loadInitialVersesIfNeeded()
            await refreshVerseOfTheDayIfNeeded(force: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await refreshVerseOfTheDayIfNeeded()
            }
        }
        .overlay(alignment: .bottom) {
            if let quickAddFeedback {
                FeedbackToast(
                    message: quickAddFeedback.message,
                    systemImage: quickAddFeedback.systemImage,
                    tint: quickAddFeedback.tint
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: quickAddFeedback)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text(greetingText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("Verse of the Day")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button {
                    quickAddVerseOfTheDay()
                } label: {
                    Image(systemName: verseOfTheDayIsInLibrary ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(verseOfTheDayIsInLibrary ? 0.22 : 0.16))
                        )
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(verseOfTheDayIsInLibrary)
                .accessibilityLabel(verseOfTheDayIsInLibrary ? "Already in Library" : "Add Verse of the Day")
            }

            Text(verseOfTheDay.reference)
                .font(.title3.weight(.semibold))

            Text(verseOfTheDay.text)
                .font(.system(.body, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.27, blue: 0.53),
                            Color(red: 0.22, green: 0.46, blue: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .foregroundStyle(.white)
    }

    private var summarySection: some View {
        HStack(spacing: 0) {
            HomeMetricColumn(title: "Memorized", value: memorizedCount)
            HomeMetricColumn(title: "Learning", value: learningCount)
            HomeMetricColumn(title: "Needs Attention", value: needsAttentionCount)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
    }

    private var reviewButton: some View {
        Button {
            startSmartReview()
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("Review Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(smartReviewQueue.isEmpty)
    }

    private func reloadVerses() {
        verses = VerseRepository.shared.loadVerses()
    }

    @MainActor
    private func loadInitialVersesIfNeeded() async {
        guard verses.isEmpty else {
            return
        }

        verses = await VerseRepository.shared.loadVersesAsync()
    }

    private var smartReviewQueue: [Verse] {
        reviewQueueBuilder.buildQueue(from: verses)
    }

    private func startSmartReview() {
        let queue = smartReviewQueue

        guard !queue.isEmpty else {
            return
        }

        reviewQueue = queue
        showingBatchReviewMethodPicker = true
    }

    private func clearReviewSession() {
        selectedBatchReviewMethod = nil
        reviewQueue = []
        verses = VerseRepository.shared.loadVerses()
    }

    @MainActor
    private func refreshVerseOfTheDayIfNeeded(force: Bool = false) async {
        let currentDayKey = VerseOfTheDayService.dayKey()
        guard force || currentDayKey != verseOfTheDayDayKey else {
            return
        }

        let resolvedVerse = await VerseOfTheDayService.resolveDailyVerse()
        verseOfTheDay = resolvedVerse
        verseOfTheDayDayKey = currentDayKey
    }

    private func quickAddVerseOfTheDay() {
        guard !verseOfTheDayIsInLibrary else {
            return
        }

        let passage = ScripturePassage(
            normalizedReference: verseOfTheDay.reference,
            translation: .kjv,
            text: verseOfTheDay.text,
            segments: [
                ScripturePassageSegment(reference: verseOfTheDay.reference, text: verseOfTheDay.text)
            ]
        )
        let verse = ScriptureAddPipeline.makeVerse(from: passage, options: ScriptureSaveOptions())
        VerseRepository.shared.addVerse(verse)
        reloadVerses()

        let feedback: QuickAddFeedback
        if verseOfTheDayIsInLibrary {
            feedback = QuickAddFeedback(
                message: "Added to Library",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
        } else {
            feedback = QuickAddFeedback(
                message: "Unable to add verse",
                systemImage: "exclamationmark.circle.fill",
                tint: .orange
            )
        }

        showQuickAddFeedback(feedback)
    }

    private func showQuickAddFeedback(_ feedback: QuickAddFeedback) {
        feedbackDismissTask?.cancel()
        quickAddFeedback = feedback

        feedbackDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    quickAddFeedback = nil
                }
            }
        }
    }

    private func verseMatchesVerseOfTheDay(_ verse: Verse) -> Bool {
        normalizedMatchText(verse.reference) == normalizedMatchText(verseOfTheDay.reference)
            && normalizedMatchText(verse.text) == normalizedMatchText(verseOfTheDay.text)
    }

    private func normalizedMatchText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }
}

private struct HomeMetricColumn: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
}
