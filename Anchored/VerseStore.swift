import Foundation

final class VerseStore {
    private static let versesKey = "saved_verses"

    static func save(_ verses: [Verse]) {
        do {
            let data = try JSONEncoder().encode(verses)
            UserDefaults.standard.set(data, forKey: versesKey)
        } catch {
            print("Failed to save verses: \(error)")
        }
    }

    static func load() -> [Verse] {
        guard let data = UserDefaults.standard.data(forKey: versesKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Verse].self, from: data)
        } catch {
            print("Failed to load verses: \(error)")
            return []
        }
    }
}
