import Foundation

extension Notification.Name {
    static let versesDidChange = Notification.Name("VerseStore.versesDidChange")
}

enum VerseStore {
    nonisolated private static let fileName = "verses.json"
    nonisolated private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cachedVerses: [Verse]?

    nonisolated static var changePublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .versesDidChange)
    }

    nonisolated static func load() -> [Verse] {
        cacheLock.lock()
        if let cachedVerses {
            cacheLock.unlock()
            return cachedVerses
        }
        cacheLock.unlock()

        do {
            let url = try fileURL()

            guard FileManager.default.fileExists(atPath: url.path) else {
                updateCache(with: [])
                return []
            }

            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let verses = try decoder.decode([Verse].self, from: data)
            updateCache(with: verses)
            return verses
        } catch {
            assertionFailure("Failed to load verses: \(error)")
            return []
        }
    }

    static func save(_ verses: [Verse]) {
        do {
            let url = try fileURL()
            try ensureDirectoryExists(for: url)
            let data = try encoder.encode(verses)
            try data.write(to: url, options: .atomic)
            updateCache(with: verses)
            NotificationCenter.default.post(name: .versesDidChange, object: nil)
        } catch {
            assertionFailure("Failed to save verses: \(error)")
        }
    }

    nonisolated private static func updateCache(with verses: [Verse]) {
        cacheLock.lock()
        cachedVerses = verses
        cacheLock.unlock()
    }

    nonisolated private static func fileURL() throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return baseDirectory
            .appendingPathComponent("Anchored", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private static func ensureDirectoryExists(for url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    nonisolated private static let decoder = JSONDecoder()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
