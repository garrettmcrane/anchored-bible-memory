import Foundation

struct ReviewRepository {
    static let shared = ReviewRepository()

    func recordReview(
        for verse: Verse,
        method: ReviewMethod,
        result: ReviewResult,
        groupID: String? = nil,
        durationSeconds: Int? = nil
    ) -> Verse {
        let reviewedAt = Date()

        let record = ReviewRecord(
            id: UUID().uuidString,
            verseID: verse.id,
            userID: LocalSession.currentUserID,
            groupID: groupID,
            method: method,
            result: result,
            reviewedAt: reviewedAt,
            durationSeconds: durationSeconds
        )

        var records = ReviewRecordStore.load()
        records.append(record)
        ReviewRecordStore.save(records)

        var updatedVerse = verse
        updatedVerse.reviewCount += 1
        updatedVerse.lastReviewedAt = reviewedAt
        updatedVerse.updatedAt = reviewedAt

        switch result {
        case .correct:
            updatedVerse.correctCount += 1
            updatedVerse.isMastered = updatedVerse.correctCount >= Verse.masteryGoal
        case .missed:
            updatedVerse.correctCount = 0
            updatedVerse.isMastered = false
        }

        if updatedVerse.syncStatus != .localOnly && updatedVerse.syncStatus != .pendingDelete {
            updatedVerse.syncStatus = .pendingUpload
        }

        VerseRepository.shared.updateVerse(updatedVerse)
        return updatedVerse
    }
}
