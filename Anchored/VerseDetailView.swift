import SwiftUI

struct VerseDetailView: View {
    private static let uncategorizedFolderName = "Uncategorized"
    let verse: Verse
    let onStartReview: (ReviewMethod) -> Void

    @State private var isVerseRevealed = false
    @State private var showingReviewMethodPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verse.reference)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    progressBar

                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 12) {
                        signalCard(
                            title: "Last Reviewed",
                            value: lastReviewedText,
                            valueColor: lastReviewedColor
                        )

                        signalCard(
                            title: "Streak",
                            value: "Streak: \(streakCount)",
                            valueColor: .primary
                        )
                    }
                }
                .padding(.top, 20)

                Button {
                    showingReviewMethodPicker = true
                } label: {
                    Text("Start Review")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Try to recall before revealing")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 16) {
                        if isVerseRevealed {
                            Text(verse.text)
                                .font(.system(.title3, design: .serif))
                                .lineSpacing(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Use this space to test your recall before checking the wording.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)

                                Text("Start a review when you want to score yourself, or reveal the verse only when you need a reference.")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isVerseRevealed.toggle()
                            }
                        } label: {
                            Text(isVerseRevealed ? "Hide Verse" : "Reveal Verse")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)

                    VStack(spacing: 0) {
                        detailRow(title: "Folder", value: folderName)
                        detailDivider
                        detailRow(title: "Added", value: addedDateText)
                        detailDivider
                        detailRow(title: "Times Reviewed", value: "\(verse.reviewCount)")
                        detailDivider
                        detailRow(title: "Confidence", value: "\(confidencePercent)%")
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
        .confirmationDialog("Choose Review Method", isPresented: $showingReviewMethodPicker, titleVisibility: .visible) {
            ForEach(ReviewMethod.allCases) { method in
                Button(method.title) {
                    onStartReview(method)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select how you want to review \(verse.reference).")
        }
    }

    private var statusText: String {
        verse.isMastered ? "Memorized" : "Learning"
    }

    private var streakCount: Int {
        verse.correctCount
    }

    private var folderName: String {
        let trimmedFolderName = verse.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
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
        guard let lastReviewedAt = verse.lastReviewedAt else {
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
        guard let lastReviewedAt = verse.lastReviewedAt else {
            return Color(.secondaryLabel)
        }

        let calendar = Calendar.current
        let daysAgo = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastReviewedAt),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        switch daysAgo {
        case ..<3:
            return Color(red: 0.24, green: 0.55, blue: 0.41)
        case 3..<7:
            return Color(red: 0.72, green: 0.56, blue: 0.18)
        default:
            return Color(red: 0.68, green: 0.36, blue: 0.34)
        }
    }

    private var addedDateText: String {
        verse.createdAt.formatted(.dateTime.month(.wide).day().year())
    }

    private var confidencePercent: Int {
        guard verse.reviewCount > 0 else {
            return 0
        }

        let ratio = Double(verse.correctCount) / Double(max(verse.reviewCount, 1))
        return Int((ratio * 100).rounded())
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))

                Capsule()
                    .fill(verse.isMastered ? Color.green.opacity(0.8) : Color.accentColor.opacity(0.85))
                    .frame(width: geometry.size.width * progressValue)
            }
            .overlay(alignment: .topTrailing) {
                Text("\(verse.correctCount) / \(Verse.masteryGoal)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .offset(y: -24)
            }
        }
        .frame(height: 6)
    }

    private var progressValue: CGFloat {
        CGFloat(min(max(verse.progress, 0), 1))
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
            onStartReview: { _ in }
        )
    }
}
