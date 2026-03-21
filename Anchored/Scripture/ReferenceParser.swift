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

struct ReferenceImportParseResult {
    let references: [ScriptureReference]
    let unresolvedEntries: [String]
    let duplicateReferenceCount: Int
}

struct ReferenceIntakeParseResult {
    let references: [ScriptureReference]
    let unresolvedEntries: [String]
    let duplicateReferenceCount: Int
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

    nonisolated static func parseImportBlock(_ input: String) throws -> ReferenceImportParseResult {
        let normalizedInput = input.replacingOccurrences(of: "\r\n", with: "\n")
        guard !normalizeWhitespace(normalizedInput).isEmpty else {
            throw ReferenceParserError.emptyInput
        }

        let matches = importReferenceRegularExpression.matches(
            in: normalizedInput,
            range: NSRange(normalizedInput.startIndex..., in: normalizedInput)
        )

        var references: [ScriptureReference] = []
        var consumedRanges: [Range<String.Index>] = []
        var seenReferenceKeys: Set<String> = []
        var duplicateReferenceCount = 0

        for match in matches {
            guard let range = Range(match.range, in: normalizedInput) else {
                continue
            }

            let candidate = normalizedImportCandidate(String(normalizedInput[range]))

            do {
                let reference = try parseSingle(candidate)
                let referenceKey = canonicalReferenceKey(reference.normalizedReference)

                if seenReferenceKeys.insert(referenceKey).inserted {
                    references.append(reference)
                } else {
                    duplicateReferenceCount += 1
                }

                consumedRanges.append(range)
            } catch {
                continue
            }
        }

        let unresolvedEntries = unresolvedImportEntries(
            in: normalizedInput,
            consumedRanges: consumedRanges
        )

        return ReferenceImportParseResult(
            references: references,
            unresolvedEntries: unresolvedEntries,
            duplicateReferenceCount: duplicateReferenceCount
        )
    }

