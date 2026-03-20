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
    private static let uncategorizedFolderName = "Uncategorized"

    @State private var showingAddVerse = false
    @State private var showingFolderFilterSheet = false
    @State private var detailVerse: Verse? = nil
    @State private var selectedVerseReview: SingleVerseReviewPresentation? = nil
    @State private var selectedFilter: FilterType = .all
    @State private var selectedFolders: Set<String> = []
    @State private var sortMode: SortMode = .newest
    @State private var selectedBatchReviewMethod: ReviewMethod? = nil
    @State private var showingBatchReviewMethodPicker = false
    @State private var scrollOffset: CGFloat = 0
    @State private var verses: [Verse] = VerseRepository.shared.loadVerses()
#if DEBUG
    private let debugRecencySimulator = DebugVerseRecencySimulator()
#endif

    private let floatingButtonHeight: CGFloat = 50
    private let floatingButtonVerticalInset: CGFloat = 8
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

    private var reviewVerses: [Verse] {
        verses
    }

    private var floatingButtonClearance: CGFloat {
        floatingButtonHeight + (floatingButtonVerticalInset * 2) + 16
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

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top

            NavigationStack {
                ZStack(alignment: .top) {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()

                    List {
                        topSummarySection
                            .opacity(summaryOpacity)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        controlsSection(spacing: currentControlsSpacing)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        Section {
                            verseSectionHeader
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)

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
                        }
                        .listSectionSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .contentMargins(.bottom, floatingButtonClearance, for: .scrollContent)
                    .environment(\.defaultMinListRowHeight, 1)
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
                    floatingReviewButton()
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
            case .firstLetterTyping:
                FirstLetterTypingReviewView(verse: presentation.verse) { _ in
                    reloadVerses()
                }
            }
        }
        .sheet(item: $selectedBatchReviewMethod) { method in
            switch method {
            case .flashcard:
                ReviewSessionView(verses: reviewVerses) { _ in
                    reloadVerses()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewSessionView(verses: reviewVerses) { _ in
                    reloadVerses()
                }
            case .firstLetterTyping:
                FirstLetterTypingReviewSessionView(verses: reviewVerses) { _ in
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
        .padding(.horizontal, 0)
        .padding(.top, 18)
        .padding(.bottom, 4)
    }

    private func controlsSection(spacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: 12) {
                LibraryFilterSegmentedControl(selection: $selectedFilter)
                    .frame(height: 34)

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
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
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
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Folders")

#if DEBUG
                debugRecencyButton
#endif
            }

            if hasActiveFolderFilter {
                Text("Filtered: \(folderSelectionSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.top, 2)
        .padding(.bottom, 2)
    }

    private var verseSectionHeader: some View {
        Text("Your Verses")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 0)
            .padding(.top, 10)
            .padding(.bottom, 12)
    }

    private var emptyVersesState: some View {
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
        .padding(.horizontal, 0)
        .padding(.bottom, 16)
    }

    private func verseListRow(verse: Verse, index: Int, totalCount: Int) -> some View {
        let rowShape = UnevenRoundedRectangle(
            cornerRadii: rowCornerRadii(for: index, totalCount: totalCount),
            style: .continuous
        )

        return Button {
            detailVerse = verse
        } label: {
            VerseRowView(verse: verse)
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
        .buttonStyle(.plain)
        .containerShape(rowShape)
        .clipShape(rowShape)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteVerse(verse)
            } label: {
                Image(systemName: "trash")
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(
            rowBackground(for: index, totalCount: totalCount)
        )
        .listRowSeparator(.hidden)
    }

    private func rowBackground(for index: Int, totalCount: Int) -> some View {
        let radii = rowCornerRadii(for: index, totalCount: totalCount)

        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
            .fill(Color(.systemBackground))
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
        .padding(.bottom, floatingButtonVerticalInset)
    }

#if DEBUG
    private var debugRecencyButton: some View {
        Menu {
            ForEach(DebugVerseRecencySimulator.Preset.allCases) { preset in
                Button(preset.title) {
                    debugRecencySimulator.apply(preset)
                    reloadVerses()
                }
            }
        } label: {
            Image(systemName: "ladybug")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Debug recency simulator")
    }
#endif

    private func reloadVerses() {
        verses = VerseRepository.shared.loadVerses()

        if let detailVerse {
            self.detailVerse = verses.first(where: { $0.id == detailVerse.id })
        }

        selectedFolders = selectedFolders.intersection(Set(folderOptions))

    }

    private func normalizedFolderName(_ folderName: String) -> String {
        let trimmedFolderName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)

        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsedWhitespaceFolderName.isEmpty else {
            return Self.uncategorizedFolderName
        }

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

        VerseRepository.shared.softDeleteVerse(id: verse.id)
        reloadVerses()
    }
}

private struct LibraryFilterSegmentedControl: UIViewRepresentable {
    @Binding var selection: LibraryView.FilterType

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: LibraryView.FilterType.allCases.map(\.rawValue))
        control.selectedSegmentIndex = selectedIndex
        control.selectedSegmentTintColor = UIColor.systemBackground
        control.backgroundColor = UIColor.tertiarySystemFill
        control.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.label
            ],
            for: .normal
        )
        control.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.label
            ],
            for: .selected
        )
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        if uiView.selectedSegmentIndex != selectedIndex {
            uiView.selectedSegmentIndex = selectedIndex
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    private var selectedIndex: Int {
        LibraryView.FilterType.allCases.firstIndex(of: selection) ?? 0
    }

    final class Coordinator: NSObject {
        @Binding private var selection: LibraryView.FilterType

        init(selection: Binding<LibraryView.FilterType>) {
            _selection = selection
        }

        @objc func valueChanged(_ sender: UISegmentedControl) {
            let allCases = LibraryView.FilterType.allCases
            guard allCases.indices.contains(sender.selectedSegmentIndex) else {
                return
            }

            selection = allCases[sender.selectedSegmentIndex]
        }
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

#Preview {
    LibraryView()
}
