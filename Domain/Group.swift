import Foundation

struct Group: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var ownerUserID: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
}
