import Foundation

struct ReviewRecord: Identifiable, Codable, Equatable {
    var id: String
    var verseID: String
    var userID: String
    var groupID: String?
    var method: ReviewMethod
    var result: ReviewResult
    var reviewedAt: Date
    var durationSeconds: Int?
}
