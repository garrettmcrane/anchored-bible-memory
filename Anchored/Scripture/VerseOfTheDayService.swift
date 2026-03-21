import Foundation

struct VerseOfTheDayContent: Equatable {
    let reference: String
    let text: String
}

enum VerseOfTheDayService {
    static let fallbackReference = "John 3:16"

    static let curatedReferences: [String] = [
        "Genesis 1:27",
        "Genesis 15:6",
        "Genesis 50:20",
        "Exodus 14:14",
        "Exodus 15:2",
        "Exodus 33:14",
        "Deuteronomy 6:5",
        "Deuteronomy 31:6",
        "Joshua 1:9",
        "1 Samuel 16:7",
        "2 Samuel 22:31",
        "1 Kings 8:56",
        "1 Chronicles 16:11",
        "2 Chronicles 7:14",
        "Nehemiah 8:10",
        "Job 1:21",
        "Job 19:25",
        "Psalm 4:8",
        "Psalm 5:11",
        "Psalm 9:9",
        "Psalm 16:8",
        "Psalm 18:2",
        "Psalm 23:1",
        "Psalm 23:4",
        "Psalm 27:1",
        "Psalm 27:14",
        "Psalm 28:7",
        "Psalm 29:11",
        "Psalm 30:5",
        "Psalm 31:24",
        "Psalm 32:8",
        "Psalm 33:4",
        "Psalm 34:8",
        "Psalm 34:18",
        "Psalm 37:4",
        "Psalm 37:5",
        "Psalm 37:7",
        "Psalm 40:1",
        "Psalm 46:1",
        "Psalm 46:10",
        "Psalm 51:10",
        "Psalm 55:22",
        "Psalm 56:3",
        "Psalm 62:1",
        "Psalm 62:8",
        "Psalm 63:3",
        "Psalm 66:20",
        "Psalm 68:19",
        "Psalm 73:26",
        "Psalm 84:11",
        "Psalm 85:10",
        "Psalm 86:5",
        "Psalm 90:14",
        "Psalm 91:1",
        "Psalm 94:19",
        "Psalm 100:5",
        "Psalm 103:8",
        "Psalm 103:12",
        "Psalm 107:1",
        "Psalm 112:7",
        "Psalm 116:1",
        "Psalm 118:6",
        "Psalm 119:9",
        "Psalm 119:11",
        "Psalm 119:105",
        "Psalm 121:1",
        "Psalm 121:2",
        "Psalm 121:7",
        "Psalm 126:5",
        "Psalm 130:5",
        "Psalm 133:1",
        "Psalm 138:8",
        "Psalm 139:14",
        "Psalm 143:8",
        "Psalm 145:9",
        "Psalm 147:3",
        "Proverbs 1:7",
        "Proverbs 3:5",
        "Proverbs 3:6",
        "Proverbs 3:7",
        "Proverbs 4:23",
        "Proverbs 9:10",
        "Proverbs 10:12",
        "Proverbs 11:25",
        "Proverbs 12:25",
        "Proverbs 15:1",
        "Proverbs 16:3",
        "Proverbs 16:9",
        "Proverbs 17:17",
        "Proverbs 18:10",
        "Proverbs 19:21",
        "Proverbs 20:24",
        "Proverbs 22:6",
        "Proverbs 24:16",
        "Ecclesiastes 3:1",
        "Ecclesiastes 4:9",
        "Ecclesiastes 7:9",
        "Isaiah 9:6",
        "Isaiah 12:2",
        "Isaiah 26:3",
        "Isaiah 30:15",
        "Isaiah 40:8",
        "Isaiah 40:29",
        "Isaiah 40:31",
        "Isaiah 41:10",
        "Isaiah 43:2",
        "Isaiah 53:5",
        "Isaiah 55:8",
        "Isaiah 55:9",
        "Isaiah 58:11",
        "Jeremiah 17:7",
        "Jeremiah 29:11",
        "Jeremiah 31:3",
        "Lamentations 3:22",
        "Lamentations 3:23",
        "Ezekiel 36:26",
        "Daniel 2:22",
        "Hosea 6:6",
        "Micah 6:8",
        "Nahum 1:7",
        "Habakkuk 3:19",
        "Zephaniah 3:17",
        "Zechariah 4:6",
        "Malachi 3:6",
        "Matthew 5:9",
        "Matthew 5:16",
        "Matthew 6:21",
        "Matthew 6:33",
        "Matthew 7:7",
        "Matthew 7:12",
        "Matthew 11:28",
        "Matthew 19:26",
        "Matthew 22:37",
        "Matthew 22:39",
        "Matthew 28:20",
        "Mark 9:23",
        "Mark 10:27",
        "Mark 11:24",
        "Luke 1:37",
        "Luke 6:31",
        "Luke 6:36",
        "Luke 10:27",
        "Luke 11:9",
        "Luke 12:7",
        "Luke 16:10",
        "John 1:5",
        "John 1:12",
        "John 3:16",
        "John 8:12",
        "John 10:10",
        "John 11:25",
        "John 13:34",
        "John 14:1",
        "John 14:6",
        "John 14:15",
        "John 14:27",
        "John 15:5",
        "John 15:12",
        "John 16:33",
        "John 17:17",
        "Acts 1:8",
        "Acts 2:38",
        "Acts 4:12",
        "Acts 16:31",
        "Romans 1:16",
        "Romans 5:1",
        "Romans 5:8",
        "Romans 6:23",
        "Romans 8:1",
        "Romans 8:6",
        "Romans 8:18",
        "Romans 8:28",
        "Romans 8:31",
        "Romans 8:38",
        "Romans 10:9",
        "Romans 12:2",
        "Romans 12:12",
        "Romans 13:10",
        "1 Corinthians 1:18",
        "1 Corinthians 6:19",
        "1 Corinthians 10:13",
        "1 Corinthians 13:4",
        "1 Corinthians 13:6",
        "1 Corinthians 13:7",
        "1 Corinthians 13:13",
        "1 Corinthians 15:58",
        "2 Corinthians 3:17",
        "2 Corinthians 4:16",
        "2 Corinthians 5:7",
        "2 Corinthians 5:17",
        "2 Corinthians 9:7",
        "2 Corinthians 12:9",
        "Galatians 2:20",
        "Galatians 5:1",
        "Galatians 5:22",
        "Galatians 5:23",
        "Galatians 6:9",
        "Ephesians 2:8",
        "Ephesians 3:20",
        "Ephesians 4:2",
        "Ephesians 4:32",
        "Ephesians 5:2",
        "Ephesians 6:10",
        "Philippians 1:6",
        "Philippians 2:3",
        "Philippians 4:4",
        "Philippians 4:6",
        "Philippians 4:7",
        "Philippians 4:8",
        "Philippians 4:13",
        "Colossians 1:17",
        "Colossians 2:6",
        "Colossians 3:2",
        "Colossians 3:12",
        "Colossians 3:15",
        "Colossians 3:17",
        "1 Thessalonians 5:16",
        "1 Thessalonians 5:17",
        "1 Thessalonians 5:18",
        "2 Thessalonians 3:3",
        "1 Timothy 1:5",
        "1 Timothy 4:12",
        "1 Timothy 6:6",
        "2 Timothy 1:7",
        "2 Timothy 2:13",
        "2 Timothy 3:16",
        "Titus 2:11",
        "Titus 3:5",
        "Hebrews 4:12",
        "Hebrews 10:23",
        "Hebrews 11:1",
        "Hebrews 12:1",
        "Hebrews 13:5",
        "James 1:5",
        "James 1:17",
        "James 1:22",
        "James 4:7",
        "1 Peter 1:3",
        "1 Peter 1:8",
        "1 Peter 2:9",
        "1 Peter 3:15",
        "1 Peter 4:8",
        "1 Peter 5:7",
        "2 Peter 1:3",
        "2 Peter 3:9",
        "1 John 1:9",
        "1 John 3:1",
        "1 John 4:7",
        "1 John 4:8",
        "1 John 4:18",
        "1 John 5:14",
        "Jude 1:24",
        "Revelation 3:20",
        "Revelation 21:4"
    ]

