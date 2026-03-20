import Foundation

struct BibleBook: Identifiable, Hashable, Codable {
    let id: Int
    let abbreviation: String
    let name: String
    let sortOrder: Int
    let testament: String
}

enum BibleBookCatalog {
    static let books: [BibleBook] = [
        BibleBook(id: 1, abbreviation: "Gen", name: "Genesis", sortOrder: 1, testament: "OT"),
        BibleBook(id: 2, abbreviation: "Exod", name: "Exodus", sortOrder: 2, testament: "OT"),
        BibleBook(id: 3, abbreviation: "Lev", name: "Leviticus", sortOrder: 3, testament: "OT"),
        BibleBook(id: 4, abbreviation: "Num", name: "Numbers", sortOrder: 4, testament: "OT"),
        BibleBook(id: 5, abbreviation: "Deut", name: "Deuteronomy", sortOrder: 5, testament: "OT"),
        BibleBook(id: 6, abbreviation: "Josh", name: "Joshua", sortOrder: 6, testament: "OT"),
        BibleBook(id: 7, abbreviation: "Judg", name: "Judges", sortOrder: 7, testament: "OT"),
        BibleBook(id: 8, abbreviation: "Ruth", name: "Ruth", sortOrder: 8, testament: "OT"),
        BibleBook(id: 9, abbreviation: "1 Sam", name: "1 Samuel", sortOrder: 9, testament: "OT"),
        BibleBook(id: 10, abbreviation: "2 Sam", name: "2 Samuel", sortOrder: 10, testament: "OT"),
        BibleBook(id: 11, abbreviation: "1 Kgs", name: "1 Kings", sortOrder: 11, testament: "OT"),
        BibleBook(id: 12, abbreviation: "2 Kgs", name: "2 Kings", sortOrder: 12, testament: "OT"),
        BibleBook(id: 13, abbreviation: "1 Chr", name: "1 Chronicles", sortOrder: 13, testament: "OT"),
        BibleBook(id: 14, abbreviation: "2 Chr", name: "2 Chronicles", sortOrder: 14, testament: "OT"),
        BibleBook(id: 15, abbreviation: "Ezra", name: "Ezra", sortOrder: 15, testament: "OT"),
        BibleBook(id: 16, abbreviation: "Neh", name: "Nehemiah", sortOrder: 16, testament: "OT"),
        BibleBook(id: 17, abbreviation: "Esth", name: "Esther", sortOrder: 17, testament: "OT"),
        BibleBook(id: 18, abbreviation: "Job", name: "Job", sortOrder: 18, testament: "OT"),
        BibleBook(id: 19, abbreviation: "Ps", name: "Psalms", sortOrder: 19, testament: "OT"),
        BibleBook(id: 20, abbreviation: "Prov", name: "Proverbs", sortOrder: 20, testament: "OT"),
        BibleBook(id: 21, abbreviation: "Eccl", name: "Ecclesiastes", sortOrder: 21, testament: "OT"),
        BibleBook(id: 22, abbreviation: "Song", name: "Song of Solomon", sortOrder: 22, testament: "OT"),
        BibleBook(id: 23, abbreviation: "Isa", name: "Isaiah", sortOrder: 23, testament: "OT"),
        BibleBook(id: 24, abbreviation: "Jer", name: "Jeremiah", sortOrder: 24, testament: "OT"),
        BibleBook(id: 25, abbreviation: "Lam", name: "Lamentations", sortOrder: 25, testament: "OT"),
        BibleBook(id: 26, abbreviation: "Ezek", name: "Ezekiel", sortOrder: 26, testament: "OT"),
        BibleBook(id: 27, abbreviation: "Dan", name: "Daniel", sortOrder: 27, testament: "OT"),
        BibleBook(id: 28, abbreviation: "Hos", name: "Hosea", sortOrder: 28, testament: "OT"),
        BibleBook(id: 29, abbreviation: "Joel", name: "Joel", sortOrder: 29, testament: "OT"),
        BibleBook(id: 30, abbreviation: "Amos", name: "Amos", sortOrder: 30, testament: "OT"),
        BibleBook(id: 31, abbreviation: "Obad", name: "Obadiah", sortOrder: 31, testament: "OT"),
        BibleBook(id: 32, abbreviation: "Jonah", name: "Jonah", sortOrder: 32, testament: "OT"),
        BibleBook(id: 33, abbreviation: "Mic", name: "Micah", sortOrder: 33, testament: "OT"),
        BibleBook(id: 34, abbreviation: "Nah", name: "Nahum", sortOrder: 34, testament: "OT"),
        BibleBook(id: 35, abbreviation: "Hab", name: "Habakkuk", sortOrder: 35, testament: "OT"),
        BibleBook(id: 36, abbreviation: "Zeph", name: "Zephaniah", sortOrder: 36, testament: "OT"),
        BibleBook(id: 37, abbreviation: "Hag", name: "Haggai", sortOrder: 37, testament: "OT"),
        BibleBook(id: 38, abbreviation: "Zech", name: "Zechariah", sortOrder: 38, testament: "OT"),
        BibleBook(id: 39, abbreviation: "Mal", name: "Malachi", sortOrder: 39, testament: "OT"),
        BibleBook(id: 40, abbreviation: "Matt", name: "Matthew", sortOrder: 40, testament: "NT"),
        BibleBook(id: 41, abbreviation: "Mark", name: "Mark", sortOrder: 41, testament: "NT"),
        BibleBook(id: 42, abbreviation: "Luke", name: "Luke", sortOrder: 42, testament: "NT"),
        BibleBook(id: 43, abbreviation: "John", name: "John", sortOrder: 43, testament: "NT"),
        BibleBook(id: 44, abbreviation: "Acts", name: "Acts", sortOrder: 44, testament: "NT"),
        BibleBook(id: 45, abbreviation: "Rom", name: "Romans", sortOrder: 45, testament: "NT"),
        BibleBook(id: 46, abbreviation: "1 Cor", name: "1 Corinthians", sortOrder: 46, testament: "NT"),
        BibleBook(id: 47, abbreviation: "2 Cor", name: "2 Corinthians", sortOrder: 47, testament: "NT"),
        BibleBook(id: 48, abbreviation: "Gal", name: "Galatians", sortOrder: 48, testament: "NT"),
        BibleBook(id: 49, abbreviation: "Eph", name: "Ephesians", sortOrder: 49, testament: "NT"),
        BibleBook(id: 50, abbreviation: "Phil", name: "Philippians", sortOrder: 50, testament: "NT"),
        BibleBook(id: 51, abbreviation: "Col", name: "Colossians", sortOrder: 51, testament: "NT"),
        BibleBook(id: 52, abbreviation: "1 Thess", name: "1 Thessalonians", sortOrder: 52, testament: "NT"),
        BibleBook(id: 53, abbreviation: "2 Thess", name: "2 Thessalonians", sortOrder: 53, testament: "NT"),
        BibleBook(id: 54, abbreviation: "1 Tim", name: "1 Timothy", sortOrder: 54, testament: "NT"),
        BibleBook(id: 55, abbreviation: "2 Tim", name: "2 Timothy", sortOrder: 55, testament: "NT"),
        BibleBook(id: 56, abbreviation: "Titus", name: "Titus", sortOrder: 56, testament: "NT"),
        BibleBook(id: 57, abbreviation: "Phlm", name: "Philemon", sortOrder: 57, testament: "NT"),
        BibleBook(id: 58, abbreviation: "Heb", name: "Hebrews", sortOrder: 58, testament: "NT"),
        BibleBook(id: 59, abbreviation: "Jas", name: "James", sortOrder: 59, testament: "NT"),
        BibleBook(id: 60, abbreviation: "1 Pet", name: "1 Peter", sortOrder: 60, testament: "NT"),
        BibleBook(id: 61, abbreviation: "2 Pet", name: "2 Peter", sortOrder: 61, testament: "NT"),
        BibleBook(id: 62, abbreviation: "1 John", name: "1 John", sortOrder: 62, testament: "NT"),
        BibleBook(id: 63, abbreviation: "2 John", name: "2 John", sortOrder: 63, testament: "NT"),
        BibleBook(id: 64, abbreviation: "3 John", name: "3 John", sortOrder: 64, testament: "NT"),
        BibleBook(id: 65, abbreviation: "Jude", name: "Jude", sortOrder: 65, testament: "NT"),
        BibleBook(id: 66, abbreviation: "Rev", name: "Revelation", sortOrder: 66, testament: "NT")
    ]

