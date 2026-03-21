import SwiftUI

struct VerseDetailView: View {
    private static let uncategorizedFolderName = "Uncategorized"
    let verse: Verse
    let onStartReview: (Verse, ReviewMethod) -> Void
    let onVerseUpdated: (Verse) -> Void

    @State private var currentVerse: Verse
    @State private var reviewStartConfiguration: ReviewStartConfiguration?

    init(
        verse: Verse,
        onStartReview: @escaping (Verse, ReviewMethod) -> Void,
        onVerseUpdated: @escaping (Verse) -> Void = { _ in }
    ) {
        self.verse = verse
        self.onStartReview = onStartReview
        self.onVerseUpdated = onVerseUpdated
        _currentVerse = State(initialValue: verse)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(currentVerse.reference)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    progressBar

                    Text(currentVerse.text)
                        .font(.system(.title3, design: .serif))
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 16) {
                    masteryPicker

                    HStack(spacing: 12) {
                        signalCard(
                            title: "Last Reviewed",
                            value: lastReviewedText,
                            valueColor: lastReviewedColor
                        )

                        signalCard(
                            title: "Correct Reviews",
                            value: "\(streakCount)",
                            valueColor: .primary
                        )
                    }
                }

                Button {
                    reviewStartConfiguration = ReviewStartConfiguration(
                        title: "Review Verse",
                        description: "Choose a review method for \(currentVerse.reference).",
                        verses: [currentVerse]
                    )
                } label: {
                    Text("Start Review")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)

                    VStack(spacing: 0) {
                        detailRow(title: "Folder", value: folderName)
                        detailDivider
                        detailRow(title: "Added", value: addedDateText)
                        detailDivider
                        detailRow(title: "Times Reviewed", value: "\(currentVerse.reviewCount)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Verse")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .onChange(of: verse) { _, newValue in
            currentVerse = newValue
        }
        .sheet(item: $reviewStartConfiguration) { configuration in
            ReviewStartSheet(configuration: configuration) { method in
                onStartReview(currentVerse, method)
            }
        }
    }

    private var masteryPicker: some View {
        Picker("Status", selection: masteryStatusBinding) {
            ForEach(VerseMasteryStatus.allCases) { status in
                Text(status.rawValue).tag(status)
            }
        }
        .pickerStyle(.segmented)
    }

    private var streakCount: Int {
        currentVerse.correctCount
    }

    private var strength: Double {
        VerseStrengthService.currentStrength(for: currentVerse)
    }

    private var folderName: String {
        let trimmedFolderName = currentVerse.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsedWhitespaceFolderName.isEmpty else {
            return Self.uncategorizedFolderName
        }

        return collapsedWhitespaceFolderName.lowercased().localizedCapitalized
    }

    private var lastReviewedText: String {
        guard let lastReviewedAt = currentVerse.lastReviewedAt else {
            return "Not reviewed yet"
        }

        let calendar = Calendar.current

        if calendar.isDateInToday(lastReviewedAt) {
            return "Today"
        }

        if calendar.isDateInYesterday(lastReviewedAt) {
            return "Yesterday"
        }

        let daysAgo = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastReviewedAt),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        return "\(max(daysAgo, 0)) days ago"
    }

    private var lastReviewedColor: Color {
        switch VerseStrengthService.band(for: strength) {
        case .strong:
            return Color(red: 0.24, green: 0.55, blue: 0.41)
        case .steady:
            return Color(red: 0.56, green: 0.78, blue: 0.40)
        case .warning:
            return Color(red: 0.72, green: 0.56, blue: 0.18)
        case .weak:
            return Color(red: 0.68, green: 0.36, blue: 0.34)
        }
    }

    private var addedDateText: String {
        currentVerse.createdAt.formatted(.dateTime.month(.wide).day().year())
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))

                Capsule()
                    .fill(progressTint)
                    .frame(width: geometry.size.width * progressValue)
            }
        }
        .frame(height: 6)
    }

    private var progressTint: Color {
        switch VerseStrengthService.band(for: strength) {
        case .strong:
            return Color(red: 0.24, green: 0.55, blue: 0.41)
        case .steady:
            return Color(red: 0.56, green: 0.78, blue: 0.40)
        case .warning:
            return Color(red: 0.72, green: 0.56, blue: 0.18)
        case .weak:
            return Color(red: 0.68, green: 0.36, blue: 0.34)
        }
    }

    private var progressValue: CGFloat {
        CGFloat(strength)
    }

    private var masteryStatusBinding: Binding<VerseMasteryStatus> {
        Binding(
            get: { currentVerse.masteryStatus },
            set: { newValue in
                updateMasteryStatus(to: newValue)
            }
        )
    }

    private var detailDivider: some View {
        Divider()
    }

    private func signalCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
    }

    private func updateMasteryStatus(to status: VerseMasteryStatus) {
        guard currentVerse.masteryStatus != status else {
            return
        }

        guard let updatedVerse = VerseRepository.shared.updateMasteryStatus(forVerseID: currentVerse.id, to: status) else {
            return
        }

        currentVerse = updatedVerse
        onVerseUpdated(updatedVerse)
    }
}

#Preview {
    NavigationStack {
        VerseDetailView(
            verse: Verse(
                reference: "Romans 8:28",
                text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
                folderName: "Encouragement",
                correctCount: 2,
                reviewCount: 3,
                createdAt: .now.addingTimeInterval(-86400 * 14),
                lastReviewedAt: .now.addingTimeInterval(-86400)
            ),
            onStartReview: { _, _ in }
        )
    }
}