    static func resolveDailyVerse(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) async -> VerseOfTheDayContent {
        resolveDailyVerseSynchronously(for: date, calendar: calendar)
    }

    static func resolveDailyVerseSynchronously(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> VerseOfTheDayContent {
        let reference = reference(for: date, calendar: calendar)

        if let resolved = resolve(reference: reference) {
            return resolved
        }

        if reference != fallbackReference, let fallback = resolve(reference: fallbackReference) {
            return fallback
        }

        return VerseOfTheDayContent(
            reference: fallbackReference,
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."
        )
    }

    static func reference(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let localCalendar = configuredCalendar(from: calendar)
        let startOfDay = localCalendar.startOfDay(for: date)
        let referenceDate = localCalendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? startOfDay
        let dayOffset = localCalendar.dateComponents([.day], from: referenceDate, to: startOfDay).day ?? 0
        let mixedIndex = abs((dayOffset * 37) + 17) % curatedReferences.count
        return curatedReferences[mixedIndex]
    }

    static func dayKey(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let localCalendar = configuredCalendar(from: calendar)
        let components = localCalendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func resolve(reference: String) -> VerseOfTheDayContent? {
        do {
            let parsedReference = try ReferenceParser.parseSingle(reference)
            let provider = try ScriptureProviderFactory.makeProvider(for: .kjv)
            let passage = try provider.fetchPassage(for: parsedReference)
            return VerseOfTheDayContent(reference: passage.normalizedReference, text: passage.text)
        } catch {
            return nil
        }
    }

    private static func configuredCalendar(from calendar: Calendar) -> Calendar {
        var localCalendar = calendar
        localCalendar.timeZone = .current
        return localCalendar
    }
}
