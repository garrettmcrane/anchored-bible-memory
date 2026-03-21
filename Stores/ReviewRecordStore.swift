import Foundation

enum ReviewRecordStore {
    nonisolated private static let fileName = "review-records.json"
    nonisolated private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cachedRecords: [ReviewRecord]?

    nonisolated static func load() -> [ReviewRecord] {
        cacheLock.lock()
        if let cachedRecords {
            cacheLock.unlock()
            return cachedRecords
        }
        cacheLock.unlock()

        do {
            let url = try fileURL()

            guard FileManager.default.fileExists(atPath: url.path) else {
                updateCache(with: [])
                return []
            }

            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let records = try decoder.decode([ReviewRecord].self, from: data)
            updateCache(with: records)
            return records
        } catch {
            assertionFailure("Failed to load review records: \(error)")
            return []
        }
    }

    static func save(_ records: [ReviewRecord]) {
        do {
            let url = try fileURL()
            try ensureDirectoryExists(for: url)
            let data = try encoder.encode(records)
            try data.write(to: url, options: .atomic)
            updateCache(with: records)
        } catch {
            assertionFailure("Failed to save review records: \(error)")
        }
    }

    nonisolated static func loadAsync() async -> [ReviewRecord] {
        await Task.detached(priority: .utility) {
            load()
        }.value
    }

    nonisolated private static func updateCache(with records: [ReviewRecord]) {
        cacheLock.lock()
        cachedRecords = records
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
