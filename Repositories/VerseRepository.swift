import Foundation

struct VerseRepository {
    static let shared = VerseRepository()

    nonisolated func loadVerses() -> [Verse] {
        let allVerses = VerseStore.load()
        let currentUserVerses = allVerses.filter { $0.ownerUserID == LocalSession.currentUserID }
        return VerseQueries.newestFirst(VerseQueries.excludingSoftDeleted(currentUserVerses))
    }

    nonisolated func loadVersesAsync() async -> [Verse] {
        await Task.detached(priority: .userInitiated) {
            loadVerses()
        }.value
    }

    func addVerse(_ verse: Verse) {
        var allVerses = VerseStore.load()
        allVerses.append(verse)
        VerseStore.save(allVerses)
    }

    func addVerses(_ verses: [Verse]) {
        guard !verses.isEmpty else {
            return
        }

        var allVerses = VerseStore.load()
        allVerses.append(contentsOf: verses)
        VerseStore.save(allVerses)
    }

    func updateVerse(_ verse: Verse) {
        var allVerses = VerseStore.load()

        guard let index = allVerses.firstIndex(where: { $0.id == verse.id }) else {
            allVerses.append(verse)
            VerseStore.save(allVerses)
            return
        }

        var updatedVerse = verse
        updatedVerse.updatedAt = Date()

        if updatedVerse.syncStatus != .localOnly && updatedVerse.syncStatus != .pendingDelete {
            updatedVerse.syncStatus = .pendingUpload
        }

        allVerses[index] = updatedVerse
        VerseStore.save(allVerses)
    }

    func updateMasteryStatus(forVerseID id: String, to status: VerseMasteryStatus) -> Verse? {
        var allVerses = VerseStore.load()

        guard let index = allVerses.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        guard allVerses[index].masteryStatus != status else {
            return allVerses[index]
        }

        allVerses[index].masteryStatus = status
        allVerses[index].updatedAt = Date()

        if allVerses[index].syncStatus != .localOnly && allVerses[index].syncStatus != .pendingDelete {
            allVerses[index].syncStatus = .pendingUpload
        }

        VerseStore.save(allVerses)
        return allVerses[index]
    }

    func updateMasteryStatus(forVerseIDs ids: Set<String>, to status: VerseMasteryStatus) -> [Verse] {
        guard !ids.isEmpty else {
            return []
        }

        var allVerses = VerseStore.load()
        let now = Date()
        var updatedVerses: [Verse] = []

        for index in allVerses.indices where ids.contains(allVerses[index].id) {
            guard allVerses[index].masteryStatus != status else {
                updatedVerses.append(allVerses[index])
                continue
            }

            allVerses[index].masteryStatus = status
            allVerses[index].updatedAt = now

            if allVerses[index].syncStatus != .localOnly && allVerses[index].syncStatus != .pendingDelete {
                allVerses[index].syncStatus = .pendingUpload
            }

            updatedVerses.append(allVerses[index])
        }

        VerseStore.save(allVerses)
        return updatedVerses
    }

    func moveVerse(id: String, toFolder folderName: String) -> Verse? {
        moveVerses(ids: [id], toFolder: folderName).first
    }

    func moveVerses(ids: Set<String>, toFolder folderName: String) -> [Verse] {
        guard !ids.isEmpty else {
            return []
        }

        var allVerses = VerseStore.load()
        let normalizedFolderName = normalizedFolderName(folderName)
        let now = Date()
        var updatedVerses: [Verse] = []

        for index in allVerses.indices where ids.contains(allVerses[index].id) {
            guard allVerses[index].folderName != normalizedFolderName else {
                updatedVerses.append(allVerses[index])
                continue
            }

            allVerses[index].folderName = normalizedFolderName
            allVerses[index].updatedAt = now

            if allVerses[index].syncStatus != .localOnly && allVerses[index].syncStatus != .pendingDelete {
                allVerses[index].syncStatus = .pendingUpload
            }

            updatedVerses.append(allVerses[index])
        }

        VerseStore.save(allVerses)
        return updatedVerses
    }

    func softDeleteVerse(id: String) {
        var allVerses = VerseStore.load()

        guard let index = allVerses.firstIndex(where: { $0.id == id }) else {
            return
        }

        allVerses[index].deletedAt = Date()
        allVerses[index].updatedAt = Date()
        allVerses[index].syncStatus = .pendingDelete
        VerseStore.save(allVerses)
    }

    func softDeleteVerses(ids: Set<String>) {
        guard !ids.isEmpty else {
            return
        }

        var allVerses = VerseStore.load()
        let now = Date()

        for index in allVerses.indices where ids.contains(allVerses[index].id) {
            allVerses[index].deletedAt = now
            allVerses[index].updatedAt = now
            allVerses[index].syncStatus = .pendingDelete
        }

        VerseStore.save(allVerses)
    }

    func verses(inFolder folderName: String) -> [Verse] {
        VerseQueries.newestFirst(VerseQueries.verses(loadVerses(), inFolder: folderName))
    }

    func learningVerses() -> [Verse] {
        VerseQueries.newestFirst(VerseQueries.learningVerses(loadVerses()))
    }

    func memorizedVerses() -> [Verse] {
        VerseQueries.newestFirst(VerseQueries.memorizedVerses(loadVerses()))
    }

    private func normalizedFolderName(_ folderName: String) -> String {
        let normalizedFolderName = ScriptureAddPipeline.normalizedFolderName(folderName)
        return normalizedFolderName.isEmpty ? "Uncategorized" : normalizedFolderName
    }
}
