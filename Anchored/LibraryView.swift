import SwiftUI

struct LibraryView: View {
    private struct SingleVerseReviewPresentation: Identifiable {
        let verse: Verse
        let method: ReviewMethod

        var id: String {
            "\(verse.id)-\(method.rawValue)"
        }
    }

    private struct BatchReviewPresentation: Identifiable {
        let id = UUID()
        let descriptor: ReviewSessionDescriptor
        let verses: [Verse]
    }

    private struct MoveVersePresentation: Identifiable {
        let id = UUID()
        let verse: Verse
    }

    private struct LibrarySummaryMetric: View {
        let value: Int
        let title: String
        let isSelected: Bool

        var body: some View {
            VStack(spacing: 5) {
                Text(value.formatted())
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.45)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AppColors.selectionFill : Color.clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? AppColors.gold.opacity(0.42) : Color.clear, lineWidth: 1)
            }
        }
    }

    private struct SummaryDivider: View {
        var body: some View {
            Rectangle()
                .fill(AppColors.divider)
                .frame(width: 1, height: 32)
        }
    }

    enum FilterType: String, CaseIterable {
        case all = "All"
        case practicing = "Practicing"
        case memorized = "Memorized"
    }

    private enum SortMode: String, CaseIterable {
        case newest = "Default"
        case review = "Review"
        case aToZ = "A–Z"
    }

    private static let allFoldersOption = "All Folders"
    private static let uncategorizedFolderName = "Uncategorized"

    @State private var showingFolderFilterSheet = false
    @State private var detailVerse: Verse? = nil
    @State private var selectedVerseReview: SingleVerseReviewPresentation? = nil
    @State private var pendingMoveVerse: MoveVersePresentation? = nil
    @State private var selectedFilter: FilterType = .all
    @State private var selectedFolders: Set<String> = []
    @State private var sortMode: SortMode = .newest
    @State private var searchText = ""
    @State private var isShowingSearchField = false
    @State private var reviewStartConfiguration: ReviewStartConfiguration?
    @State private var activeBatchReview: BatchReviewPresentation?
    @State private var isSelectionMode = false
    @State private var selectedVerseIDs: Set<String> = []
    @State private var pendingBatchDeleteVerseIDs: Set<String> = []
    @State private var scrollOffset: CGFloat = 0
    @State private var verses: [Verse] = []
    @FocusState private var isSearchFieldFocused: Bool

    private let floatingButtonHeight: CGFloat = 50
    private let floatingButtonVerticalInset: CGFloat = 8
    private let summaryFadeDistance: CGFloat = 100

    private var bottomShellClearance: CGFloat {
        BottomNavigationShellLayout.overlayClearance
    }

    private var folderOptions: [String] {
        let folderNames = Set(
            verses.map { verse in
                normalizedFolderName(verse.folderName)
            }
        )

        return folderNames.sorted()
    }

    private var statusFilteredVerses: [Verse] {
        switch selectedFilter {
        case .all:
            return verses
        case .practicing:
            return VerseQueries.practicingVerses(verses)
        case .memorized:
            return VerseQueries.memorizedVerses(verses)
        }
    }

    private var folderFilteredVerses: [Verse] {
        guard !selectedFolders.isEmpty else {
            return statusFilteredVerses
        }

        return statusFilteredVerses.filter { verse in
            selectedFolders.contains(normalizedFolderName(verse.folderName))
        }
    }

    private var searchFilteredVerses: [Verse] {
        guard hasActiveSearch else {
            return folderFilteredVerses
        }

        return folderFilteredVerses.filter(matchesSearch)
    }

    private var filteredVerses: [Verse] {
        switch sortMode {
        case .newest:
            return searchFilteredVerses.sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }

                return lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
            }
        case .review:
            return searchFilteredVerses.sorted(by: reviewSort)
        case .aToZ:
            return searchFilteredVerses.sorted { lhs, rhs in
                let comparison = lhs.reference.localizedCaseInsensitiveCompare(rhs.reference)

                if comparison == .orderedSame {
                    return lhs.createdAt > rhs.createdAt
                }

                return comparison == .orderedAscending
            }
        }
    }

    private var practicingCount: Int {
        VerseQueries.practicingVerses(verses).count
    }

    private var memorizedCount: Int {
        VerseQueries.memorizedVerses(verses).count
    }

    private var totalCount: Int {
        verses.count
    }

    private var reviewVerses: [Verse] {
        filteredVerses.sorted { VerseStrengthService.reviewPriority($0, $1) }
    }

    private var practicingReviewVerses: [Verse] {
        reviewVerses.filter { $0.masteryStatus == .practicing }
    }

    private var floatingButtonClearance: CGFloat {
        floatingButtonHeight + (floatingButtonVerticalInset * 2) + bottomShellClearance + 6
    }

    private var batchActionBarClearance: CGFloat {
        96 + bottomShellClearance
    }

    private var bottomOverlayClearance: CGFloat {
        isSelectionMode ? batchActionBarClearance : floatingButtonClearance
    }

    private var hasActiveFolderFilter: Bool {
        !selectedFolders.isEmpty
    }

    private var hasNonDefaultSortMode: Bool {
        sortMode != .newest
    }

    private var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedVisibleCount: Int {
        selectedVerseIDs.intersection(Set(filteredVerses.map(\.id))).count
    }

    private var hasSelection: Bool {
        selectedVisibleCount > 0
    }

    private var batchDeleteDialogTitle: String {
        "Delete \(selectedVisibleCount) \(selectedVisibleCount == 1 ? "verse" : "verses")?"
    }

    private var folderSelectionSummary: String {
        if selectedFolders.isEmpty {
            return Self.allFoldersOption
        }

        let selected = folderOptions.filter { selectedFolders.contains($0) }

        if selected.count == 1, let firstSelection = selected.first {
            return firstSelection
        }

        return "\(selected.count) folders"
    }

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top

            NavigationStack {
                ZStack(alignment: .top) {
                    AppColors.background
                        .ignoresSafeArea()

                    List {
                        topSummarySection
                            .opacity(summaryOpacity)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        Section {
                            if filteredVerses.isEmpty {
                                emptyVersesState
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            } else {
                                ForEach(Array(filteredVerses.enumerated()), id: \.element.id) { index, verse in
                                    verseListRow(
                                        verse: verse,
                                        index: index,
                                        totalCount: filteredVerses.count
                                    )
                                }
                            }
                        } header: {
                            managementRail
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, -16)
                                .padding(.top, 8)
                                .padding(.bottom, 8)
                        }
                        .textCase(nil)
                        .listSectionSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .listSectionSpacing(.custom(0))
                    .scrollContentBackground(.hidden)
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .contentMargins(.bottom, bottomOverlayClearance, for: .scrollContent)
                    .environment(\.defaultMinListRowHeight, 1)
                    .overlay(alignment: .top) {
                        AppColors.background
                            .frame(height: safeTop)
                            .ignoresSafeArea(edges: .top)
                            .allowsHitTesting(false)
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y + geometry.contentInsets.top
                    } action: { _, newValue in
                        scrollOffset = max(newValue, 0)
                    }
                }
                .overlay(alignment: .bottom) {
                    bottomOverlay
                }
                .navigationBarHidden(true)
                .navigationDestination(isPresented: detailVersePresented) {
                    if let verse = detailVerse {
                        VerseDetailView(
                            verse: verse,
                            onStartReview: { verse, method in
                                selectedVerseReview = SingleVerseReviewPresentation(verse: verse, method: method)
                            },
                            onVerseUpdated: { updatedVerse in
                                detailVerse = updatedVerse
                                reloadVerses()
                            },
                            onVerseDeleted: { deletedVerse in
                                if detailVerse?.id == deletedVerse.id {
                                    detailVerse = nil
                                }
                                reloadVerses()
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingFolderFilterSheet) {
            FolderFilterSheet(
                allFoldersTitle: Self.allFoldersOption,
                folders: folderOptions,
                initialSelection: selectedFolders
            ) { selection in
                selectedFolders = selection
            }
        }
        .sheet(item: $pendingMoveVerse) { presentation in
            FolderDestinationSheet(
                title: "Move to Folder",
                currentFolderName: presentation.verse.folderName,
                additionalFolders: []
            ) { folderName in
                moveVerse(id: presentation.verse.id, toFolder: folderName)
            }
        }
        .sheet(item: $selectedVerseReview) { presentation in
            switch presentation.method {
            case .flashcard:
                ReviewView(verse: presentation.verse) { _ in
                    reloadVerses()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewView(verse: presentation.verse) { _ in
                    reloadVerses()
                }
            case .firstLetterTyping:
                FirstLetterTypingReviewView(verse: presentation.verse) { _ in
                    reloadVerses()
                }
            case .voiceRecitation:
                VoiceRecitationReviewSessionView(
                    descriptor: ReviewSessionDescriptor(title: presentation.method.title, method: presentation.method),
                    verses: [presentation.verse],
                    onUpdate: { _ in
                        reloadVerses()
                    }
                )
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
        .sheet(item: $activeBatchReview) { presentation in
            switch presentation.descriptor.method {
            case .flashcard:
                ReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    reloadVerses()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    reloadVerses()
                }
            case .firstLetterTyping:
                FirstLetterTypingReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    reloadVerses()
                }
            case .voiceRecitation:
                VoiceRecitationReviewSessionView(descriptor: presentation.descriptor, verses: presentation.verses) { _ in
                    reloadVerses()
                }
            }
        }
        .task {
            await loadInitialVersesIfNeeded()
        }
        .onAppear {
            reloadVerses()
        }
        .confirmationDialog(batchDeleteDialogTitle, isPresented: batchDeleteDialogPresented, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteVerses(ids: pendingBatchDeleteVerseIDs)
                pendingBatchDeleteVerseIDs.removeAll()
            }

            Button("Cancel", role: .cancel) {
                pendingBatchDeleteVerseIDs.removeAll()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var summaryOpacity: CGFloat {
        1 - scrollProgress
    }

    private var scrollProgress: CGFloat {
        min(scrollOffset / summaryFadeDistance, 1)
    }

    private var currentControlsSpacing: CGFloat {
        8 - (2 * scrollProgress)
    }

    private var detailVersePresented: Binding<Bool> {
        Binding(
            get: { detailVerse != nil },
            set: { isPresented in
                if !isPresented {
                    detailVerse = nil
                }
            }
        )
    }

    private var batchDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { !pendingBatchDeleteVerseIDs.isEmpty },
            set: { isPresented in
                if !isPresented {
                    pendingBatchDeleteVerseIDs.removeAll()
                }
            }
        )
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        if isSelectionMode {
            batchActionBar
        } else {
            floatingReviewButton()
        }
    }

    private var topSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Library")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Your saved passages, organized and ready to review.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button {
                    isShowingSearchField = true
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Search library")
            }

            HStack(spacing: 0) {
                summaryFilterMetric(value: totalCount, title: "All", filter: .all)
                SummaryDivider()
                summaryFilterMetric(value: practicingCount, title: "Practicing", filter: .practicing)
                SummaryDivider()
                summaryFilterMetric(value: memorizedCount, title: "Memorized", filter: .memorized)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            }
        }
        .padding(.horizontal, 0)
        .padding(.top, 8)
        .padding(.bottom, 0)
    }

    @ViewBuilder
    private var managementRail: some View {
        if isSelectionMode {
            HStack(spacing: 12) {
                Text("\(selectedVisibleCount) Selected")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer(minLength: 12)

                Button("Cancel") {
                    exitSelectionMode()
                }
                .font(.system(size: 16, weight: .semibold))
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                utilityRail

                if isShowingSearchField || hasActiveSearch {
                    librarySearchField
                        .padding(.top, 10)
                }

                if hasActiveFolderFilter {
                    Text("Folders: \(folderSelectionSummary)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 2)
                }
            }
        }
    }

    private var utilityRail: some View {
        HStack(spacing: 8) {
            Button {
                enterSelectionMode()
            } label: {
                Text("Select")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .fixedSize()
            .glassEffect(.regular.interactive(), in: .capsule)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button {
                    showingFolderFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFolderFilter ? "folder.fill" : "folder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(hasActiveFolderFilter ? AppColors.gold : AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(
                    hasActiveFolderFilter
                        ? .regular.tint(AppColors.gold).interactive()
                        : .regular.interactive(),
                    in: .circle
                )
                .accessibilityLabel("Folders")

                Menu {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(hasNonDefaultSortMode ? AppColors.gold : AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(
                    hasNonDefaultSortMode
                        ? .regular.tint(AppColors.gold).interactive()
                        : .regular.interactive(),
                    in: .circle
                )
                .accessibilityLabel("Sort")
            }
        }
    }

    private var librarySearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)

            TextField("Search reference or text", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearchFieldFocused)

            if hasActiveSearch {
                Button {
                    searchText = ""
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            } else {
                Button("Cancel") {
                    isShowingSearchField = false
                    isSearchFieldFocused = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    private func summaryFilterMetric(value: Int, title: String, filter: FilterType) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            LibrarySummaryMetric(
                value: value,
                title: title,
                isSelected: selectedFilter == filter
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyVersesState: some View {
        VStack(spacing: 12) {
            Image(systemName: hasActiveSearch ? "magnifyingglass" : "book.closed")
                .font(.system(size: 34))
                .foregroundStyle(AppColors.textSecondary)

            Text(hasActiveSearch ? "No matches found" : "No verses here yet")
                .font(.headline)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.surface)
        )
        .padding(.horizontal, 0)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func verseListRow(verse: Verse, index: Int, totalCount: Int) -> some View {
        let rowShape = UnevenRoundedRectangle(
            cornerRadii: rowCornerRadii(for: index, totalCount: totalCount),
            style: .continuous
        )

        if isSelectionMode {
            Button {
                toggleSelection(for: verse)
            } label: {
                rowContent(for: verse, index: index, totalCount: totalCount, showsChevron: false)
            }
            .buttonStyle(.plain)
            .containerShape(rowShape)
            .clipShape(rowShape)
            .listRowInsets(EdgeInsets())
            .listRowBackground(
                rowBackground(for: index, totalCount: totalCount)
            )
            .listRowSeparator(.hidden)
        } else {
            Button {
                detailVerse = verse
            } label: {
                rowContent(for: verse, index: index, totalCount: totalCount, showsChevron: true)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    pendingMoveVerse = MoveVersePresentation(verse: verse)
                } label: {
                    Label("Move to Folder", systemImage: "folder")
                }

                Button {
                    toggleMasteryStatus(for: verse)
                } label: {
                    Label(toggleActionMenuTitle(for: verse), systemImage: toggleActionSystemImage(for: verse))
                }

                Button(role: .destructive) {
                    deleteVerse(verse)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    toggleMasteryStatus(for: verse)
                } label: {
                    Image(systemName: toggleActionSystemImage(for: verse))
                }
                .accessibilityLabel(toggleActionTitle(for: verse))
                .tint(toggleActionTint(for: verse))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    pendingMoveVerse = MoveVersePresentation(verse: verse)
                } label: {
                    Image(systemName: "folder")
                }
                .tint(.indigo)

                Button(role: .destructive) {
                    deleteVerse(verse)
                } label: {
                    Image(systemName: "trash")
                }
            }
            .containerShape(rowShape)
            .clipShape(rowShape)
            .listRowInsets(EdgeInsets())
            .listRowBackground(
                rowBackground(for: index, totalCount: totalCount)
            )
            .listRowSeparator(.hidden)
        }
    }

    private func rowContent(for verse: Verse, index: Int, totalCount: Int, showsChevron: Bool) -> some View {
        VerseRowView(
            verse: verse,
            showsChevron: showsChevron,
            selectionState: isSelectionMode ? .init(isSelected: selectedVerseIDs.contains(verse.id)) : nil
        )
        .contentShape(Rectangle())
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if index < totalCount - 1 {
                Divider()
                    .padding(.horizontal, 18)
            }
        }
    }

    private var utilityControlBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(AppColors.surface)
    }

    private func rowBackground(for index: Int, totalCount: Int) -> some View {
        let radii = rowCornerRadii(for: index, totalCount: totalCount)

        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
            .fill(AppColors.surface)
    }

    private func rowCornerRadii(for index: Int, totalCount: Int) -> RectangleCornerRadii {
        let radius: CGFloat = 26
        let isFirstRow = index == 0
        let isLastRow = index == totalCount - 1

        return RectangleCornerRadii(
            topLeading: isFirstRow ? radius : 0,
            bottomLeading: isLastRow ? radius : 0,
            bottomTrailing: isLastRow ? radius : 0,
            topTrailing: isFirstRow ? radius : 0
        )
    }

    @ViewBuilder
    private func floatingReviewButton() -> some View {
        HStack(spacing: 10) {
            reviewButton(
                title: "Review Practicing",
                tint: AppColors.primaryButton,
                textColor: AppColors.primaryButtonText,
                isEnabled: !practicingReviewVerses.isEmpty
            ) {
                startLibraryReview(
                    title: "Review Practicing",
                    description: "Review only the practicing verses currently shown in your library.",
                    verses: practicingReviewVerses
                )
            }

            reviewButton(
                title: "Review All",
                tint: AppColors.gold,
                textColor: AppColors.textPrimary,
                isEnabled: !reviewVerses.isEmpty
            ) {
                startLibraryReview(
                    title: "Review All",
                    description: "Review every verse currently shown in your library.",
                    verses: reviewVerses
                )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, bottomShellClearance - 2)
    }

    private var batchActionBar: some View {
        HStack(spacing: 10) {
            batchActionButton(
                title: "Mark Memorized",
                systemImage: "checkmark.circle.fill",
                tint: AppColors.statusMemorized,
                isEnabled: hasSelection
            ) {
                updateMasteryStatusForSelectedVerses(to: .memorized)
            }

            batchActionButton(
                title: "Mark Practicing",
                systemImage: "flame.fill",
                tint: AppColors.statusPracticing,
                isEnabled: hasSelection
            ) {
                updateMasteryStatusForSelectedVerses(to: .practicing)
            }

            batchActionButton(
                title: "Delete",
                systemImage: "trash",
                tint: AppColors.gold,
                isEnabled: hasSelection
            ) {
                pendingBatchDeleteVerseIDs = selectedVerseIDs.intersection(Set(filteredVerses.map(\.id)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
        .shadow(color: AppColors.background.opacity(0.08), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 8 + bottomShellClearance)
    }

    private func batchActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isEnabled ? tint : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isEnabled ? tint.opacity(0.12) : AppColors.surface.opacity(0.85))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func reviewButton(
        title: String,
        tint: Color,
        textColor: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(isEnabled ? tint : AppColors.surface)
            )
            .overlay {
                Capsule()
                    .stroke(isEnabled ? tint.opacity(0.18) : AppColors.divider, lineWidth: 1)
            }
            .shadow(color: AppColors.background.opacity(isEnabled ? 0.12 : 0), radius: 12, x: 0, y: 6)
        }
        .disabled(!isEnabled)
    }

    private func reloadVerses() {
        verses = VerseRepository.shared.loadVerses()

        if let detailVerse {
            self.detailVerse = verses.first(where: { $0.id == detailVerse.id })
        }

        selectedFolders = selectedFolders.intersection(Set(folderOptions))
        pruneSelectionToVisibleVerses()
    }

    @MainActor
    private func loadInitialVersesIfNeeded() async {
        guard verses.isEmpty else {
            return
        }

        verses = await VerseRepository.shared.loadVersesAsync()
    }

    private func normalizedFolderName(_ folderName: String) -> String {
        let normalizedFolderName = ScriptureAddPipeline.normalizedFolderName(folderName)

        guard !normalizedFolderName.isEmpty else {
            return Self.uncategorizedFolderName
        }

        return normalizedFolderName
    }

    private func startLibraryReview(title: String, description: String, verses: [Verse]) {
        guard !verses.isEmpty else {
            return
        }

        reviewStartConfiguration = ReviewStartConfiguration(
            title: title,
            description: description,
            verses: verses
        )
    }

    private func reviewSort(_ lhs: Verse, _ rhs: Verse) -> Bool {
        VerseStrengthService.reviewPriority(lhs, rhs)
    }

    private var emptyStateMessage: String {
        if hasActiveSearch {
            return "Try a reference or words from the verse text."
        }

        return "Add a verse to start memorizing Scripture."
    }

    private func matchesSearch(_ verse: Verse) -> Bool {
        let normalizedSearchText = normalizedSearchContent(searchText)
        guard !normalizedSearchText.isEmpty else {
            return true
        }

        let reference = normalizedSearchContent(verse.reference)
        if reference.contains(normalizedSearchText) {
            return true
        }

        let searchableText = normalizedSearchContent("\(verse.reference) \(verse.text)")
        let searchTokens = normalizedSearchText.split(separator: " ").map(String.init)

        return searchTokens.allSatisfy { searchableText.contains($0) }
    }

    private func normalizedSearchContent(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func deleteVerse(_ verse: Verse) {
        deleteVerses(ids: Set([verse.id]))
    }

    private func moveVerse(id: String, toFolder folderName: String) {
        guard let updatedVerse = VerseRepository.shared.moveVerse(id: id, toFolder: folderName) else {
            return
        }

        applyUpdatedVerses([updatedVerse])
        reloadVerses()
    }

    private func toggleMasteryStatus(for verse: Verse) {
        let targetStatus: VerseMasteryStatus = verse.masteryStatus == .practicing ? .memorized : .practicing
        updateMasteryStatus(forVerseIDs: Set([verse.id]), to: targetStatus)
    }

    private func toggleActionTitle(for verse: Verse) -> String {
        verse.masteryStatus == .practicing ? "Memorized" : "Practicing"
    }

    private func toggleActionMenuTitle(for verse: Verse) -> String {
        verse.masteryStatus == .practicing ? "Mark Memorized" : "Mark Practicing"
    }

    private func toggleActionSystemImage(for verse: Verse) -> String {
        verse.masteryStatus == .practicing ? "checkmark.circle" : "flame.fill"
    }

    private func toggleActionTint(for verse: Verse) -> Color {
        verse.masteryStatus == .practicing ? AppColors.statusMemorized : AppColors.statusPracticing
    }

    private func enterSelectionMode() {
        isSelectionMode = true
        selectedVerseIDs.removeAll()
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedVerseIDs.removeAll()
        pendingBatchDeleteVerseIDs.removeAll()
    }

    private func toggleSelection(for verse: Verse) {
        if selectedVerseIDs.contains(verse.id) {
            selectedVerseIDs.remove(verse.id)
        } else {
            selectedVerseIDs.insert(verse.id)
        }
    }

    private func updateMasteryStatusForSelectedVerses(to status: VerseMasteryStatus) {
        updateMasteryStatus(forVerseIDs: selectedVerseIDs.intersection(Set(filteredVerses.map(\.id))), to: status)
    }

    private func updateMasteryStatus(forVerseIDs ids: Set<String>, to status: VerseMasteryStatus) {
        guard !ids.isEmpty else {
            return
        }

        let updatedVerses = VerseRepository.shared.updateMasteryStatus(forVerseIDs: ids, to: status)
        applyUpdatedVerses(updatedVerses)
        reloadVerses()
    }

    private func deleteVerses(ids: Set<String>) {
        guard !ids.isEmpty else {
            return
        }

        if let detailVerse, ids.contains(detailVerse.id) {
            self.detailVerse = nil
        }

        if let selectedVerseReview, ids.contains(selectedVerseReview.verse.id) {
            self.selectedVerseReview = nil
        }

        VerseRepository.shared.softDeleteVerses(ids: ids)
        selectedVerseIDs.subtract(ids)
        reloadVerses()
    }

    private func applyUpdatedVerses(_ updatedVerses: [Verse]) {
        guard !updatedVerses.isEmpty else {
            return
        }

        let updatedVersesByID = Dictionary(uniqueKeysWithValues: updatedVerses.map { ($0.id, $0) })

        if let detailVerse, let updatedVerse = updatedVersesByID[detailVerse.id] {
            self.detailVerse = updatedVerse
        }

        if let selectedVerseReview, let updatedVerse = updatedVersesByID[selectedVerseReview.verse.id] {
            self.selectedVerseReview = SingleVerseReviewPresentation(
                verse: updatedVerse,
                method: selectedVerseReview.method
            )
        }
    }

    private func pruneSelectionToVisibleVerses() {
        let visibleVerseIDs = Set(filteredVerses.map(\.id))
        selectedVerseIDs = selectedVerseIDs.intersection(visibleVerseIDs)
        pendingBatchDeleteVerseIDs = pendingBatchDeleteVerseIDs.intersection(visibleVerseIDs)
    }
}

private struct FolderFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let allFoldersTitle: String
    let folders: [String]
    let initialSelection: Set<String>
    let onApply: (Set<String>) -> Void

    @State private var draftSelection: Set<String>

    init(
        allFoldersTitle: String,
        folders: [String],
        initialSelection: Set<String>,
        onApply: @escaping (Set<String>) -> Void
    ) {
        self.allFoldersTitle = allFoldersTitle
        self.folders = folders
        self.initialSelection = initialSelection
        self.onApply = onApply
        _draftSelection = State(initialValue: initialSelection)
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    draftSelection.removeAll()
                } label: {
                    folderRow(title: allFoldersTitle, isSelected: draftSelection.isEmpty)
                }
                .buttonStyle(.plain)

                ForEach(folders, id: \.self) { folder in
                    Button {
                        toggle(folder)
                    } label: {
                        folderRow(title: folder, isSelected: draftSelection.contains(folder))
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        draftSelection.removeAll()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(draftSelection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func folderRow(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(isSelected ? AppColors.gold : AppColors.textSecondary)

            Text(title)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func toggle(_ folder: String) {
        if draftSelection.contains(folder) {
            draftSelection.remove(folder)
        } else {
            draftSelection.insert(folder)
        }
    }
}

#Preview {
    LibraryView()
}
