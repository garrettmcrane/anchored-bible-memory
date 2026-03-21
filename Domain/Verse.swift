import Foundation

enum VerseMasteryStatus: String, CaseIterable, Codable, Identifiable {
    case learning = "Learning"
    case memorized = "Memorized"

    var id: String {
        rawValue
    }
}

enum VerseStrengthBand {
    case strong
    case steady
    case warning
    case weak
}

enum VerseStrengthService {
    static let decayWindowDays = 10.0
    static let defaultUnreviewedStrength = 0.3
    static let incorrectReviewStrength = 0.2
    static let correctReviewBoost = 0.4
    static let needsAttentionThreshold = 0.4

    static func currentStrength(for verse: Verse, now: Date = Date(), calendar: Calendar = .current) -> Double {
        guard let lastReviewedAt = verse.lastReviewedAt else {
            return defaultUnreviewedStrength
        }

        let daysSinceReview = max(0, Double(
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastReviewedAt),
                to: calendar.startOfDay(for: now)
            ).day ?? 0
        ))

        return max(0, clampedStrength(verse.strength) - (daysSinceReview / decayWindowDays))
    }

    static func updatedStoredStrength(for verse: Verse, result: ReviewResult, reviewedAt: Date) -> Double {
        switch result {
        case .correct:
            return min(1, currentStrength(for: verse, now: reviewedAt) + correctReviewBoost)
        case .missed:
            return incorrectReviewStrength
        }
    }

    static func needsAttention(for verse: Verse, now: Date = Date()) -> Bool {
        currentStrength(for: verse, now: now) < needsAttentionThreshold
    }

    static func band(for strength: Double) -> VerseStrengthBand {
        switch clampedStrength(strength) {
        case 0.75...1:
            return .strong
        case 0.5..<0.75:
            return .steady
        case 0.25..<0.5:
            return .warning
        default:
            return .weak
        }
    }

    static func reviewPriority(_ lhs: Verse, _ rhs: Verse, now: Date = Date()) -> Bool {
        let lhsStrength = currentStrength(for: lhs, now: now)
        let rhsStrength = currentStrength(for: rhs, now: now)

        if lhsStrength != rhsStrength {
            return lhsStrength < rhsStrength
        }

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
        get { isMastered ? .memorized : .learning }
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
        lastReviewedAt == nil ? VerseStrengthService.defaultUnreviewedStrength : 1
    }
}
