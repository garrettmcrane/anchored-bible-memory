import Foundation

struct ReviewQueueBuilder {
    static let defaultSessionSize = 10

    func buildQueue(from verses: [Verse], sessionSize: Int = defaultSessionSize) -> [Verse] {
        let eligibleVerses = VerseQueries.excludingSoftDeleted(verses).filter {
            $0.ownerUserID == LocalSession.currentUserID && $0.sourceType == .personal
        }

        let needsReview = sortByReviewPriority(
            eligibleVerses.filter { $0.urgencyLevel == .needsReview },
            nilLastReviewedFirst: false
        )
        let atRisk = sortByReviewPriority(
            eligibleVerses.filter { $0.urgencyLevel == .atRisk },
            nilLastReviewedFirst: false
        )
        let learningFresh = sortByReviewPriority(
            eligibleVerses.filter { !$0.isMastered && $0.urgencyLevel == .fresh },
            nilLastReviewedFirst: true
        )
        let masteredFresh = sortByReviewPriority(
            eligibleVerses.filter { $0.isMastered && $0.urgencyLevel == .fresh },
            nilLastReviewedFirst: true
        )

        return Array((needsReview + atRisk + learningFresh + masteredFresh).prefix(sessionSize))
    }

    private func sortByReviewPriority(_ verses: [Verse], nilLastReviewedFirst: Bool) -> [Verse] {
        verses.sorted { lhs, rhs in
            if lhs.lastReviewedAt != rhs.lastReviewedAt {
                switch (lhs.lastReviewedAt, rhs.lastReviewedAt) {
                case let (leftDate?, rightDate?):
                    return leftDate < rightDate
                case (nil, _?):
                    return nilLastReviewedFirst
                case (_?, nil):
                    return !nilLastReviewedFirst
                case (nil, nil):
                    break
                }
            }

            if lhs.correctCount != rhs.correctCount {
                return lhs.correctCount < rhs.correctCount
            }

            return lhs.reference.localizedCaseInsensitiveCompare(rhs.reference) == .orderedAscending
        }
    }
}
