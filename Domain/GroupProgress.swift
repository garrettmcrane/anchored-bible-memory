import Foundation

enum GroupVerseProgressStatus: String, Codable {
    case notStarted
    case inProgress
    case mastered

    var title: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .mastered:
            return "Mastered"
        }
    }
}

struct GroupVerseProgress: Equatable {
    var verseID: String
    var status: GroupVerseProgressStatus
    var reviewCount: Int
    var consecutiveCorrectCount: Int
    var lastReviewedAt: Date?
}

struct GroupProgressSummary: Equatable {
    var totalAssignedCount: Int
    var notStartedCount: Int
    var inProgressCount: Int
    var masteredCount: Int
}
