import SwiftUI

struct LibraryView: View {
    private struct SingleVerseReviewPresentation: Identifiable {
        let verse: Verse
        let method: ReviewMethod

        var id: String {
            "\(verse.id)-\(method.rawValue)"
        }
    }

    enum FilterType: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case memorized = "Memorized"
    }

    private enum SortMode: String, CaseIterable {
        case newest = "Newest"
        case review = "Review"
        case aToZ = "A–Z"
    }

    private static let allFoldersOption = "All Folders"

    @State private var showingAddVerse = false
    @State private var showingFolderFilterSheet = false
    @State private var detailVerse: Verse? = nil
    @State private var selectedVerseReview: SingleVerseReviewPresentation? = nil
    @State private var selectedFilter: FilterType = .all
    @State private var selectedFolders: Set<String> = []
    @State private var sortMode: SortMode = .newest
    @State private var selectedBatchReviewMethod: ReviewMethod? = nil
    @State private var showingBatchReviewMethodPicker = false
    @State private var swipedVerseID: String? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var verses: [Verse] = VerseRepository.shared.loadVerses()

    private let expandedReviewButtonHeight: CGFloat = 66
    private let collapsedReviewButtonHeight: CGFloat = 34
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
        case .learning:
            return VerseQueries.learningVerses(verses)
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

    private var filteredVerses: [Verse] {
        switch sortMode {
        case .newest:
            return folderFilteredVerses.sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }

                return lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
            }
        case .review:
            return folderFilteredVerses.sorted(by: reviewSort)
        case .aToZ:
            return folderFilteredVerses.sorted { lhs, rhs in
                let comparison = lhs.reference.localizedCaseInsensitiveCompare(rhs.reference)

                if comparison == .orderedSame {
                    return lhs.createdAt > rhs.createdAt
                }

                return comparison == .orderedAscending
            }
        }
    }

    private var learningCount: Int {
        VerseQueries.learningVerses(verses).count
    }

    private var memorizedCount: Int {
        VerseQueries.memorizedVerses(verses).count
    }

    private var totalCount: Int {
        verses.count
    }

    private var learningVerses: [Verse] {
        VerseQueries.learningVerses(verses)
    }

    private var hasActiveFolderFilter: Bool {
        !selectedFolders.isEmpty
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

    private var reviewButtonBottomInset: CGFloat {
        88
    }

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom

            NavigationStack {
                ZStack(alignment: .top) {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            topSummarySection
                                .opacity(summaryOpacity)

                            Section {
                                versesSection
                            } header: {
                                controlsSection(
                                    buttonHeight: currentReviewButtonHeight,
                                    spacing: currentControlsSpacing
                                )
                                .background(
                                    Color(.systemGroupedBackground)
                                        .ignoresSafeArea(edges: .top)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            }
                        }
                        .padding(.bottom, reviewButtonBottomInset + safeBottom)
                    }
                    .overlay(alignment: .top) {
                        Color(.systemGroupedBackground)
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
                    floatingReviewButton(safeBottom: safeBottom)
                }
                .navigationBarHidden(true)
                .navigationDestination(isPresented: detailVersePresented) {
                    if let verse = detailVerse {
                        VerseDetailView(
                            verse: verse,
                            onStartReview: { method in
                                selectedVerseReview = SingleVerseReviewPresentation(verse: verse, method: method)
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddVerse) {
            AddVerseView { newVerse in
                VerseRepository.shared.addVerse(newVerse)
                reloadVerses()
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
            }
        }
        .sheet(item: $selectedBatchReviewMethod) { method in
            switch method {
            case .flashcard:
                ReviewSessionView(verses: learningVerses) { _ in
                    reloadVerses()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewSessionView(verses: learningVerses) { _ in
                    reloadVerses()
                }
            }
        }
        .onAppear {
            reloadVerses()
        }
        .confirmationDialog("Choose Review Method", isPresented: $showingBatchReviewMethodPicker, titleVisibility: .visible) {
            ForEach(ReviewMethod.allCases) { method in
                Button(method.title) {
                    selectedBatchReviewMethod = method
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select one method for this review session.")
        }
    }

    private var summaryOpacity: CGFloat {
        1 - scrollProgress
    }

    private var scrollProgress: CGFloat {
        min(scrollOffset / summaryFadeDistance, 1)
    }

    private var currentReviewButtonHeight: CGFloat {
        expandedReviewButtonHeight - ((expandedReviewButtonHeight - collapsedReviewButtonHeight) * scrollProgress)
    }

    private var currentControlsSpacing: CGFloat {
        12 - (4 * scrollProgress)
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

    private var topSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Library")
                        .font(.system(size: 34, weight: .bold))

                    Text("Manage your personal verses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAddVerse = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Text("Total \(totalCount)")
                    .foregroundStyle(.primary)

                Text("•")

                Text("Learning \(learningCount)")

                Text("•")

                Text("Memorized \(memorizedCount)")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func controlsSection(
        buttonHeight: CGFloat,
        spacing: CGFloat
    ) -> some View {
        VStack(spacing: spacing) {
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Menu {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sort")

                Button {
                    showingFolderFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFolderFilter ? "folder.badge.gearshape.fill" : "folder.badge.gearshape")
                        .font(.title3)
                        .foregroundStyle(hasActiveFolderFilter ? .blue : .primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Folders")
            }

            if hasActiveFolderFilter {
                Text("Filtered: \(folderSelectionSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var versesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Verses")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if filteredVerses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)

                    Text("No verses here yet")
                        .font(.headline)

                    Text("Add a verse to start memorizing Scripture.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground))
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredVerses) { verse in
                        SwipeToDeleteVerseRow(
                            id: verse.id,
                            openRowID: $swipedVerseID,
                            onDelete: {
                                deleteVerse(verse)
                            },
                            onTap: {
                                detailVerse = verse
                            },
                            label: {
                                VerseRowView(verse: verse)
                                    .contentShape(Rectangle())
                            }
                        )

                        if verse.id != filteredVerses.last?.id {
                            Divider()
                                .padding(.horizontal, 18)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color(.systemBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func floatingReviewButton(safeBottom: CGFloat) -> some View {
        Button {
            showingBatchReviewMethodPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                Text("Review Verses")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .disabled(learningVerses.isEmpty)
        .opacity(learningVerses.isEmpty ? 0.55 : 1)
    }

    private func reloadVerses() {
        verses = VerseRepository.shared.loadVerses()

        if let detailVerse {
            self.detailVerse = verses.first(where: { $0.id == detailVerse.id })
        }

        selectedFolders = selectedFolders.intersection(Set(folderOptions))

        if let swipedVerseID, !verses.contains(where: { $0.id == swipedVerseID }) {
            self.swipedVerseID = nil
        }
    }

    private func normalizedFolderName(_ folderName: String) -> String {
        let trimmedFolderName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFolderName.isEmpty else {
            return "General"
        }

        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsedWhitespaceFolderName.lowercased().localizedCapitalized
    }

    private func reviewSort(_ lhs: Verse, _ rhs: Verse) -> Bool {
        let lhsPriority = urgencyPriority(for: lhs.urgencyLevel)
        let rhsPriority = urgencyPriority(for: rhs.urgencyLevel)

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }

        switch (lhs.lastReviewedAt, rhs.lastReviewedAt) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return lhsDate < rhsDate
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            break
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
    }

    private func urgencyPriority(for urgencyLevel: UrgencyLevel) -> Int {
        switch urgencyLevel {
        case .needsReview:
            return 0
        case .atRisk:
            return 1
        case .fresh:
            return 2
        }
    }

    private func deleteVerse(_ verse: Verse) {
        if detailVerse?.id == verse.id {
            detailVerse = nil
        }

        if selectedVerseReview?.verse.id == verse.id {
            selectedVerseReview = nil
        }

        if swipedVerseID == verse.id {
            swipedVerseID = nil
        }

        VerseRepository.shared.softDeleteVerse(id: verse.id)
        reloadVerses()
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
                .foregroundStyle(isSelected ? .blue : .secondary)

            Text(title)
                .foregroundStyle(.primary)

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

private struct SwipeToDeleteVerseRow<Label: View>: View {
    let id: String
    @Binding var openRowID: String?
    let onDelete: () -> Void
    let onTap: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var settledOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let actionWidth: CGFloat = 84
    private let revealThreshold: CGFloat = 52
    private let fullSwipeThreshold: CGFloat = 148

    private var contentOffset: CGFloat {
        let proposedOffset = settledOffset + dragOffset
        return min(0, max(-fullSwipeThreshold, proposedOffset))
    }

    private var deleteActionOpacity: CGFloat {
        contentOffset == 0 ? 0 : 1
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteAction

            label()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .offset(x: contentOffset)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isDragging else {
                        return
                    }

                    if settledOffset == 0 {
                        onTap()
                    } else {
                        closeRow()
                    }
                }
                .highPriorityGesture(dragGesture)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.86), value: settledOffset)
        .onChange(of: openRowID) { _, newValue in
            if newValue != id, settledOffset != 0 {
                settledOffset = 0
                dragOffset = 0
            }
        }
    }

    private var deleteAction: some View {
        HStack {
            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color(uiColor: .systemRed))
                    )
                    .frame(width: actionWidth, height: 64)
                    .opacity(deleteActionOpacity)
            }
            .buttonStyle(.plain)
            .disabled(settledOffset == 0)
        }
        .padding(.trailing, 12)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }

                if openRowID != id, value.translation.width < 0 {
                    openRowID = id
                }

                if value.translation.width < 0 || settledOffset < 0 {
                    dragOffset = value.translation.width
                } else {
                    dragOffset = 0
                }
            }
            .onEnded { value in
                defer {
                    dragOffset = 0
                    DispatchQueue.main.async {
                        isDragging = false
                    }
                }

                let finalOffset = settledOffset + value.translation.width
                let predictedOffset = settledOffset + value.predictedEndTranslation.width

                if predictedOffset <= -fullSwipeThreshold {
                    onDelete()
                    return
                }

                if finalOffset <= -revealThreshold {
                    openRow()
                } else {
                    closeRow()
                }
            }
    }

    private func openRow() {
        openRowID = id
        settledOffset = -actionWidth
    }

    private func closeRow() {
        if openRowID == id {
            openRowID = nil
        }

        settledOffset = 0
    }
}

#Preview {
    LibraryView()
}
