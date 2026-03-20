import Foundation

struct ScripturePassageSegment: Identifiable, Hashable, Codable {
    let reference: String
    let text: String

    var id: String {
        reference
    }
}

struct ScripturePassage: Identifiable, Hashable, Codable {
    let normalizedReference: String
    let translation: BibleTranslation
    let text: String
    let segments: [ScripturePassageSegment]

    var id: String {
        "\(translation.rawValue)-\(normalizedReference)"
    }
}

struct ScriptureVerse: Identifiable, Hashable {
    let book: BibleBook
    let chapter: Int
    let verse: Int
    let reference: String
    let text: String
    let sortKey: Int

    var id: Int {
        sortKey
    }
}
