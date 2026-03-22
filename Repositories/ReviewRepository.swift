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
        appendReviewRecord(
            for: verse,
            method: method,
            result: result,
            groupID: groupID,
            reviewedAt: reviewedAt,
            durationSeconds: durationSeconds
        )

        var updatedVerse = verse
        updatedVerse.reviewCount += 1
        updatedVerse.strength = VerseStrengthService.updatedStoredStrength(for: verse, result: result, reviewedAt: reviewedAt)
        updatedVerse.lastReviewedAt = reviewedAt
        updatedVerse.updatedAt = reviewedAt
        updatedVerse.masteryStatus = result == .correct ? .memorized : .practicing

        switch result {
        case .correct:
            updatedVerse.correctCount += 1
        case .missed:
            updatedVerse.correctCount = 0
        }

        if updatedVerse.syncStatus != .localOnly && updatedVerse.syncStatus != .pendingDelete {
            updatedVerse.syncStatus = .pendingUpload
        }

        VerseRepository.shared.updateVerse(updatedVerse)
        return updatedVerse
    }

    func recordGroupReview(
        for verse: Verse,
        groupID: String,
        method: ReviewMethod,
        result: ReviewResult,
        durationSeconds: Int? = nil
    ) {
        appendReviewRecord(
            for: verse,
            method: method,
            result: result,
            groupID: groupID,
            reviewedAt: Date(),
            durationSeconds: durationSeconds
        )
    }

    private func appendReviewRecord(
        for verse: Verse,
        method: ReviewMethod,
        result: ReviewResult,
        groupID: String?,
        reviewedAt: Date,
        durationSeconds: Int?
    ) {
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
    }
}
