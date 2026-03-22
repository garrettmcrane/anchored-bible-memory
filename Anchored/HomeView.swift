import SwiftUI

struct HomeView: View {
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
    @State private var isShowingSettings = false
    @State private var isShowingNotifications = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @State private var isShowingAddFlow = false
    @State private var addFocusTrigger = 0

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

    private var firstName: String {
        let trimmedName = LocalSession.currentUserDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedName.split(separator: " ")
        return components.first.map(String.init) ?? "Friend"
    }

    private var personalizedGreetingText: String {
        "\(greetingText), \(firstName)"
    }

    private var verseOfTheDayIsInLibrary: Bool {
        verses.contains { verse in
            verseMatchesVerseOfTheDay(verse)
        }
    }

    private var practicingVerses: [Verse] {
        VerseQueries.practicingVerses(verses)
    }

    private var memorizedCount: Int {
        VerseQueries.memorizedVerses(verses).count
    }

    private var practicingCount: Int {
        practicingVerses.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    header
                    greetingSection
                    verseCard
                    summarySection
                    reviewButtons
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingNotifications = false
                    isShowingSettings = false
                    // Present Add flow
                    addVerse()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add")
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
        .onReceive(NotificationCenter.default.publisher(for: .versesDidChange)) { _ in
            reloadVerses()
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
        .sheet(isPresented: $isShowingNotifications) {
            NotificationsPlaceholderView()
        }
        .sheet(isPresented: $isShowingAddFlow) {
            AddHubView(showsCancelButton: true, focusTrigger: addFocusTrigger) { newVerse in
                VerseRepository.shared.addVerse(newVerse)
                verses = VerseRepository.shared.loadVerses()
            }
        }
    }

    private var header: some View {
        MainScreenTopBar(
            title: "Home",
            onNotificationsTap: {
                isShowingNotifications = true
            },
            onSettingsTap: {
                isShowingSettings = true
            }
        )
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(personalizedGreetingText)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, 2)

            Text("Keep your next review close and your library growing steadily.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("Verse of the Day")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.structuralAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColors.verseOfTheDayBadgeFill)
                    )

                Spacer(minLength: 0)

                Button {
                    quickAddVerseOfTheDay()
                } label: {
                    Image(systemName: verseOfTheDayIsInLibrary ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary.opacity(0.96))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppColors.textPrimary.opacity(verseOfTheDayIsInLibrary ? 0.22 : 0.16))
                        )
                        .overlay {
                            Circle()
                                .stroke(AppColors.textPrimary.opacity(0.14), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(verseOfTheDayIsInLibrary)
                .accessibilityLabel(verseOfTheDayIsInLibrary ? "Already in Library" : "Add Verse of the Day")
            }

            Text(verseOfTheDay.reference)
                .font(.title3.weight(.semibold))
                .foregroundStyle(verseOfTheDayReferenceColor)

            Text(verseOfTheDay.text)
                .font(.system(.body, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
        .foregroundStyle(AppColors.textPrimary)
    }

    private var summarySection: some View {
        HStack(spacing: 0) {
            HomeMetricColumn(title: "Memorized", value: memorizedCount)
            HomeMetricColumn(title: "Practicing", value: practicingCount)
            HomeMetricColumn(title: "All", value: verses.count)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        )
    }

    private var reviewButtons: some View {
        VStack(spacing: 12) {
            Button {
                startPracticingReview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                    Text("Review Practicing")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.reviewPracticingActionBackground)
            .foregroundStyle(AppColors.reviewPracticingActionText)
            .disabled(practicingVerses.isEmpty)

            Button {
                startAllReview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                    Text("Review All")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.reviewAllActionBackground)
            .foregroundStyle(AppColors.reviewAllActionText)
            .disabled(verses.isEmpty)
        }
    }

    private var verseOfTheDayReferenceColor: Color {
        colorScheme == .light ? AppColors.verseOfTheDayReference : AppColors.scriptureAccent
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

    private func startPracticingReview() {
        let queue = reviewQueueBuilder.buildPracticingQueue(from: verses)

        guard !queue.isEmpty else {
            return
        }

        reviewStartConfiguration = ReviewStartConfiguration(
            title: "Review Practicing",
            description: "Review only the verses you are still working on.",
            verses: queue
        )
    }

    private func startAllReview() {
        let queue = reviewQueueBuilder.buildAllQueue(from: verses)

        guard !queue.isEmpty else {
            return
        }

        reviewStartConfiguration = ReviewStartConfiguration(
            title: "Review All",
            description: "Review every verse in your personal library.",
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
                tint: AppColors.scriptureAccent
            )
        } else {
            feedback = QuickAddFeedback(
                message: "Unable to add verse",
                systemImage: "exclamationmark.circle.fill",
                tint: AppColors.textSecondary
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

    private func addVerse() {
        addFocusTrigger += 1
        isShowingAddFlow = true
    }
}

private struct HomeMetricColumn: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
}
