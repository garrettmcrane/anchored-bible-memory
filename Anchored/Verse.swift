import Foundation
import SwiftData

@Model
final class Verse {
    var id: UUID
    var reference: String
    var text: String
    var isMastered: Bool
    var correctCount: Int

    static let masteryGoal = 3

    init(
        id: UUID = UUID(),
        reference: String,
        text: String,
        isMastered: Bool = false,
        correctCount: Int = 0
    ) {
        self.id = id
        self.reference = reference
        self.text = text
        self.isMastered = isMastered
        self.correctCount = correctCount
    }

    var progress: Double {
        Double(correctCount) / Double(Self.masteryGoal)
    }

    var progressText: String {
        "\(correctCount)/\(Self.masteryGoal)"
    }
}
