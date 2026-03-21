import SwiftUI

struct HomeView: View {
    private struct VerseOfTheDay {
        let reference: String
        let text: String
    }

    @State private var verses: [Verse] = VerseRepository.shared.loadVerses()
    @State private var reviewQueue: [Verse] = []
    @State private var selectedBatchReviewMethod: ReviewMethod? = nil
    @State private var showingBatchReviewMethodPicker = false

    private let reviewQueueBuilder = ReviewQueueBuilder()

    private let placeholderVerses = [
        VerseOfTheDay(
            reference: "Psalm 119:11",
            text: "I have stored up your word in my heart, that I might not sin against you."
        ),
        VerseOfTheDay(
            reference: "Joshua 1:9",
            text: "Be strong and courageous. Do not be frightened, and do not be dismayed, for the Lord your God is with you wherever you go."
        ),
        VerseOfTheDay(
            reference: "Romans 12:2",
            text: "Be transformed by the renewal of your mind, that by testing you may discern what is the will of God."
        )
    ]

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

    private var verseOfTheDay: VerseOfTheDay {
        if !verses.isEmpty {
            let index = Calendar.current.ordinality(of: .day, in: .year, for: Date()).map { ($0 - 1) % verses.count } ?? 0
            let verse = verses[index]
            return VerseOfTheDay(reference: verse.reference, text: verse.text)
        }

        let index = Calendar.current.ordinality(of: .day, in: .year, for: Date()).map { ($0 - 1) % placeholderVerses.count } ?? 0
        return placeholderVerses[index]
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
        verses.filter { $0.urgencyLevel == .needsReview }.count
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
        .onAppear {
            reloadVerses()
        }
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
            Text("Verse of the Day")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

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
