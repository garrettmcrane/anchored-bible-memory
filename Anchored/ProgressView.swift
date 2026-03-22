import SwiftUI

struct ProgressTabView: View {
    @State private var verses: [Verse] = []
    @State private var reviewRecords: [ReviewRecord] = []

    private let calendar = Calendar.current

    private var memorizedCount: Int {
        verses.filter(\.isMastered).count
    }

    private var practicingCount: Int {
        verses.filter { !$0.isMastered }.count
    }

    private var timesReviewedCount: Int {
        verses.reduce(into: 0) { partialResult, verse in
            partialResult += verse.reviewCount
        }
    }

    private var practicingVerses: [Verse] {
        verses
            .filter { $0.masteryStatus == .practicing }
            .sorted { VerseStrengthService.reviewPriority($0, $1) }
    }

    private var folderBreakdown: [FolderBreakdownItem] {
        Dictionary(grouping: verses, by: { normalizedFolderName($0.folderName) })
            .map { folderName, groupedVerses in
                FolderBreakdownItem(name: folderName, count: groupedVerses.count)
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private var recentActivity: [ReviewActivityDay] {
        let filteredRecords = reviewRecords.filter { $0.userID == LocalSession.currentUserID }
        let today = calendar.startOfDay(for: Date())

        return (0..<7).compactMap { index in
            guard let day = calendar.date(byAdding: .day, value: -(6 - index), to: today) else {
                return nil
            }

            let count = filteredRecords.reduce(into: 0) { partialResult, record in
                if calendar.isDate(record.reviewedAt, inSameDayAs: day) {
                    partialResult += 1
                }
            }

            return ReviewActivityDay(date: day, count: count)
        }
    }

    private var hasActivityHistory: Bool {
        reviewRecords.contains { $0.userID == LocalSession.currentUserID }
    }

    private var weeklyReviewCount: Int {
        recentActivity.reduce(into: 0) { partialResult, day in
            partialResult += day.count
        }
    }

    private var insightText: String? {
        if practicingCount > memorizedCount, !verses.isEmpty {
            return "You currently have more practicing verses than memorized verses."
        }

        if weeklyReviewCount > 0 {
            return "You reviewed \(weeklyReviewCount) \(weeklyReviewCount == 1 ? "time" : "times") this week."
        }

        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        summarySection
                        activitySection
                        folderBreakdownSection
                        practicingSection

                        if let insightText {
                            insightCard(text: insightText)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadInitialDataIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Progress")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("A simple view of your memorization activity")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Overview")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ProgressMetricCard(title: "Memorized", value: memorizedCount)
                ProgressMetricCard(title: "Practicing", value: practicingCount)
                ProgressMetricCard(title: "Times Reviewed", value: timesReviewedCount)
                ProgressMetricCard(title: "All Verses", value: verses.count)
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Recent Activity", subtitle: "Reviews from the last 7 days")

            if hasActivityHistory {
                ReviewActivityCard(days: recentActivity)
            } else {
                ProgressEmptyStateCard(message: "Activity charts will become more detailed as more review history builds up.")
            }
        }
    }

    private var folderBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Folder Breakdown")

            if folderBreakdown.isEmpty {
                ProgressEmptyStateCard(message: "Your verse folders will appear here as you build your library.")
            } else {
                VStack(spacing: 12) {
                    ForEach(folderBreakdown) { item in
                        FolderBreakdownRow(
                            item: item,
                            totalCount: max(verses.count, 1)
                        )
                    }
                }
                .padding(18)
                .background(cardBackground)
            }
        }
    }

    private var practicingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Practicing")

            if practicingVerses.isEmpty {
                ProgressEmptyStateCard(message: "Everything is currently marked Memorized.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(practicingVerses.prefix(5)).indices, id: \.self) { index in
                        let verse = practicingVerses[index]

                        NeedsAttentionRow(verse: verse)

                        if index < min(practicingVerses.count, 5) - 1 {
                            Divider()
                                .padding(.horizontal, 18)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(cardBackground)
            }
        }
    }

    private func insightCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insight")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    AppColors.secondarySurface
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
    }

    private func sectionHeader(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func reloadData() {
        verses = VerseRepository.shared.loadVerses()
        reviewRecords = ReviewRecordStore.load()
    }

    @MainActor
    private func loadInitialDataIfNeeded() async {
        guard verses.isEmpty, reviewRecords.isEmpty else {
            return
        }

        async let loadedVerses = VerseRepository.shared.loadVersesAsync()
        async let loadedReviewRecords = ReviewRecordStore.loadAsync()
        verses = await loadedVerses
        reviewRecords = await loadedReviewRecords
    }

    private func normalizedFolderName(_ folderName: String) -> String {
        let trimmedFolderName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFolderName.isEmpty else {
            return "Uncategorized"
        }

        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsedWhitespaceFolderName.lowercased().localizedCapitalized
    }
}

private struct ProgressMetricCard: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            Text(value.formatted())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
        )
    }
}

private struct ReviewActivityCard: View {
    let days: [ReviewActivityDay]

    private var maxCount: Int {
        max(days.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(days.reduce(0) { $0 + $1.count }.formatted())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("reviews this week")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(days) { day in
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            VStack {
                                Spacer(minLength: 0)

                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColors.gold.opacity(day.count == 0 ? 0.18 : 0.55),
                                                AppColors.gold.opacity(day.count == 0 ? 0.08 : 0.24)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        height: max(
                                            geometry.size.height * CGFloat(day.count) / CGFloat(maxCount),
                                            day.count == 0 ? 10 : 20
                                        )
                                    )
                            }
                        }
                        .frame(height: 132)

                        Text(dayLabel(for: day.date))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColors.textSecondary)

                        Text(day.count.formatted())
                            .font(.caption2)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func dayLabel(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.narrow))
    }
}

private struct FolderBreakdownRow: View {
    let item: FolderBreakdownItem
    let totalCount: Int

    private var ratio: Double {
        Double(item.count) / Double(max(totalCount, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(item.count.formatted())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.surface)

                    Capsule()
                        .fill(AppColors.gold.opacity(0.65))
                        .frame(width: max(geometry.size.width * ratio, ratio == 0 ? 0 : 10))
                }
            }
            .frame(height: 10)
        }
    }
}

private struct NeedsAttentionRow: View {
    let verse: Verse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(verse.reference)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer(minLength: 12)

                Text(lastReviewedText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack(spacing: 8) {
                Text(folderName)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text("\(verse.reviewCount) \(verse.reviewCount == 1 ? "review" : "reviews")")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var folderName: String {
        let trimmedFolderName = verse.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedFolderName.isEmpty ? "Uncategorized" : trimmedFolderName
    }

    private var lastReviewedText: String {
        guard let lastReviewedAt = verse.lastReviewedAt else {
            return "Not reviewed yet"
        }

        return "Last reviewed \(lastReviewedAt.formatted(.relative(presentation: .named)))"
    }
}

private struct ProgressEmptyStateCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.surface)
            )
    }
}

private struct ReviewActivityDay: Identifiable {
    let date: Date
    let count: Int

    var id: Date {
        date
    }
}

private struct FolderBreakdownItem: Identifiable {
    let name: String
    let count: Int

    var id: String {
        name
    }
}

#Preview {
    ProgressTabView()
}
