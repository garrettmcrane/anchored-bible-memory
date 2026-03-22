import Foundation

enum GroupVerseProgressStatus: String, Codable {
    case practicing
    case memorized

    var title: String {
        switch self {
        case .practicing:
            return "Practicing"
        case .memorized:
            return "Memorized"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.practicing.rawValue, "notStarted", "inProgress":
            self = .practicing
        case Self.memorized.rawValue, "mastered":
            self = .memorized
        default:
            self = .practicing
        }
    }
}

struct GroupVerseProgress: Equatable {
    var verseID: String
    var status: GroupVerseProgressStatus
    var reviewCount: Int
    var lastReviewedAt: Date?
}

struct GroupProgressSummary: Equatable {
    var totalAssignedCount: Int
    var practicingCount: Int
    var memorizedCount: Int
}
