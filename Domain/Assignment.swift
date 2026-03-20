import Foundation

struct Assignment: Identifiable, Codable, Equatable {
    var id: String
    var groupID: String
    var verseID: String
    var assignedByUserID: String
    var assignedAt: Date
    var dueAt: Date?
    var isArchived: Bool
}
