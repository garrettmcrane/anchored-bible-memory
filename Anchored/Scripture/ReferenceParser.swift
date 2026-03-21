import Foundation

enum ReferenceParserError: LocalizedError {
    case emptyInput
    case invalidReference(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Enter at least one Scripture reference."
        case .invalidReference(let value):
            return "We couldn't understand \"\(value)\". Check the reference and try again."
        }
    }
}

enum ReferenceParser {
    nonisolated static func parse(_ input: String) throws -> [ScriptureReference] {
        let components = input
            .split(whereSeparator: { $0 == "," || $0.isNewline })
            .map { normalizeWhitespace(String($0)) }
            .filter { !$0.isEmpty }

        guard !components.isEmpty else {
            throw ReferenceParserError.emptyInput
        }

        return try components.map(parseSingle)
    }

    nonisolated static func parseSingle(_ input: String) throws -> ScriptureReference {
        let cleanedInput = normalizeWhitespace(input)
        guard let (book, remainder) = matchBook(in: cleanedInput) else {
            throw ReferenceParserError.invalidReference(cleanedInput)
        }

        guard !remainder.isEmpty else {
            throw ReferenceParserError.invalidReference(cleanedInput)
        }

        if remainder.contains(":") {
            return try parseVerseReference(book: book, remainder: remainder, original: cleanedInput)
        }

        guard let chapter = Int(remainder) else {
            throw ReferenceParserError.invalidReference(cleanedInput)
        }

        return ScriptureReference(
            book: book,
            startChapter: chapter,
            startVerse: nil,
            endChapter: nil,
            endVerse: nil,
            kind: .chapter,
            normalizedReference: "\(book.name) \(chapter)"
        )
    }

    nonisolated private static func parseVerseReference(book: BibleBook, remainder: String, original: String) throws -> ScriptureReference {
        let parts = remainder.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2, let startChapter = Int(parts[0]) else {
            throw ReferenceParserError.invalidReference(original)
        }

        let versePart = String(parts[1])
        if versePart.contains("-") {
            let rangeParts = versePart.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
            guard
                rangeParts.count == 2,
                let startVerse = Int(rangeParts[0]),
                let endVerse = Int(rangeParts[1]),
                endVerse >= startVerse
            else {
                throw ReferenceParserError.invalidReference(original)
            }

            return ScriptureReference(
                book: book,
                startChapter: startChapter,
                startVerse: startVerse,
                endChapter: startChapter,
                endVerse: endVerse,
                kind: .verseRange,
                normalizedReference: "\(book.name) \(startChapter):\(startVerse)-\(endVerse)"
            )
        }

        guard let verse = Int(versePart) else {
            throw ReferenceParserError.invalidReference(original)
        }

        return ScriptureReference(
            book: book,
            startChapter: startChapter,
            startVerse: verse,
            endChapter: nil,
            endVerse: nil,
            kind: .singleVerse,
            normalizedReference: "\(book.name) \(startChapter):\(verse)"
        )
    }

    nonisolated private static func matchBook(in input: String) -> (BibleBook, String)? {
        let normalizedInput = BibleBookCatalog.normalize(input)

        for alias in BibleBookCatalog.sortedAliases {
            guard normalizedInput.hasPrefix(alias) else {
                continue
            }

            let remainder = normalizeWhitespace(String(normalizedInput.dropFirst(alias.count)))
            guard let book = BibleBookCatalog.aliasMap[alias] else {
                continue
            }

            return (book, remainder)
        }

        return nil
    }

    nonisolated private static func normalizeWhitespace(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
