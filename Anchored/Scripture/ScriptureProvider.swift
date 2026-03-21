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
            return "The Bible text couldn't be opened right now."
        case .queryFailed(let message):
            return message
        case .verseNotFound(let reference):
            return "We couldn't find a passage for \(reference)."
        case .unsupportedReference(let reference):
            return "That reference isn't supported yet: \(reference)"
        }
    }
}
