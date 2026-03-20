import Foundation

protocol ScriptureProvider {
    var translation: BibleTranslation { get }

    func fetchPassage(for reference: ScriptureReference) throws -> ScripturePassage
    func fetchPassages(for references: [ScriptureReference]) throws -> [ScripturePassage]
    func browseBooks() throws -> [BibleBook]
    func browseChapters(in book: BibleBook) throws -> [Int]
    func browseVerses(in book: BibleBook, chapter: Int) throws -> [ScriptureVerse]
}

enum ScriptureProviderError: LocalizedError {
    case translationUnavailable(BibleTranslation)
    case databaseMissing(String)
    case databaseOpenFailed
    case queryFailed(String)
    case verseNotFound(String)
    case unsupportedReference(String)

    var errorDescription: String? {
        switch self {
        case .translationUnavailable(let translation):
            return "\(translation.title) is not available yet."
        case .databaseMissing(let message):
            return message
        case .databaseOpenFailed:
            return "The scripture database could not be opened."
        case .queryFailed(let message):
            return message
        case .verseNotFound(let reference):
            return "No passage was found for \(reference)."
        case .unsupportedReference(let reference):
            return "The reference format is not supported yet: \(reference)"
        }
    }
}
