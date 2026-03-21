import Foundation

#if DEBUG
struct DebugVerseRecencySimulator {
    enum Preset: CaseIterable, Identifiable {
        case fresh
        case atRisk
        case needsReview
        case clear

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .fresh:
                return "Set All Fresh"
            case .atRisk:
                return "Set All At Risk"
            case .needsReview:
                return "Set All Needs Review"
            case .clear:
                return "Clear Review Dates"
            }
        }

        var lastReviewedAt: Date? {
            let calendar = Calendar.current

            switch self {
            case .fresh:
                return Date()
            case .atRisk:
                return calendar.date(byAdding: .day, value: -4, to: Date())
            case .needsReview:
                return calendar.date(byAdding: .day, value: -8, to: Date())
            case .clear:
                return nil
            }
        }

        var strength: Double {
            switch self {
            case .clear:
                return VerseStrengthService.defaultUnreviewedStrength
            default:
                return 1
            }
        }
    }

    func apply(_ preset: Preset) {
        var allVerses = VerseStore.load()

        for index in allVerses.indices {
            guard allVerses[index].ownerUserID == LocalSession.currentUserID,
                  allVerses[index].sourceType == .personal,
                  allVerses[index].deletedAt == nil else {
                continue
            }

            allVerses[index].strength = preset.strength
            allVerses[index].lastReviewedAt = preset.lastReviewedAt
            allVerses[index].updatedAt = Date()
        }

        VerseStore.save(allVerses)
    }
}
#endif
