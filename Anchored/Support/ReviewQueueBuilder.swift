import Foundation

struct ReviewQueueBuilder {
    static let defaultSessionSize = 10

    func buildQueue(from verses: [Verse], sessionSize: Int = defaultSessionSize) -> [Verse] {
        let eligibleVerses = VerseQueries.excludingSoftDeleted(verses).filter {
            $0.ownerUserID == LocalSession.currentUserID && $0.sourceType == .personal
        }

        return Array(eligibleVerses.sorted { VerseStrengthService.reviewPriority($0, $1) }.prefix(sessionSize))
    }
}
