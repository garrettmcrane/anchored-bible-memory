import SwiftUI

struct HomeView: View {
    private enum Destination: Hashable {
        case settings
    }

    private struct BatchReviewPresentation: Identifiable {
        let id = UUID()
        let descriptor: ReviewSessionDescriptor
        let verses: [Verse]
    }

    private struct QuickAddFeedback: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let systemImage: String
        let tint: Color
    }

    @State private var verses: [Verse] = []
    @State private var reviewStartConfiguration: ReviewStartConfiguration?
    @State private var activeBatchReview: BatchReviewPresentation?
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
                AppColors.darkBackground
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
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView()
                }
            }
        }
        .sheet(item: $reviewStartConfiguration) { configuration in
            ReviewStartSheet(configuration: configuration) { method in
                activeBatchReview = BatchReviewPresentation(
                    descriptor: ReviewSessionDescriptor(title: configuration.title, method: method),
                    verses: configuration.verses
                )
            }
        }
        .sheet(item: $activeBatchReview, onDismiss: clearReviewSession) { presentation in
            switch presentation.descriptor.method {
            case .flashcard:
                ReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            case .firstLetterTyping:
                FirstLetterTypingReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            case .voiceRecitation:
                VoiceRecitationReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    verses = VerseRepository.shared.loadVerses()
                }
            }
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
                    .foregroundStyle(AppColors.darkTextPrimary)
            }

            Spacer()

            NavigationLink(value: Destination.settings) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.darkTextPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppColors.darkSurface)
                    )
                    .overlay {
                        Circle()
                            .stroke(AppColors.darkDivider, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("Verse of the Day")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.darkTextSecondary)

                Spacer(minLength: 0)

                Button {
                    quickAddVerseOfTheDay()
                } label: {
                    Image(systemName: verseOfTheDayIsInLibrary ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.darkTextPrimary.opacity(0.96))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppColors.darkTextPrimary.opacity(verseOfTheDayIsInLibrary ? 0.22 : 0.16))
                        )
                        .overlay {
                            Circle()
                                .stroke(AppColors.darkTextPrimary.opacity(0.14), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(verseOfTheDayIsInLibrary)
                .accessibilityLabel(verseOfTheDayIsInLibrary ? "Already in Library" : "Add Verse of the Day")
            }

            Text(verseOfTheDay.reference)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.gold)

            Text(verseOfTheDay.text)
                .font(.system(.body, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(AppColors.darkTextPrimary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.darkSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.darkDivider, lineWidth: 1)
        }
        .foregroundStyle(AppColors.darkTextPrimary)
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
                .fill(AppColors.darkSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.darkDivider, lineWidth: 1)
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
        .tint(AppColors.gold)
        .foregroundStyle(AppColors.darkBackground)
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

        reviewStartConfiguration = ReviewStartConfiguration(
            title: "Smart Review",
            description: "Prioritizes weaker verses and learning passages first.",
            verses: queue
        )
    }

    private func clearReviewSession() {
        activeBatchReview = nil
        reviewStartConfiguration = nil
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
                tint: AppColors.gold
            )
        } else {
            feedback = QuickAddFeedback(
                message: "Unable to add verse",
                systemImage: "exclamationmark.circle.fill",
                tint: AppColors.darkTextSecondary
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
                .foregroundStyle(AppColors.darkTextSecondary.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.darkTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
}
