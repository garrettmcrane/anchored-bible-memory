import Foundation

struct ReviewQueueBuilder {
    static let defaultSessionSize = 10

    func buildPracticingQueue(from verses: [Verse], sessionSize: Int = defaultSessionSize) -> [Verse] {
        let eligibleVerses = VerseQueries.excludingSoftDeleted(verses).filter {
            $0.ownerUserID == LocalSession.currentUserID && $0.sourceType == .personal
        }

        return Array(
            VerseQueries.practicingVerses(eligibleVerses)
                .sorted { VerseStrengthService.reviewPriority($0, $1) }
                .prefix(sessionSize)
        )
    }

    func buildAllQueue(from verses: [Verse], sessionSize: Int? = nil) -> [Verse] {
        let eligibleVerses = VerseQueries.excludingSoftDeleted(verses).filter {
            $0.ownerUserID == LocalSession.currentUserID && $0.sourceType == .personal
        }
        let sortedVerses = eligibleVerses.sorted { VerseStrengthService.reviewPriority($0, $1) }

        guard let sessionSize else {
            return sortedVerses
        }

        return Array(sortedVerses.prefix(sessionSize))
    }
}
