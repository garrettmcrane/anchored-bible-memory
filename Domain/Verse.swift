import Foundation

struct Verse: Identifiable, Codable, Equatable {
    var id: String
    var reference: String
    var text: String
    var folderName: String
    var isMastered: Bool
    var correctCount: Int
    var reviewCount: Int
    var createdAt: Date
    var updatedAt: Date
    var lastReviewedAt: Date?
    var ownerUserID: String
    var sourceType: VerseSourceType
    var syncStatus: SyncStatus
    var deletedAt: Date?

    static let masteryGoal = 3

    init(
        id: String = UUID().uuidString,
        reference: String,
        text: String,
        folderName: String = "General",
        isMastered: Bool = false,
        correctCount: Int = 0,
        reviewCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        ownerUserID: String = LocalSession.currentUserID,
        sourceType: VerseSourceType = .personal,
        syncStatus: SyncStatus = .localOnly,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.reference = reference
        self.text = text
        self.folderName = folderName
        self.isMastered = isMastered
        self.correctCount = correctCount
        self.reviewCount = reviewCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastReviewedAt = lastReviewedAt
        self.ownerUserID = ownerUserID
        self.sourceType = sourceType
        self.syncStatus = syncStatus
        self.deletedAt = deletedAt
    }

    var progress: Double {
        Double(correctCount) / Double(Self.masteryGoal)
    }

    var progressText: String {
        "\(correctCount)/\(Self.masteryGoal)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case reference
        case text
        case folderName
        case isMastered
        case correctCount
        case reviewCount
        case createdAt
        case updatedAt
        case lastReviewedAt
        case ownerUserID
        case sourceType
        case syncStatus
        case deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)

        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else {
            let uuidID = try container.decode(UUID.self, forKey: .id)
            id = uuidID.uuidString
        }

        reference = try container.decode(String.self, forKey: .reference)
        text = try container.decode(String.self, forKey: .text)
        folderName = try container.decodeIfPresent(String.self, forKey: .folderName) ?? "General"
        isMastered = try container.decodeIfPresent(Bool.self, forKey: .isMastered) ?? false
        correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        self.createdAt = createdAt
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        ownerUserID = try container.decodeIfPresent(String.self, forKey: .ownerUserID) ?? LocalSession.currentUserID
        sourceType = try container.decodeIfPresent(VerseSourceType.self, forKey: .sourceType) ?? .personal
        syncStatus = try container.decodeIfPresent(SyncStatus.self, forKey: .syncStatus) ?? .localOnly
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}
