import Foundation

struct ProgressiveWordHidingState {
    private let tokens: [VerseToken]
    private let hideOrder: [Int]
    private let stepSize: Int

    private(set) var hiddenWordCount = 0

    init(text: String) {
        let tokens = VerseToken.tokenize(text)
        self.tokens = tokens

        let hideableWordIndices = tokens.enumerated().compactMap { index, token in
            token.isHideableWord ? index : nil
        }

        hideOrder = Self.makeHideOrder(from: hideableWordIndices)
        stepSize = max(1, hideOrder.count / 5)
    }

    var displayedText: String {
        let hiddenIndices = Set(hideOrder.prefix(hiddenWordCount))

        return tokens.enumerated().map { index, token in
            if hiddenIndices.contains(index) {
                return token.hiddenPlaceholder
            }

            return token.value
        }
        .joined()
    }

    var canHideMoreWords: Bool {
        hiddenWordCount < hideOrder.count
    }

    var hasHiddenWords: Bool {
        hiddenWordCount > 0
    }

    mutating func hideMoreWords() {
        guard canHideMoreWords else {
            return
        }

        hiddenWordCount = min(hideOrder.count, hiddenWordCount + stepSize)
    }

    mutating func reset() {
        hiddenWordCount = 0
    }

    private static func makeHideOrder(from indices: [Int]) -> [Int] {
        let evenPositions = indices.enumerated().compactMap { offset, index in
            offset.isMultiple(of: 2) ? index : nil
        }
        let oddPositions = indices.enumerated().compactMap { offset, index in
            offset.isMultiple(of: 2) ? nil : index
        }

        return evenPositions + oddPositions
    }
}

private struct VerseToken {
    let value: String
    let isHideableWord: Bool

    var hiddenPlaceholder: String {
        guard isHideableWord else {
            return value
        }

        return String(repeating: "_", count: max(2, value.count))
    }

    static func tokenize(_ text: String) -> [VerseToken] {
        let pattern = #"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)*|\s+|[^A-Za-z0-9\s]"#
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let regex = try? NSRegularExpression(pattern: pattern)

        guard let regex else {
            return [VerseToken(value: text, isHideableWord: false)]
        }

        return regex.matches(in: text, range: range).compactMap { match in
            guard let tokenRange = Range(match.range, in: text) else {
                return nil
            }

            let tokenValue = String(text[tokenRange])
            let isWord = tokenValue.rangeOfCharacter(from: .letters) != nil &&
                tokenValue.rangeOfCharacter(from: .whitespacesAndNewlines) == nil

            return VerseToken(value: tokenValue, isHideableWord: isWord)
        }
    }
}
