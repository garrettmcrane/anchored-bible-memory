import Foundation

enum BibleTranslation: String, CaseIterable, Identifiable, Codable {
    case kjv
    case esv

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .kjv:
            return "KJV"
        case .esv:
            return "ESV"
        }
    }

    var subtitle: String {
        switch self {
        case .kjv:
            return "Bundled offline"
        case .esv:
            return "API approval pending"
        }
    }

    var isAvailable: Bool {
        self == .kjv
    }
}
