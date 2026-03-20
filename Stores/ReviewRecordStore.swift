import Foundation

enum ReviewRecordStore {
    private static let fileName = "review-records.json"

    static func load() -> [ReviewRecord] {
        do {
            let url = try fileURL()

            guard FileManager.default.fileExists(atPath: url.path) else {
                return []
            }

            let data = try Data(contentsOf: url)
            return try decoder.decode([ReviewRecord].self, from: data)
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
        } catch {
            assertionFailure("Failed to save review records: \(error)")
        }
    }

    private static func fileURL() throws -> URL {
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

    private static let decoder = JSONDecoder()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
