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

enum ReviewMethod: String, Codable {
    case flashcard
    case progressiveReveal
    case firstLetter
    case listening
    case voice
}

enum ReviewResult: String, Codable {
    case correct
    case missed
}
