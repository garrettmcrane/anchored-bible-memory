import Foundation

enum AppAppearancePreference: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

struct UserSettings: Identifiable, Codable, Equatable {
    var id: String
    var userID: String
    var translationCode: String
    var preferredAppearance: AppAppearancePreference
    var createdAt: Date
    var updatedAt: Date

    var selectedTranslation: BibleTranslation {
        BibleTranslation(rawValue: translationCode) ?? .kjv
    }

    init(
        id: String,
        userID: String,
        translationCode: String,
        preferredAppearance: AppAppearancePreference = .system,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.translationCode = translationCode
        self.preferredAppearance = preferredAppearance
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userID = try container.decode(String.self, forKey: .userID)
        translationCode = try container.decodeIfPresent(String.self, forKey: .translationCode) ?? BibleTranslation.kjv.rawValue
        preferredAppearance = try container.decodeIfPresent(AppAppearancePreference.self, forKey: .preferredAppearance) ?? .system
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    static func `default`(for userID: String = LocalSession.currentUserID) -> UserSettings {
        let now = Date()
        return UserSettings(
            id: userID,
            userID: userID,
            translationCode: BibleTranslation.kjv.rawValue,
            preferredAppearance: .system,
            createdAt: now,
            updatedAt: now
        )
    }
}
