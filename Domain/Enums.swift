import Foundation

enum VerseSourceType: String, Codable {
    case personal
    case groupAssignment
    case starter
    case curated
}

enum SyncStatus: String, Codable {
    case localOnly
    case pendingUpload
    case synced
    case pendingDelete
    case syncError
}

enum GroupRole: String, Codable {
    case owner
    case admin
    case member
}

enum ReviewMethod: String, Codable, CaseIterable, Identifiable {
    case flashcard
    case progressiveWordHiding
    case firstLetterTyping
    case voiceRecitation

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .flashcard:
            return "Flashcard"
        case .progressiveWordHiding:
            return "Progressive Word Hiding"
        case .firstLetterTyping:
            return "First-Letter Typing"
        case .voiceRecitation:
            return "Voice Recitation"
        }
    }

    var promptDescription: String {
        switch self {
        case .flashcard:
            return "Recite first, then reveal and score."
        case .progressiveWordHiding:
            return "Start with the full verse and hide more words as you go."
        case .firstLetterTyping:
            return "Type the verse from memory with first-letter prompts as your guide."
        case .voiceRecitation:
            return "Hear the reference, recite aloud, review the transcript, and score it manually."
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.flashcard.rawValue, "listening", "voice":
            self = .flashcard
        case Self.progressiveWordHiding.rawValue, "progressiveReveal":
            self = .progressiveWordHiding
        case Self.firstLetterTyping.rawValue, "firstLetter":
            self = .firstLetterTyping
        case Self.voiceRecitation.rawValue, "voiceRecitationV1":
            self = .voiceRecitation
        default:
            self = .flashcard
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum ReviewResult: String, Codable {
    case correct
    case missed
}
