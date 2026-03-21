import Foundation

enum UserSettingsStore {
    private static let fileName = "user-settings.json"
    private static let cacheLock = NSLock()
    private static var cachedSettings: UserSettings?

    static func load() -> UserSettings {
        cacheLock.lock()
        if let cachedSettings {
            cacheLock.unlock()
            return cachedSettings
        }
        cacheLock.unlock()

        do {
            let url = try fileURL()

            guard FileManager.default.fileExists(atPath: url.path) else {
                let settings = UserSettings.default()
                updateCache(with: settings)
                return settings
            }

            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let settings = try decoder.decode(UserSettings.self, from: data)
            updateCache(with: settings)
            return settings
        } catch {
            assertionFailure("Failed to load user settings: \(error)")
            return UserSettings.default()
        }
    }

    static func save(_ settings: UserSettings) {
        do {
            let url = try fileURL()
            try ensureDirectoryExists(for: url)
            let data = try encoder.encode(settings)
            try data.write(to: url, options: .atomic)
            updateCache(with: settings)
        } catch {
            assertionFailure("Failed to save user settings: \(error)")
        }
    }

    private static func updateCache(with settings: UserSettings) {
        cacheLock.lock()
        cachedSettings = settings
        cacheLock.unlock()
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
