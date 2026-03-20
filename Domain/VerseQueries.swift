import Foundation

enum VerseQueries {
    static func excludingSoftDeleted(_ verses: [Verse]) -> [Verse] {
        verses.filter { $0.deletedAt == nil }
    }

    static func newestFirst(_ verses: [Verse]) -> [Verse] {
        verses.sorted { $0.createdAt > $1.createdAt }
    }

    static func learningVerses(_ verses: [Verse]) -> [Verse] {
        excludingSoftDeleted(verses).filter { !$0.isMastered }
    }

    static func memorizedVerses(_ verses: [Verse]) -> [Verse] {
        excludingSoftDeleted(verses).filter(\.isMastered)
    }

    static func verses(_ verses: [Verse], inFolder folderName: String) -> [Verse] {
        excludingSoftDeleted(verses).filter { $0.folderName == folderName }
    }
}
