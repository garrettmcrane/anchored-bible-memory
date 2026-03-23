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

    enum FilterType: String, CaseIterable {
        case all = "All"
        case practicing = "Practicing"
        case memorized = "Memorized"
    }

    fileprivate enum SortMode: String, CaseIterable {
        case newest = "Default"
        case lastReviewedEarliestToLatest = "Last Reviewed (Earliest - Latest)"
        case lastReviewedLatestToEarliest = "Last Reviewed (Latest - Earliest)"
        case dateAddedEarliestToLatest = "Date Added (Earliest - Latest)"
        case dateAddedLatestToEarliest = "Date Added (Latest - Earliest)"
        case aToZ = "Alphabetical (A-Z)"
        case zToA = "Alphabetical (Z-A)"
        case canonicalOrder = "Canonical Order"
    }

    private static let allFoldersOption = "All Folders"
    private static let uncategorizedFolderName = "Uncategorized"

    @State private var showingFolderFilterSheet = false
    @State private var showingSortSheet = false
    @State private var detailVerse: Verse? = nil
    @State private var selectedVerseReview: SingleVerseReviewPresentation? = nil
    @State private var pendingMoveVerse: MoveVersePresentation? = nil
    @State private var selectedFilter: FilterType = .all
    @State private var selectedFolders: Set<String> = []
    @State private var sortMode: SortMode = .newest
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var reviewStartConfiguration: ReviewStartConfiguration?
    @State private var activeBatchReview: BatchReviewPresentation?
    @State private var isSelectionMode = false
    @State private var selectedVerseIDs: Set<String> = []
    @State private var pendingBatchDeleteVerseIDs: Set<String> = []
    @State private var isShowingBatchActionsSheet = false
    @State private var isShowingBatchFolderSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var verses: [Verse] = []
    @FocusState private var isSearchFieldFocused: Bool

    @State private var isShowingAddFlow = false
    @State private var addFocusTrigger = 0
    @Namespace private var searchTransitionNamespace

    private let floatingButtonHeight: CGFloat = 50
    private let summaryFadeDistance: CGFloat = 100

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

    private var baseFolderFilteredVerses: [Verse] {
        guard !selectedFolders.isEmpty else {
            return verses
        }

        return verses.filter { verse in
            selectedFolders.contains(normalizedFolderName(verse.folderName))
        }
    }

    private var baseSearchFilteredVerses: [Verse] {
        guard hasActiveSearch else {
            return baseFolderFilteredVerses
        }

        return baseFolderFilteredVerses.filter(matchesSearch)
    }

    private var folderFilteredVerses: [Verse] {
        switch selectedFilter {
        case .all:
            return baseFolderFilteredVerses
        case .practicing:
            return VerseQueries.practicingVerses(baseFolderFilteredVerses)
        case .memorized:
            return VerseQueries.memorizedVerses(baseFolderFilteredVerses)
        }
    }

    private var searchFilteredVerses: [Verse] {
        guard hasActiveSearch else {
            return folderFilteredVerses
        }

        return folderFilteredVerses.filter(matchesSearch)
    }

    private var filteredVerses: [Verse] {
        searchFilteredVerses.sorted(by: sortComparator(for: sortMode))
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
        let practicingPool = baseSearchFilteredVerses
            .filter { $0.masteryStatus == .practicing }

        return practicingPool.sorted { VerseStrengthService.reviewPriority($0, $1) }
    }

    private var floatingButtonClearance: CGFloat {
        floatingButtonHeight + 8
    }

    private var batchActionBarClearance: CGFloat {
        56
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

    private var selectedVerses: [Verse] {
        filteredVerses.filter { selectedVerseIDs.contains($0.id) }
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
            .toolbar {}
            .sheet(isPresented: $showingFolderFilterSheet) {
                FolderFilterSheet(
                    allFoldersTitle: Self.allFoldersOption,
                    folders: folderOptions,
                    initialSelection: selectedFolders
                ) { selection in
                    selectedFolders = selection
                }
            }
            .sheet(isPresented: $showingSortSheet) {
                SortModeSheet(initialSelection: sortMode) { selection in
                    sortMode = selection
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
            .sheet(isPresented: $isShowingBatchFolderSheet) {
                FolderDestinationSheet(
                    title: "Move Selected Verses",
                    currentFolderName: "",
                    additionalFolders: selectedVerses.compactMap(\.folderName)
                ) { folderName in
                    moveSelectedVerses(toFolder: folderName)
                }
            }
            .sheet(isPresented: $isShowingBatchActionsSheet) {
                BatchVerseActionsSheet(
                    selectionCount: selectedVisibleCount,
                    canApplyActions: hasSelection,
                    onChooseFolder: {
                        isShowingBatchActionsSheet = false
                        isShowingBatchFolderSheet = true
                    },
                    onMarkMemorized: {
                        isShowingBatchActionsSheet = false
                        updateMasteryStatusForSelectedVerses(to: .memorized)
                    },
                    onMarkPracticing: {
                        isShowingBatchActionsSheet = false
                        updateMasteryStatusForSelectedVerses(to: .practicing)
                    },
                    onDelete: {
                        isShowingBatchActionsSheet = false
                        pendingBatchDeleteVerseIDs = selectedVerseIDs.intersection(Set(filteredVerses.map(\.id)))
                    }
                )
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
            .sheet(isPresented: $isShowingAddFlow) {
                AddHubView(showsCancelButton: true, focusTrigger: addFocusTrigger) { newVerse in
                    VerseRepository.shared.addVerse(newVerse)
                    reloadVerses()
                }
            }
            .task {
                await loadInitialVersesIfNeeded()
            }
            .onAppear {
                reloadVerses()
            }
            .onReceive(VerseStore.changePublisher) { _ in
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
        LibraryBottomOverlayView(
            isSelectionMode: isSelectionMode,
            selectedVisibleCount: selectedVisibleCount,
            hasSelection: hasSelection,
            practicingReviewEnabled: !practicingReviewVerses.isEmpty || selectedFilter == .memorized,
            reviewAllEnabled: !reviewVerses.isEmpty,
            onStartPracticingReview: {
                startLibraryReview(
                    title: "Review Practicing",
                    description: "Review only the practicing verses currently shown in your library.",
                    verses: practicingReviewVerses
                )
            },
            onStartReviewAll: {
                startLibraryReview(
                    title: "Review All",
                    description: "Review every verse currently shown in your library.",
                    verses: reviewVerses
                )
            },
            onDoneSelection: exitSelectionMode,
            onEditSelection: { isShowingBatchActionsSheet = true }
        )
    }

    private var topSummarySection: some View {
        LibraryHeaderSectionView(
            isSearchPresented: $isSearchPresented,
            searchText: $searchText,
            selectedFilter: $selectedFilter,
            totalCount: totalCount,
            practicingCount: practicingCount,
            memorizedCount: memorizedCount,
            hasActiveSearch: hasActiveSearch,
            searchTransitionNamespace: searchTransitionNamespace,
            isSearchFieldFocused: $isSearchFieldFocused
        )
    }

    @ViewBuilder
    private var managementRail: some View {
        LibraryManagementRailView(
            isSelectionMode: isSelectionMode,
            selectedVisibleCount: selectedVisibleCount,
            hasActiveFolderFilter: hasActiveFolderFilter,
            folderSelectionSummary: folderSelectionSummary,
            hasNonDefaultSortMode: hasNonDefaultSortMode,
            onCancelSelection: exitSelectionMode,
            onShowFolderFilter: { showingFolderFilterSheet = true },
            onShowSort: { showingSortSheet = true },
            onEnterSelectionMode: enterSelectionMode
        )
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
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteVerse(verse)
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
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
        .padding(.vertical, 5)
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

    private var isSearchActive: Bool {
        isSearchPresented || hasActiveSearch
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

    private func sortComparator(for mode: SortMode) -> (Verse, Verse) -> Bool {
        switch mode {
        case .newest, .dateAddedLatestToEarliest:
            return { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }

                return referenceComparison(lhs, rhs) == .orderedAscending
            }
        case .dateAddedEarliestToLatest:
            return { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }

                return referenceComparison(lhs, rhs) == .orderedAscending
            }
        case .lastReviewedEarliestToLatest:
            return { lhs, rhs in
                switch (lhs.lastReviewedAt, rhs.lastReviewedAt) {
                case (nil, nil):
                    break
                case (nil, _?):
                    return true
                case (_?, nil):
                    return false
                case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                    return lhsDate < rhsDate
                default:
                    break
                }

                return sortComparator(for: .dateAddedEarliestToLatest)(lhs, rhs)
            }
        case .lastReviewedLatestToEarliest:
            return { lhs, rhs in
                switch (lhs.lastReviewedAt, rhs.lastReviewedAt) {
                case (nil, nil):
                    break
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                    return lhsDate > rhsDate
                default:
                    break
                }

                return sortComparator(for: .newest)(lhs, rhs)
            }
        case .aToZ:
            return { lhs, rhs in
                let comparison = referenceComparison(lhs, rhs)

                if comparison == .orderedSame {
                    return lhs.createdAt > rhs.createdAt
                }

                return comparison == .orderedAscending
            }
        case .zToA:
            return { lhs, rhs in
                let comparison = referenceComparison(lhs, rhs)

                if comparison == .orderedSame {
                    return lhs.createdAt > rhs.createdAt
                }

                return comparison == .orderedDescending
            }
        case .canonicalOrder:
            return canonicalSort
        }
    }

    private func referenceComparison(_ lhs: Verse, _ rhs: Verse) -> ComparisonResult {
        lhs.reference.localizedCaseInsensitiveCompare(rhs.reference)
    }

    private func canonicalSort(_ lhs: Verse, _ rhs: Verse) -> Bool {
        let lhsReference = canonicalReferenceComponents(for: lhs)
        let rhsReference = canonicalReferenceComponents(for: rhs)

        switch (lhsReference, rhsReference) {
        case let (lhsReference?, rhsReference?):
            if lhsReference.bookOrder != rhsReference.bookOrder {
                return lhsReference.bookOrder < rhsReference.bookOrder
            }

            if lhsReference.chapter != rhsReference.chapter {
                return lhsReference.chapter < rhsReference.chapter
            }

            if lhsReference.verse != rhsReference.verse {
                return lhsReference.verse < rhsReference.verse
            }

            if lhsReference.endChapter != rhsReference.endChapter {
                return lhsReference.endChapter < rhsReference.endChapter
            }

            if lhsReference.endVerse != rhsReference.endVerse {
                return lhsReference.endVerse < rhsReference.endVerse
            }
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            break
        }

        return sortComparator(for: .aToZ)(lhs, rhs)
    }

    private func canonicalReferenceComponents(for verse: Verse) -> (
        bookOrder: Int,
        chapter: Int,
        verse: Int,
        endChapter: Int,
        endVerse: Int
    )? {
        guard let reference = try? ReferenceParser.parseSingle(verse.reference) else {
            return nil
        }

        return (
            bookOrder: reference.book.sortOrder,
            chapter: reference.startChapter,
            verse: reference.startVerse ?? 0,
            endChapter: reference.endChapter ?? reference.startChapter,
            endVerse: reference.endVerse ?? reference.startVerse ?? 0
        )
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

        let searchTokens = normalizedSearchText.split(separator: " ").map(String.init)
        let reference = normalizedSearchContent(verse.reference)
        if reference.contains(normalizedSearchText) {
            return true
        }

        if searchTokens.allSatisfy({ reference.contains($0) }) {
            return true
        }

        let searchableText = normalizedSearchContent("\(verse.reference) \(verse.text)")
        return searchTokens.allSatisfy { searchableText.contains($0) }
    }

    private func normalizedSearchContent(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-zA-Z0-9]+", with: " ", options: .regularExpression)
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

    private func moveSelectedVerses(toFolder folderName: String) {
        let ids = selectedVerseIDs.intersection(Set(filteredVerses.map(\.id)))
        guard !ids.isEmpty else {
            return
        }

        let updatedVerses = ids.compactMap { verseID in
            VerseRepository.shared.moveVerse(id: verseID, toFolder: folderName)
        }

        applyUpdatedVerses(updatedVerses)
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

private struct SortModeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialSelection: LibraryView.SortMode
    let onSelect: (LibraryView.SortMode) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(LibraryView.SortMode.allCases, id: \.self) { mode in
                    Button {
                        onSelect(mode)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(mode.rawValue)
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()

                            if mode == initialSelection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.structuralAccent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Sort")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

private struct BatchVerseActionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let selectionCount: Int
    let canApplyActions: Bool
    let onChooseFolder: () -> Void
    let onMarkMemorized: () -> Void
    let onMarkPracticing: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    actionRow(
                        title: "Move to Folder",
                        systemImage: "folder",
                        tint: AppColors.structuralAccent
                    ) {
                        dismiss()
                        onChooseFolder()
                    }
                }

                Section("Mastery") {
                    actionRow(
                        title: "Mark Memorized",
                        systemImage: "checkmark.circle.fill",
                        tint: AppColors.statusMemorized
                    ) {
                        dismiss()
                        onMarkMemorized()
                    }

                    actionRow(
                        title: "Mark Practicing",
                        systemImage: "flame.fill",
                        tint: AppColors.statusPracticing
                    ) {
                        dismiss()
                        onMarkPracticing()
                    }
                }

                Section {
                    actionRow(
                        title: "Delete Verses",
                        systemImage: "trash",
                        tint: .red,
                        role: .destructive
                    ) {
                        dismiss()
                        onDelete()
                    }
                }
            }
            .navigationTitle("\(selectionCount) Selected")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(false)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func actionRow(
        title: String,
        systemImage: String,
        tint: Color,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(canApplyActions ? tint : AppColors.textSecondary)
        }
        .disabled(!canApplyActions)
    }
}

#Preview {
    LibraryView()
}
