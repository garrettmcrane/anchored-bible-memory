import Foundation

struct VerseRepository {
    static let shared = VerseRepository()

    func loadVerses() -> [Verse] {
        let allVerses = VerseStore.load()
        let currentUserVerses = allVerses.filter { $0.ownerUserID == LocalSession.currentUserID }
        return VerseQueries.newestFirst(VerseQueries.excludingSoftDeleted(currentUserVerses))
    }

    func addVerse(_ verse: Verse) {
        var allVerses = VerseStore.load()
        allVerses.append(verse)
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

    func verses(inFolder folderName: String) -> [Verse] {
        VerseQueries.newestFirst(VerseQueries.verses(loadVerses(), inFolder: folderName))
    }

    func learningVerses() -> [Verse] {
        VerseQueries.newestFirst(VerseQueries.learningVerses(loadVerses()))
    }

    func memorizedVerses() -> [Verse] {
        VerseQueries.newestFirst(VerseQueries.memorizedVerses(loadVerses()))
    }
}