    private static let numberWordVariants: [String: [String]] = [
        "1": ["1", "1st", "first", "i"],
        "2": ["2", "2nd", "second", "ii"],
        "3": ["3", "3rd", "third", "iii"]
    ]

    static let aliasMap: [String: BibleBook] = {
        var map: [String: BibleBook] = [:]

        for book in books {
            for alias in aliases(for: book) {
                map[normalize(alias)] = book
            }
        }

        map[normalize("psalm")] = books[18]
        map[normalize("ps")] = books[18]
        map[normalize("song of songs")] = books[21]
        map[normalize("song")] = books[21]

        return map
    }()

    static let sortedAliases: [String] = aliasMap.keys.sorted {
        if $0.count == $1.count {
            return $0 < $1
        }

        return $0.count > $1.count
    }

    static func book(for name: String) -> BibleBook? {
        aliasMap[normalize(name)]
    }

    static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func aliases(for book: BibleBook) -> Set<String> {
        var values: Set<String> = [
            book.name,
            book.abbreviation
        ]

        values.insert(book.name.replacingOccurrences(of: " ", with: ""))
        values.insert(book.abbreviation.replacingOccurrences(of: " ", with: ""))

        if let firstWord = book.name.split(separator: " ").first, Int(firstWord) == nil {
            values.insert(String(firstWord))
        }

        if let firstWord = book.abbreviation.split(separator: " ").first, Int(firstWord) == nil {
            values.insert(String(firstWord))
        }

        if let generated = generateNumberedAliases(for: book.name) {
            values.formUnion(generated)
        }

        if let generated = generateNumberedAliases(for: book.abbreviation) {
            values.formUnion(generated)
        }

        return values
    }

    private static func generateNumberedAliases(for source: String) -> Set<String>? {
        let parts = source.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2 else {
            return nil
        }

        let prefix = String(parts[0])
        guard let variants = numberWordVariants[prefix] else {
            return nil
        }

        let remainder = String(parts[1])
        var generated: Set<String> = []

        for variant in variants {
            generated.insert("\(variant) \(remainder)")
            generated.insert("\(variant)\(remainder.replacingOccurrences(of: " ", with: ""))")
        }

        return generated
    }
}
