import Foundation
import SQLite3

final class KJVLocalScriptureProvider: ScriptureProvider {
    let translation: BibleTranslation = .kjv

    func fetchPassage(for reference: ScriptureReference) throws -> ScripturePassage {
        let verses = try fetchVerses(for: reference)
        guard !verses.isEmpty else {
            throw ScriptureProviderError.verseNotFound(reference.normalizedReference)
        }

        let segments = verses.map { verse in
            ScripturePassageSegment(reference: verse.reference, text: verse.text)
        }

        return ScripturePassage(
            normalizedReference: reference.normalizedReference,
            translation: translation,
            text: verses.map(\.text).joined(separator: " "),
            segments: segments
        )
    }

    func fetchPassages(for references: [ScriptureReference]) throws -> [ScripturePassage] {
        try references.map(fetchPassage(for:))
    }

    func browseBooks() throws -> [BibleBook] {
        try withDatabase { database in
            let sql = """
            SELECT id, abbreviation, name, sort_order, testament
            FROM books
            ORDER BY sort_order ASC;
            """

            let statement = try prepareStatement(sql, database: database)
            defer { sqlite3_finalize(statement) }

            var books: [BibleBook] = []

            while sqlite3_step(statement) == SQLITE_ROW {
                books.append(
                    BibleBook(
                        id: Int(sqlite3_column_int(statement, 0)),
                        abbreviation: stringValue(from: statement, column: 1),
                        name: stringValue(from: statement, column: 2),
                        sortOrder: Int(sqlite3_column_int(statement, 3)),
                        testament: stringValue(from: statement, column: 4)
                    )
                )
            }

            return books
        }
    }

