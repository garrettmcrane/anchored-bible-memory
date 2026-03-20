import Foundation

struct AppUser: Identifiable, Codable, Equatable {
    var id: String
    var email: String?
    var displayName: String?
    var createdAt: Date
    var updatedAt: Date
}
