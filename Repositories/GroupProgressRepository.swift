import Foundation

struct GroupProgressRepository {
    static let shared = GroupProgressRepository()

    private let masteredThreshold = 3

    func progressByVerseID(forGroupID groupID: String, verseIDs: [String]) -> [String: GroupVerseProgress] {
        let uniqueVerseIDs = Array(Set(verseIDs))
        let recordsByVerseID = Dictionary(grouping: groupRecords(forGroupID: groupID), by: \.verseID)

        return uniqueVerseIDs.reduce(into: [:]) { result, verseID in
            result[verseID] = progress(forVerseID: verseID, records: recordsByVerseID[verseID] ?? [])
        }
    }

    func summary(forGroupID groupID: String, verseIDs: [String]) -> GroupProgressSummary {
        let progressValues = progressByVerseID(forGroupID: groupID, verseIDs: verseIDs).values

        return GroupProgressSummary(
            totalAssignedCount: Array(Set(verseIDs)).count,
            notStartedCount: progressValues.filter { $0.status == .notStarted }.count,
            inProgressCount: progressValues.filter { $0.status == .inProgress }.count,
            masteredCount: progressValues.filter { $0.status == .mastered }.count
        )
    }

    private func groupRecords(forGroupID groupID: String) -> [ReviewRecord] {
        ReviewRecordStore.load()
            .filter { $0.userID == LocalSession.currentUserID && $0.groupID == groupID }
            .sorted { $0.reviewedAt < $1.reviewedAt }
    }

    private func progress(forVerseID verseID: String, records: [ReviewRecord]) -> GroupVerseProgress {
        guard !records.isEmpty else {
            return GroupVerseProgress(
                verseID: verseID,
                status: .notStarted,
                reviewCount: 0,
                consecutiveCorrectCount: 0,
                lastReviewedAt: nil
            )
        }

        var consecutiveCorrectCount = 0

        for record in records {
            switch record.result {
            case .correct:
                consecutiveCorrectCount += 1
            case .missed:
                consecutiveCorrectCount = 0
            }
        }

        let status: GroupVerseProgressStatus = consecutiveCorrectCount >= masteredThreshold ? .mastered : .inProgress

        return GroupVerseProgress(
            verseID: verseID,
            status: status,
            reviewCount: records.count,
            consecutiveCorrectCount: consecutiveCorrectCount,
            lastReviewedAt: records.last?.reviewedAt
        )
    }
}
