import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var verses: [Verse]

    enum FilterType: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case memorized = "Memorized"
    }

    @State private var showingAddVerse = false
    @State private var selectedVerse: Verse? = nil
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
                modelContext.insert(newVerse)
            }
        }
        .sheet(item: $selectedVerse) { verse in
            ReviewView(verse: verse)
        }
        .sheet(isPresented: $showingReviewSession) {
            ReviewSessionView(verses: learningVerses)
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
                                    selectedVerse = verse
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
        let versesToDelete = offsets.map { filteredVerses[$0] }
        for verse in versesToDelete {
            modelContext.delete(verse)
        }
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Verse.self, inMemory: true)
}
