import SwiftUI

struct ContentView: View {
    enum FilterType: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case mastered = "Mastered"
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

    private var filteredVerses: [Verse] {
        switch selectedFilter {
        case .all:
            return verses
        case .learning:
            return verses.filter { !$0.isMastered }
        case .mastered:
            return verses.filter { $0.isMastered }
        }
    }

    private var learningCount: Int {
        verses.filter { !$0.isMastered }.count
    }

    private var masteredCount: Int {
        verses.filter { $0.isMastered }.count
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Anchored")
                        .font(.system(size: 34, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    StatCardView(
                        title: "Learning",
                        value: learningCount,
                        systemImage: "brain.head.profile",
                        iconColor: .blue
                    )

                    StatCardView(
                        title: "Mastered",
                        value: masteredCount,
                        systemImage: "checkmark.circle.fill",
                        iconColor: .green
                    )
                }
                .padding(.horizontal)

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Text("Your Verses")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                List {
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
                        }
                    }
                    .onDelete(perform: deleteVerses)
                }
                .listStyle(.plain)
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddVerse = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
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
        .onChange(of: verses) { _, newValue in
            VerseStore.save(newValue)
        }
        .onAppear {
            if VerseStore.load().isEmpty {
                VerseStore.save(verses)
            }
        }
    }

    private func deleteVerses(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredVerses[$0].id }
        verses.removeAll { idsToDelete.contains($0.id) }
    }
}

#Preview {
    ContentView()
}
