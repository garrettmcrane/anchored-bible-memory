import Foundation

enum VerseMasteryStatus: String, CaseIterable, Codable, Identifiable {
    case practicing = "Practicing"
    case memorized = "Memorized"

    var id: String {
        rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.practicing.rawValue, "Learning":
            self = .practicing
        case Self.memorized.rawValue:
            self = .memorized
        default:
            self = .practicing
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum VerseStrengthService {
    static let practicingStrength = 0.0
    static let memorizedStrength = 1.0

    static func updatedStoredStrength(for verse: Verse, result: ReviewResult, reviewedAt: Date) -> Double {
        switch result {
        case .correct:
            return memorizedStrength
        case .missed:
            return practicingStrength
        }
    }

    static func reviewPriority(_ lhs: Verse, _ rhs: Verse, now: Date = Date()) -> Bool {
        if lhs.isMastered != rhs.isMastered {
            return !lhs.isMastered
        }

        switch (lhs.lastReviewedAt, rhs.lastReviewedAt) {
        case (nil, nil):
            break
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return lhsDate < rhsDate
        default:
            break
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
    }

    static func clampedStrength(_ strength: Double) -> Double {
        min(max(strength, 0), 1)
    }
}

struct Verse: Identifiable, Codable, Equatable {
    var id: String
    var reference: String
    var text: String
    var folderName: String
    var strength: Double
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

    init(
        id: String = UUID().uuidString,
        reference: String,
        text: String,
        folderName: String = "General",
        strength: Double? = nil,
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
        self.strength = strength.map { VerseStrengthService.clampedStrength($0) } ?? Self.defaultStrength(lastReviewedAt: lastReviewedAt)
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

    var masteryStatus: VerseMasteryStatus {
        get { isMastered ? .memorized : .practicing }
        set { isMastered = newValue == .memorized }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case reference
        case text
        case folderName
        case strength
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
        let decodedLastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        strength = VerseStrengthService.clampedStrength(
            try container.decodeIfPresent(Double.self, forKey: .strength) ?? Self.defaultStrength(lastReviewedAt: decodedLastReviewedAt)
        )
        isMastered = try container.decodeIfPresent(Bool.self, forKey: .isMastered) ?? false
        correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        self.createdAt = createdAt
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        lastReviewedAt = decodedLastReviewedAt
        ownerUserID = try container.decodeIfPresent(String.self, forKey: .ownerUserID) ?? LocalSession.currentUserID
        sourceType = try container.decodeIfPresent(VerseSourceType.self, forKey: .sourceType) ?? .personal
        syncStatus = try container.decodeIfPresent(SyncStatus.self, forKey: .syncStatus) ?? .localOnly
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }

    private static func defaultStrength(lastReviewedAt: Date?) -> Double {
        lastReviewedAt == nil ? VerseStrengthService.practicingStrength : VerseStrengthService.memorizedStrength
    }
}
