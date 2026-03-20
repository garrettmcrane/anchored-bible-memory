import Foundation

struct GroupMembership: Identifiable, Codable, Equatable {
    var id: String
    var groupID: String
    var userID: String
    var role: GroupRole
    var joinedAt: Date
    var isActive: Bool
}
