import Foundation
import SwiftData

@Model
final class Verse {
    var id: UUID
    var reference: String
    var text: String

    var isMastered: Bool
    var correctCount: Int

    // NEW FIELDS
    var createdAt: Date
    var lastReviewedAt: Date?
    var reviewCount: Int
    var folderName: String

    static let masteryGoal = 3

    init(
        id: UUID = UUID(),
        reference: String,
        text: String,
        isMastered: Bool = false,
        correctCount: Int = 0,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        reviewCount: Int = 0,
        folderName: String = "General"
    ) {
        self.id = id
        self.reference = reference
        self.text = text
        self.isMastered = isMastered
        self.correctCount = correctCount

        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.reviewCount = reviewCount
        self.folderName = folderName
    }

    var progress: Double {
        Double(correctCount) / Double(Self.masteryGoal)
    }

    var progressText: String {
        "\(correctCount)/\(Self.masteryGoal)"
    }
}
