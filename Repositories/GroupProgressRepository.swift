import Foundation

struct GroupProgressRepository {
    static let shared = GroupProgressRepository()

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
            practicingCount: progressValues.filter { $0.status == .practicing }.count,
            memorizedCount: progressValues.filter { $0.status == .memorized }.count
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
                status: .practicing,
                reviewCount: 0,
                lastReviewedAt: nil
            )
        }

        let latestResult = records.last?.result ?? .missed
        let status: GroupVerseProgressStatus = latestResult == .correct ? .memorized : .practicing

        return GroupVerseProgress(
            verseID: verseID,
            status: status,
            reviewCount: records.count,
            lastReviewedAt: records.last?.reviewedAt
        )
    }
}