    nonisolated static func parseAddIntake(_ input: String) throws -> ReferenceIntakeParseResult {
        let normalizedInput = input.replacingOccurrences(of: "\r\n", with: "\n")
        guard !normalizeWhitespace(normalizedInput).isEmpty else {
            throw ReferenceParserError.emptyInput
        }

        let segmentSeparators = CharacterSet(charactersIn: ",;\n")
        let rawSegments = normalizedInput
            .components(separatedBy: segmentSeparators)
            .map(normalizeWhitespace)
            .filter { !$0.isEmpty }

        var references: [ScriptureReference] = []
        var unresolvedEntries: [String] = []
        var seenReferenceKeys: Set<String> = []
        var duplicateReferenceCount = 0

        for segment in rawSegments {
            if let directReference = tryParseSingle(segment) {
                let referenceKey = canonicalReferenceKey(directReference.normalizedReference)
                if seenReferenceKeys.insert(referenceKey).inserted {
                    references.append(directReference)
                } else {
                    duplicateReferenceCount += 1
                }
                continue
            }

            let extractionResult = extractReferences(from: segment, seenReferenceKeys: &seenReferenceKeys)
            references.append(contentsOf: extractionResult.references)
            duplicateReferenceCount += extractionResult.duplicateReferenceCount

            if extractionResult.references.isEmpty, likelyReferenceAttempt(segment) {
                unresolvedEntries.append(segment)
            } else {
                unresolvedEntries.append(contentsOf: extractionResult.unresolvedEntries)
            }
        }

        return ReferenceIntakeParseResult(
            references: references,
            unresolvedEntries: deduplicatedEntries(unresolvedEntries),
            duplicateReferenceCount: duplicateReferenceCount
        )
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

        guard let numericValue = Int(remainder) else {
            throw ReferenceParserError.invalidReference(cleanedInput)
        }

        if BibleBookCatalog.isSingleChapterBook(book) {
            return ScriptureReference(
                book: book,
                startChapter: 1,
                startVerse: numericValue,
                endChapter: nil,
                endVerse: nil,
                kind: .singleVerse,
                normalizedReference: "\(book.name) 1:\(numericValue)"
            )
        }

        return ScriptureReference(
            book: book,
            startChapter: numericValue,
            startVerse: nil,
            endChapter: nil,
            endVerse: nil,
            kind: .chapter,
            normalizedReference: "\(book.name) \(numericValue)"
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

    nonisolated private static func tryParseSingle(_ input: String) -> ScriptureReference? {
        try? parseSingle(input)
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

    nonisolated private static func normalizedImportCandidate(_ value: String) -> String {
        normalizeWhitespace(
            value
                .replacingOccurrences(of: "\\s*:\\s*", with: ":", options: .regularExpression)
                .replacingOccurrences(of: "\\s*-\\s*", with: "-", options: .regularExpression)
        )
    }

    nonisolated private static func extractReferences(
        from input: String,
        seenReferenceKeys: inout Set<String>
    ) -> (references: [ScriptureReference], unresolvedEntries: [String], duplicateReferenceCount: Int) {
        let matches = importReferenceRegularExpression.matches(
            in: input,
            range: NSRange(input.startIndex..., in: input)
        )

        var references: [ScriptureReference] = []
        var consumedRanges: [Range<String.Index>] = []
        var duplicateReferenceCount = 0

        for match in matches {
            guard let range = Range(match.range, in: input) else {
                continue
            }

            let candidate = normalizedImportCandidate(String(input[range]))
            guard let reference = tryParseSingle(candidate) else {
                continue
            }

            let referenceKey = canonicalReferenceKey(reference.normalizedReference)
            if seenReferenceKeys.insert(referenceKey).inserted {
                references.append(reference)
            } else {
                duplicateReferenceCount += 1
            }

            consumedRanges.append(range)
        }

        let unresolvedEntries = unresolvedReferenceAttempts(
            in: input,
            consumedRanges: consumedRanges
        )

        return (references, unresolvedEntries, duplicateReferenceCount)
    }

    nonisolated private static func unresolvedImportEntries(
        in input: String,
        consumedRanges: [Range<String.Index>]
    ) -> [String] {
        guard !consumedRanges.isEmpty else {
            return cleanedUnresolvedChunks(from: input)
        }

        var segments: [String] = []
        var currentIndex = input.startIndex

        for range in consumedRanges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if currentIndex < range.lowerBound {
                segments.append(String(input[currentIndex..<range.lowerBound]))
            }

            currentIndex = range.upperBound
        }

        if currentIndex < input.endIndex {
            segments.append(String(input[currentIndex..<input.endIndex]))
        }

        return cleanedUnresolvedChunks(from: segments.joined(separator: "\n"))
    }

    nonisolated private static func cleanedUnresolvedChunks(from value: String) -> [String] {
        var seen: Set<String> = []
        var entries: [String] = []
        let separatorSet = CharacterSet(charactersIn: ",;\n")

        for chunk in value.components(separatedBy: separatorSet) {
            let cleanedChunk = normalizeWhitespace(
                chunk.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            )

            guard !cleanedChunk.isEmpty else {
                continue
            }

            let entryKey = canonicalReferenceKey(cleanedChunk)
            if seen.insert(entryKey).inserted {
                entries.append(cleanedChunk)
            }
        }

        return entries
    }

    nonisolated private static func unresolvedReferenceAttempts(
        in input: String,
        consumedRanges: [Range<String.Index>]
    ) -> [String] {
        cleanedUnresolvedChunks(
            from: unresolvedImportEntries(in: input, consumedRanges: consumedRanges)
                .filter(likelyReferenceAttempt)
                .joined(separator: "\n")
        )
    }

    nonisolated private static func likelyReferenceAttempt(_ value: String) -> Bool {
        let normalizedValue = normalizeWhitespace(value)
        guard !normalizedValue.isEmpty else {
            return false
        }

        let containsDigit = normalizedValue.rangeOfCharacter(from: .decimalDigits) != nil
        let containsLetter = normalizedValue.rangeOfCharacter(from: .letters) != nil
        return containsDigit && containsLetter
    }

    nonisolated private static func deduplicatedEntries(_ entries: [String]) -> [String] {
        var seen: Set<String> = []
        var deduplicated: [String] = []

        for entry in entries {
            let normalizedEntry = canonicalReferenceKey(entry)
            if seen.insert(normalizedEntry).inserted {
                deduplicated.append(entry)
            }
        }

        return deduplicated
    }

    nonisolated private static func canonicalReferenceKey(_ value: String) -> String {
        normalizeWhitespace(value).lowercased()
    }

    nonisolated private static let importReferenceRegularExpression: NSRegularExpression = {
        let aliasPattern = BibleBookCatalog.sortedAliases
            .map { alias in
                NSRegularExpression.escapedPattern(for: alias)
                    .replacingOccurrences(of: "\\ ", with: "\\s*")
            }
            .joined(separator: "|")

        let pattern = "(?i)(?<![A-Za-z0-9])(?:\(aliasPattern))\\s+\\d+(?::\\d+(?:\\s*-\\s*\\d+)?)?"
        return try! NSRegularExpression(pattern: pattern)
    }()
}
