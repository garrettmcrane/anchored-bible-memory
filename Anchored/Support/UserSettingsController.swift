import Combine
import SwiftUI

@MainActor
final class UserSettingsController: ObservableObject {
    @Published private(set) var settings: UserSettings

    private let repository: UserSettingsRepository

    init() {
        repository = .shared
        settings = repository.loadSettings()
    }

    var preferredColorScheme: ColorScheme? {
        switch settings.preferredAppearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func updateAppearance(_ appearance: AppAppearancePreference) {
        guard settings.preferredAppearance != appearance else {
            return
        }

        var updatedSettings = settings
        updatedSettings.preferredAppearance = appearance
        updatedSettings.updatedAt = Date()
        repository.save(updatedSettings)
        settings = updatedSettings
    }
}
