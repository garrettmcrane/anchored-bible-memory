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
                headerCard

                TranslationPickerSection(selection: $translation)
                    .padding(.leading, 18)
                    .padding(.trailing, 6)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground(cornerRadius: 24))

                if let message {
                    AddFlowMessageCard(message: message, tint: AppColors.gold)
                }

                selectionFlowCard
            }
            .padding(AnchoredSpacing.screenHorizontal)
        }
        .background(AppColors.background)
        .navigationTitle("Search Bible")
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
        .onChange(of: selectionMode) { _, newMode in
            guard let selectedStartVerse else {
                selectedEndVerse = nil
                return
            }

            if newMode == .singleVerse {
                selectedEndVerse = selectedStartVerse
            } else if let selectedEndVerse, selectedEndVerse < selectedStartVerse {
                self.selectedEndVerse = selectedStartVerse
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add verses by browsing Scripture")
                .font(AnchoredFont.editorial(28))
                .foregroundStyle(AppColors.textPrimary)

            Text("Choose a Bible book, then select a chapter and verse. You can add a single verse or switch to a verse range when you want to save a longer passage.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Pick book, chapter, verse, then preview before saving.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.structuralAccent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AnchoredCardBackground(elevated: true, cornerRadius: 26))
    }

    private var selectionFlowCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                compactSelector(
                    title: "Book",
                    value: selectedBook?.name ?? "Choose a book",
                    isEnabled: !books.isEmpty,
                    menuContent: {
                        ForEach(books) { book in
                            Button(book.name) {
                                selectedBook = book
                            }
                        }
                    }
                )

                compactSelector(
                    title: "Chapter",
                    value: selectedChapter.map(String.init) ?? "Choose",
                    isEnabled: !chapters.isEmpty,
                    menuContent: {
                        ForEach(chapters, id: \.self) { chapter in
                            Button("Chapter \(chapter)") {
                                selectedChapter = chapter
                            }
                        }
                    }
                )
                .frame(width: 132)
            }

            if !verses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    Picker("Mode", selection: $selectionMode) {
                        ForEach(SelectionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppColors.secondarySurface))

                    if selectionMode == .singleVerse {
                        compactSelector(
                            title: "Verse",
                            value: selectedStartVerse.map(String.init) ?? "Choose",
                            isEnabled: !verses.isEmpty,
                            menuContent: {
                                verseButtons { verse in
                                    selectedStartVerse = verse
                                    selectedEndVerse = verse
                                }
                            }
                        )
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            compactSelector(
                                title: "Start",
                                value: selectedStartVerse.map(String.init) ?? "Choose",
                                isEnabled: !verses.isEmpty,
                                menuContent: {
                                    verseButtons { verse in
                                        selectedStartVerse = verse
                                        if let selectedEndVerse, selectedEndVerse < verse {
                                            self.selectedEndVerse = verse
                                        } else if self.selectedEndVerse == nil {
                                            self.selectedEndVerse = verse
                                        }
                                    }
                                }
                            )

                            compactSelector(
                                title: "End",
                                value: selectedEndVerse.map(String.init) ?? "Choose",
                                isEnabled: selectedStartVerse != nil,
                                menuContent: {
                                    verseButtons(filteringFrom: selectedStartVerse) { verse in
                                        selectedEndVerse = verse
                                    }
                                }
                            )
                        }
                    }

                    if let selectionSummary {
                        Text(selectionSummary)
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Button(previewButtonTitle) {
                        buildPreview()
                    }
                    .buttonStyle(AnchoredPrimaryButtonStyle())
                    .opacity(selectedReference == nil ? 0.45 : 1)
                    .disabled(selectedReference == nil)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 26))
    }

    private var selectionSummary: String? {
        guard let selectedBook, let selectedChapter else {
            return nil
        }

        guard let selectedReference else {
            return "\(selectedBook.name) \(selectedChapter)"
        }

        return selectedReference.normalizedReference
    }

    private var previewButtonTitle: String {
        switch selectionMode {
        case .singleVerse:
            return "Preview Verse"
        case .verseRange:
            return "Preview Verses"
        }
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

    private func compactSelector<MenuContent: View>(
        title: String,
        value: String,
        isEnabled: Bool,
        @ViewBuilder menuContent: () -> MenuContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            Menu {
                menuContent()
            } label: {
                HStack(spacing: 10) {
                    Text(value)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isEnabled ? AppColors.textPrimary : AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(cardBackground(cornerRadius: 16, fill: AppColors.elevatedSurface))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardBackground(cornerRadius: CGFloat, fill: Color = AppColors.surface) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
    }

    private func verseButtons(
        filteringFrom startVerse: Int? = nil,
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        ForEach(verses.filter { verse in
            guard let startVerse else {
                return true
            }

            return verse.verse >= startVerse
        }, id: \.verse) { verse in
            Button("Verse \(verse.verse)") {
                onSelect(verse.verse)
            }
        }
    }

    private func loadBooks() {
        guard translation.isAvailable else {
            books = []
            chapters = []
            verses = []
            selectedBook = nil
            selectedChapter = nil
            selectedStartVerse = nil
            selectedEndVerse = nil
            message = "ESV is shown here for what’s next, but it isn’t available yet."
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
            selectedStartVerse = nil
            selectedEndVerse = nil
            message = error.localizedDescription
        }
    }

    private func loadChapters() {
        guard let selectedBook else {
            chapters = []
            selectedChapter = nil
            verses = []
            selectedStartVerse = nil
            selectedEndVerse = nil
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
            selectedStartVerse = nil
            selectedEndVerse = nil
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
            selectedEndVerse = selectionMode == .singleVerse ? verses.first?.verse : verses.first?.verse
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

#Preview {
    NavigationStack {
        BrowseBibleAddView(onSaveVerse: { _ in }, onComplete: nil)
    }
}
