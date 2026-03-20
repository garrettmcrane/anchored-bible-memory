import SwiftUI

struct ContentView: View {
    enum FilterType: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case memorized = "Memorized"
    }

    @State private var verses: [Verse] = VerseStore.load().isEmpty ? [
        Verse(
            reference: "John 3:16",
            text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life."
        ),
        Verse(
            reference: "Romans 8:28",
            text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose."
        )
    ] : VerseStore.load()

    @State private var showingAddVerse = false
    @State private var selectedIndex: Int? = nil
    @State private var selectedFilter: FilterType = .all
    @State private var showingReviewSession = false
    @State private var scrollOffset: CGFloat = 0

    private let expandedReviewButtonHeight: CGFloat = 66
    private let collapsedReviewButtonHeight: CGFloat = 34
    private let summaryFadeDistance: CGFloat = 100

    private var filteredVerses: [Verse] {
        switch selectedFilter {
        case .all:
            return verses
        case .learning:
            return verses.filter { !$0.isMastered }
        case .memorized:
            return verses.filter { $0.isMastered }
        }
    }

    private var learningCount: Int {
        verses.filter { !$0.isMastered }.count
    }

    private var memorizedCount: Int {
        verses.filter { $0.isMastered }.count
    }

    private var learningVerses: [Verse] {
        verses.filter { !$0.isMastered }
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
            }
        }
        .sheet(isPresented: $showingAddVerse) {
            AddVerseView { newVerse in
                verses.append(newVerse)
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedIndex != nil },
            set: { if !$0 { selectedIndex = nil } }
        )) {
            if let index = selectedIndex {
                ReviewView(
                    verse: verses[index],
                    onUpdate: { updatedVerse in
                        verses[index] = updatedVerse
                    }
                )
            }
        }
        .sheet(isPresented: $showingReviewSession) {
            ReviewSessionView(
                verses: learningVerses,
                onComplete: { updatedSessionVerses in
                    for updatedVerse in updatedSessionVerses {
                        if let realIndex = verses.firstIndex(where: { $0.id == updatedVerse.id }) {
                            verses[realIndex] = updatedVerse
                        }
                    }
                }
            )
        }
        .onChange(of: verses) { _, newValue in
            VerseStore.save(newValue)
        }
        .onAppear {
            if VerseStore.load().isEmpty {
                VerseStore.save(verses)
            }
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
                    showingReviewSession = true
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
                        NavigationLink {
                            VerseDetailView(
                                verse: verse,
                                onStartReview: {
                                    if let realIndex = verses.firstIndex(of: verse) {
                                        selectedIndex = realIndex
                                    }
                                }
                            )
                        } label: {
                            VerseRowView(verse: verse)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if verse.id != filteredVerses.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color(.systemBackground))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 28)
    }

    private func deleteVerses(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredVerses[$0].id }
        verses.removeAll { idsToDelete.contains($0.id) }
    }
}

#Preview {
    ContentView()
}