    func browseChapters(in book: BibleBook) throws -> [Int] {
        try withDatabase { database in
            let sql = """
            SELECT DISTINCT chapter
            FROM verses
            WHERE book_id = ?
            ORDER BY chapter ASC;
            """

            let statement = try prepareStatement(sql, database: database)
            defer { sqlite3_finalize(statement) }

            sqlite3_bind_int(statement, 1, Int32(book.id))

            var chapters: [Int] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                chapters.append(Int(sqlite3_column_int(statement, 0)))
            }

            return chapters
        }
    }

    func browseVerses(in book: BibleBook, chapter: Int) throws -> [ScriptureVerse] {
        try withDatabase { database in
            let sql = """
            SELECT chapter, verse, reference, text, sort_key
            FROM verses
            WHERE book_id = ? AND chapter = ?
            ORDER BY verse ASC;
            """

            let statement = try prepareStatement(sql, database: database)
            defer { sqlite3_finalize(statement) }

            sqlite3_bind_int(statement, 1, Int32(book.id))
            sqlite3_bind_int(statement, 2, Int32(chapter))

            var verses: [ScriptureVerse] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                verses.append(
                    ScriptureVerse(
                        book: book,
                        chapter: Int(sqlite3_column_int(statement, 0)),
                        verse: Int(sqlite3_column_int(statement, 1)),
                        reference: stringValue(from: statement, column: 2),
                        text: stringValue(from: statement, column: 3),
                        sortKey: Int(sqlite3_column_int(statement, 4))
                    )
                )
            }

            return verses
        }
    }

    private func fetchVerses(for reference: ScriptureReference) throws -> [ScriptureVerse] {
        switch reference.kind {
        case .singleVerse:
            guard let verse = reference.startVerse else {
                throw ScriptureProviderError.unsupportedReference(reference.normalizedReference)
            }

            return try queryVerses(
                book: reference.book,
                sql: """
                SELECT chapter, verse, reference, text, sort_key
                FROM verses
                WHERE book_id = ? AND chapter = ? AND verse = ?
                ORDER BY verse ASC;
                """,
                binds: [reference.book.id, reference.startChapter, verse]
            )
        case .verseRange:
            guard
                let startVerse = reference.startVerse,
                let endVerse = reference.endVerse,
                reference.endChapter == nil || reference.endChapter == reference.startChapter
            else {
                throw ScriptureProviderError.unsupportedReference(reference.normalizedReference)
            }

            return try queryVerses(
                book: reference.book,
                sql: """
                SELECT chapter, verse, reference, text, sort_key
                FROM verses
                WHERE book_id = ? AND chapter = ? AND verse BETWEEN ? AND ?
                ORDER BY verse ASC;
                """,
                binds: [reference.book.id, reference.startChapter, startVerse, endVerse]
            )
        case .chapter:
            return try queryVerses(
                book: reference.book,
                sql: """
                SELECT chapter, verse, reference, text, sort_key
                FROM verses
                WHERE book_id = ? AND chapter = ?
                ORDER BY verse ASC;
                """,
                binds: [reference.book.id, reference.startChapter]
            )
        }
    }

    private func queryVerses(book: BibleBook, sql: String, binds: [Int]) throws -> [ScriptureVerse] {
        try withDatabase { database in
            let statement = try prepareStatement(sql, database: database)
            defer { sqlite3_finalize(statement) }

            for (index, value) in binds.enumerated() {
                sqlite3_bind_int(statement, Int32(index + 1), Int32(value))
            }

            var verses: [ScriptureVerse] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                verses.append(
                    ScriptureVerse(
                        book: book,
                        chapter: Int(sqlite3_column_int(statement, 0)),
                        verse: Int(sqlite3_column_int(statement, 1)),
                        reference: stringValue(from: statement, column: 2),
                        text: stringValue(from: statement, column: 3),
                        sortKey: Int(sqlite3_column_int(statement, 4))
                    )
                )
            }

            return verses
        }
    }

    private func withDatabase<T>(_ work: (OpaquePointer) throws -> T) throws -> T {
        guard let databaseURL = Self.databaseURL() else {
            throw ScriptureProviderError.databaseMissing(
                "KJV.sqlite is not bundled yet. Add the generated database to the app resources to enable KJV browsing and lookup."
            )
        }

        var database: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let database else {
            sqlite3_close(database)
            throw ScriptureProviderError.databaseOpenFailed
        }

        defer { sqlite3_close(database) }
        return try work(database)
    }

    private func prepareStatement(_ sql: String, database: OpaquePointer) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            let message = sqlite3_errmsg(database).map { String(cString: $0) } ?? "Unknown SQLite error"
            throw ScriptureProviderError.queryFailed(message)
        }

        return statement
    }

    private func stringValue(from statement: OpaquePointer, column: Int32) -> String {
        guard let rawValue = sqlite3_column_text(statement, column) else {
            return ""
        }

        return String(cString: rawValue)
    }

    private static func databaseURL(bundle: Bundle = .main) -> URL? {
        if bundle == .main, let cachedDatabaseURL {
            return cachedDatabaseURL
        }

        if let directMatch = bundle.url(forResource: "KJV", withExtension: "sqlite") {
            cacheDatabaseURLIfNeeded(directMatch, bundle: bundle)
            return directMatch
        }

        if let flatMatch = bundle
            .urls(forResourcesWithExtension: "sqlite", subdirectory: nil)?
            .first(where: { $0.lastPathComponent == "KJV.sqlite" })
        {
            cacheDatabaseURLIfNeeded(flatMatch, bundle: bundle)
            return flatMatch
        }

        guard let resourceURL = bundle.resourceURL else {
            return nil
        }

        let resolvedURL = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .first(where: { $0.lastPathComponent == "KJV.sqlite" })

        cacheDatabaseURLIfNeeded(resolvedURL, bundle: bundle)
        return resolvedURL
    }

    private static func cacheDatabaseURLIfNeeded(_ url: URL?, bundle: Bundle) {
        guard bundle == .main else {
            return
        }

        cachedDatabaseURL = url
    }

    private static var cachedDatabaseURL: URL?
}
