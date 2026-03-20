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

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .flashcard:
            return "Flashcard"
        case .progressiveWordHiding:
            return "Progressive Word Hiding"
        }
    }

    var promptDescription: String {
        switch self {
        case .flashcard:
            return "Recite first, then reveal and score."
        case .progressiveWordHiding:
            return "Start with the full verse and hide more words as you go."
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.flashcard.rawValue, "firstLetter", "listening", "voice":
            self = .flashcard
        case Self.progressiveWordHiding.rawValue, "progressiveReveal":
            self = .progressiveWordHiding
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

enum UrgencyLevel {
    case fresh
    case atRisk
    case needsReview
}
