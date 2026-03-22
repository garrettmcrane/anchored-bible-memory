import SwiftUI

struct ProgressTabView: View {
    @State private var isShowingNotifications = false
    @State private var isShowingSettings = false
    @State private var isShowingAddFlow = false
    @State private var addFocusTrigger = 0
    @State private var verses: [Verse] = []
    @State private var reviewRecords: [ReviewRecord] = []

    private let calendar = Calendar.current

    private var displayName: String {
        let trimmedName = LocalSession.currentUserDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Friend" : trimmedName
    }

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

    private var leadingInsightTitle: String {
        if weeklyReviewCount > 0 {
            return "Your rhythm is building"
        }

        if verses.isEmpty {
            return "Your library starts here"
        }

        if memorizedCount > 0 {
            return "You already have traction"
        }

        return "A steady cadence wins"
    }

    private var leadingInsightMessage: String {
        if verses.isEmpty {
            return "Add a few verses and this space will begin reflecting your memory habits, recent reviews, and where to focus next."
        }

        if let nextVerse = practicingVerses.first {
            return "Your next best review is \(nextVerse.reference). Keep your active verses warm and your memorized ones durable."
        }

        if weeklyReviewCount > 0 {
            return "You reviewed \(weeklyReviewCount) \(weeklyReviewCount == 1 ? "time" : "times") this week. A little consistency here compounds quickly."
        }

        return "Your library is in a strong place. Revisit a favorite verse to keep momentum from going flat."
    }

    private var strongestFolderName: String? {
        folderBreakdown.first?.name
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        profileHeroSection
                        momentumSection
                        activitySection
                        librarySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, BottomNavigationShellLayout.overlayClearance + 22)
                }
            }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
        .task {
            await loadInitialDataIfNeeded()
        }
        .sheet(isPresented: $isShowingNotifications) {
            NotificationsPlaceholderView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .versesDidChange)) { _ in
            reloadData()
        }
        .sheet(isPresented: $isShowingAddFlow) {
            AddHubView(showsCancelButton: true, focusTrigger: addFocusTrigger) { newVerse in
                VerseRepository.shared.addVerse(newVerse)
                Task { await loadInitialDataIfNeeded() }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addFocusTrigger += 1
                    isShowingAddFlow = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add")
            }
        }
    }

    private var header: some View {
        MainScreenTopBar(
            title: "Me",
            onNotificationsTap: {
                isShowingNotifications = true
            },
            onSettingsTap: {
                isShowingSettings = true
            }
        )
    }

    private var profileHeroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(displayName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                Text(leadingInsightTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.scriptureAccent)

                Text(leadingInsightMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                ProfileHighlightPill(title: "Memorized", value: memorizedCount.formatted())
                ProfileHighlightPill(title: "Practicing", value: practicingCount.formatted())
                ProfileHighlightPill(title: "Library", value: verses.count.formatted())
            }

            HStack(spacing: 10) {
                profileDetail(label: "This week", value: "\(weeklyReviewCount) reviews")

                if let strongestFolderName {
                    profileDetail(label: "Top folder", value: strongestFolderName)
                } else {
                    profileDetail(label: "Top folder", value: "None yet")
                }
            }
        }
        .padding(20)
        .background(heroBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Momentum", subtitle: "Your recent pace and lifetime repetition")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                MomentumCard(
                    title: "This Week",
                    value: weeklyReviewCount.formatted(),
                    detail: weeklyReviewCount == 1 ? "review completed" : "reviews completed",
                    accent: AppColors.scriptureAccent
                )

                MomentumCard(
                    title: "Lifetime Reviews",
                    value: timesReviewedCount.formatted(),
                    detail: verses.isEmpty ? "build your library" : "across your verses",
                    accent: AppColors.structuralAccent
                )
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

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Library Snapshot", subtitle: "How your verses are distributed right now")

            if folderBreakdown.isEmpty {
                ProgressEmptyStateCard(message: "Your verse folders will appear here as you build your library.")
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        LibrarySnapshotCard(title: "Folders", value: folderBreakdown.count.formatted())
                        LibrarySnapshotCard(title: "Largest Folder", value: strongestFolderName ?? "None")
                    }

                    VStack(spacing: 12) {
                        ForEach(folderBreakdown) { item in
                            FolderBreakdownRow(
                                item: item,
                                totalCount: max(verses.count, 1)
                            )
                        }
                    }
                }
                .padding(18)
                .background(cardBackground)
            }
        }
    }

    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.elevatedSurface,
                        AppColors.secondarySurface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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

    private func profileDetail(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.7))
        )
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

private struct ProfileHighlightPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.82))
        )
    }
}

private struct MomentumCard: View {
    let title: String
    let value: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Capsule(style: .continuous)
                .fill(accent.opacity(0.28))
                .frame(width: 34, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }
}

private struct LibrarySnapshotCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.secondarySurface)
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
