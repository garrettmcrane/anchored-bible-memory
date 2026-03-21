import Foundation

struct UserSettingsRepository {
    static let shared = UserSettingsRepository()

    func loadSettings() -> UserSettings {
        UserSettingsStore.load()
    }

    func save(_ settings: UserSettings) {
        UserSettingsStore.save(settings)
    }
}
