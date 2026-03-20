import Foundation

struct Verse: Identifiable, Codable, Hashable {
    let id: UUID
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

    var progressText: String {
        if isMastered {
            return "Mastered"
        }

        return "\(correctCount)/\(Self.masteryGoal) correct"
    }

    var progressValue: Double {
        min(Double(correctCount) / Double(Self.masteryGoal), 1.0)
    }
}
