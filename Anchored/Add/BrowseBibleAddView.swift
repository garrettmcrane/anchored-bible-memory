import SwiftUI

struct BrowseBibleAddView: View {
    enum SelectionMode: String, CaseIterable, Identifiable {
        case singleVerse = "Single Verse"
        case verseRange = "Verse Range"

        var id: String {
            rawValue
        }
    }

    let onSaveVerse: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var translation: BibleTranslation = .kjv
    @State private var books: [BibleBook] = []
    @State private var selectedBook: BibleBook?
    @State private var chapters: [Int] = []
    @State private var selectedChapter: Int?
    @State private var verses: [ScriptureVerse] = []
    @State private var selectionMode: SelectionMode = .singleVerse
    @State private var selectedStartVerse: Int?
    @State private var selectedEndVerse: Int?
    @State private var previewContext: ScriptureAddPreviewContext?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TranslationPickerSection(selection: $translation)

                if let message {
                    AddFlowMessageCard(message: message, tint: .orange)
                }

                selectorsSection

                if !verses.isEmpty {
                    selectionSection
                    versePreviewSection
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Browse Bible")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $previewContext) { context in
            ScriptureAddPreviewView(
                passages: context.passages,
                onSaveVerse: onSaveVerse,
                onComplete: onComplete
            )
        }
        .task {
            loadBooks()
        }
        .onChange(of: translation) { _, _ in
            loadBooks()
        }
        .onChange(of: selectedBook) { _, _ in
            loadChapters()
        }
        .onChange(of: selectedChapter) { _, _ in
            loadVerses()
        }
    }

    private var selectorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Menu {
                ForEach(books) { book in
                    Button(book.name) {
                        selectedBook = book
                    }
                }
            } label: {
                selectorLabel(title: "Book", value: selectedBook?.name ?? "Choose a book")
            }
            .buttonStyle(.plain)
            .disabled(books.isEmpty)

            Menu {
                ForEach(chapters, id: \.self) { chapter in
                    Button("Chapter \(chapter)") {
                        selectedChapter = chapter
                    }
                }
            } label: {
                selectorLabel(
                    title: "Chapter",
                    value: selectedChapter.map { "Chapter \($0)" } ?? "Choose a chapter"
                )
            }
            .buttonStyle(.plain)
            .disabled(chapters.isEmpty)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selection")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Picker("Mode", selection: $selectionMode) {
                ForEach(SelectionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Menu {
                ForEach(verses, id: \.verse) { verse in
                    Button("Verse \(verse.verse)") {
                        selectedStartVerse = verse.verse
                        if selectionMode == .singleVerse {
                            selectedEndVerse = verse.verse
                        } else if let selectedEndVerse, selectedEndVerse < verse.verse {
                            self.selectedEndVerse = verse.verse
                        }
                    }
                }
            } label: {
                selectorLabel(
                    title: "Start",
                    value: selectedStartVerse.map { "Verse \($0)" } ?? "Choose a verse"
                )
            }
            .buttonStyle(.plain)

            if selectionMode == .verseRange {
                Menu {
                    ForEach(verses.filter { verse in
                        guard let selectedStartVerse else {
                            return true
                        }

                        return verse.verse >= selectedStartVerse
                    }, id: \.verse) { verse in
                        Button("Verse \(verse.verse)") {
                            selectedEndVerse = verse.verse
                        }
                    }
                } label: {
                    selectorLabel(
                        title: "End",
                        value: selectedEndVerse.map { "Verse \($0)" } ?? "Choose an ending verse"
                    )
                }
                .buttonStyle(.plain)
            }

            Button("Preview Passage") {
                buildPreview()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedReference == nil)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var versePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chapter")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(verses) { verse in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(verse.verse)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, alignment: .leading)

                    Text(verse.text)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var selectedReference: ScriptureReference? {
        guard let selectedBook, let selectedChapter, let selectedStartVerse else {
            return nil
        }

        switch selectionMode {
        case .singleVerse:
            return ScriptureReference(
                book: selectedBook,
                startChapter: selectedChapter,
                startVerse: selectedStartVerse,
                endChapter: nil,
                endVerse: nil,
                kind: .singleVerse,
                normalizedReference: "\(selectedBook.name) \(selectedChapter):\(selectedStartVerse)"
            )
        case .verseRange:
            guard let selectedEndVerse, selectedEndVerse >= selectedStartVerse else {
                return nil
            }

            return ScriptureReference(
                book: selectedBook,
                startChapter: selectedChapter,
                startVerse: selectedStartVerse,
                endChapter: selectedChapter,
                endVerse: selectedEndVerse,
                kind: .verseRange,
                normalizedReference: "\(selectedBook.name) \(selectedChapter):\(selectedStartVerse)-\(selectedEndVerse)"
            )
        }
    }

    private func selectorLabel(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private func loadBooks() {
        guard translation.isAvailable else {
            books = []
            chapters = []
            verses = []
            selectedBook = nil
            selectedChapter = nil
            message = "ESV is visible for the future, but it is not available until API approval is in place."
            return
        }

        do {
            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            books = try provider.browseBooks()
            selectedBook = books.first
            message = nil
        } catch {
            books = []
            chapters = []
            verses = []
            selectedBook = nil
            selectedChapter = nil
            message = error.localizedDescription
        }
    }

    private func loadChapters() {
        guard let selectedBook else {
            chapters = []
            selectedChapter = nil
            verses = []
            return
        }

        do {
            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            chapters = try provider.browseChapters(in: selectedBook)
            selectedChapter = chapters.first
        } catch {
            chapters = []
            selectedChapter = nil
            verses = []
            message = error.localizedDescription
        }
    }

    private func loadVerses() {
        guard let selectedBook, let selectedChapter else {
            verses = []
            selectedStartVerse = nil
            selectedEndVerse = nil
            return
        }

        do {
            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            verses = try provider.browseVerses(in: selectedBook, chapter: selectedChapter)
            selectedStartVerse = verses.first?.verse
            selectedEndVerse = verses.first?.verse
            message = nil
        } catch {
            verses = []
            selectedStartVerse = nil
            selectedEndVerse = nil
            message = error.localizedDescription
        }
    }

    private func buildPreview() {
        guard let selectedReference else {
            return
        }

        do {
            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            let passage = try provider.fetchPassage(for: selectedReference)
            previewContext = ScriptureAddPreviewContext(passages: [passage])
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}
