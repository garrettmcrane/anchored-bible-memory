import Foundation

enum ScriptureReferenceKind: String, Codable {
    case singleVerse
    case verseRange
    case chapter
}

struct ScriptureReference: Identifiable, Hashable, Codable {
    let book: BibleBook
    let startChapter: Int
    let startVerse: Int?
    let endChapter: Int?
    let endVerse: Int?
    let kind: ScriptureReferenceKind
    let normalizedReference: String

    var id: String {
        normalizedReference
    }
}
