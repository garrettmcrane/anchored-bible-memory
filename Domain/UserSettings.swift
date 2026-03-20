import Foundation

struct UserSettings: Identifiable, Codable, Equatable {
    var id: String
    var userID: String
    var translationCode: String
    var createdAt: Date
    var updatedAt: Date
}
