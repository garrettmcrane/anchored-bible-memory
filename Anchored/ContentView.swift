import SwiftUI

struct ContentView: View {
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

    private static let allFoldersOption = "All Folders"

    @State private var showingAddVerse = false
    @State private var detailVerse: Verse? = nil
    @State private var selectedVerseReview: SingleVerseReviewPresentation? = nil
    @State private var selectedFilter: FilterType = .all
    @State private var selectedFolder: String = Self.allFoldersOption
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

        return [Self.allFoldersOption] + folderNames.sorted()
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

    private var filteredVerses: [Verse] {
        guard selectedFolder != Self.allFoldersOption else {
            return statusFilteredVerses
        }

        return statusFilteredVerses.filter { verse in
            normalizedFolderName(verse.folderName) == selectedFolder
        }
    }

    private var learningCount: Int {
        VerseQueries.learningVerses(verses).count
    }

    private var memorizedCount: Int {
        VerseQueries.memorizedVerses(verses).count
    }

    private var learningVerses: [Verse] {
        VerseQueries.learningVerses(verses)
    }

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top

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
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center) {
                Text("Anchored")
                    .font(.system(size: 34, weight: .bold))

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

            HStack(spacing: 14) {
                StatCardView(
                    title: "Learning",
                    value: learningCount,
                    systemImage: "brain.head.profile",
                    iconColor: .blue
                )

                StatCardView(
                    title: "Memorized",
                    value: memorizedCount,
                    systemImage: "checkmark.circle.fill",
                    iconColor: .green
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private func controlsSection(
        buttonHeight: CGFloat,
        spacing: CGFloat
    ) -> some View {
        VStack(spacing: spacing) {
            if !learningVerses.isEmpty {
                Button {
                    showingBatchReviewMethodPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                        Text("Review Learning Verses")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(.plain)
            }

            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Folders")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(folderOptions, id: \.self) { folder in
                            Button {
                                selectedFolder = folder
                            } label: {
                                Text(folder)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedFolder == folder ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedFolder == folder ? Color.blue : Color(.secondarySystemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
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
        .padding(.bottom, 28)
    }

    private func reloadVerses() {
        verses = VerseRepository.shared.loadVerses()

        if !folderOptions.contains(selectedFolder) {
            selectedFolder = Self.allFoldersOption
        }

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
    ContentView()
}
