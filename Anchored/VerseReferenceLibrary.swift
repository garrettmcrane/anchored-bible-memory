import Foundation

enum VerseReferenceLibrary {
    static let sampleVerses: [String: String] = [
        "John 3:16": "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.",
        "Romans 8:28": "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
        "Psalm 23:1": "The Lord is my shepherd; I shall not want.",
        "Proverbs 3:5": "Trust in the Lord with all your heart, and do not lean on your own understanding.",
        "Proverbs 3:6": "In all your ways acknowledge him, and he will make straight your paths.",
        "Philippians 4:6": "Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God.",
        "Philippians 4:7": "And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.",
        "2 Timothy 3:16": "All Scripture is breathed out by God and profitable for teaching, for reproof, for correction, and for training in righteousness.",
        "Joshua 1:9": "Have I not commanded you? Be strong and courageous. Do not be frightened, and do not be dismayed, for the Lord your God is with you wherever you go."
    ]

    static func lookup(reference: String) -> String? {
        let trimmed = normalize(reference)
        return sampleVerses.first { normalize($0.key) == trimmed }?.value
    }

    static func normalize(_ reference: String) -> String {
        reference
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
            .lowercased()
    }
}
