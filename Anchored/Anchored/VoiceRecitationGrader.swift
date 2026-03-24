import SwiftUI

struct VoiceRecitationGrade: Equatable {
    let transcript: String
    let accuracyPercent: Int
    let matchedWordCount: Int
    let expectedWordCount: Int
    let reviewResult: ReviewResult
    let targetAttributedText: AttributedString
    let transcriptAttributedText: AttributedString
    let mismatchCount: Int

    var isPassing: Bool {
        reviewResult == .correct
    }

    var summaryTitle: String {
        isPassing ? "Correct" : "Needs Work"
    }

    var summaryDetail: String {
        "\(accuracyPercent)% match across \(expectedWordCount) verse words"
    }

    var tintColor: Color {
        isPassing ? AppColors.success : AppColors.weakness
    }
}

enum VoiceRecitationGrader {
    static func grade(transcript: String, targetText: String) -> VoiceRecitationGrade {
        let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetTokens = comparableTokens(from: targetText, filterFillers: false)
        let transcriptTokens = comparableTokens(from: cleanedTranscript, filterFillers: true)
        let alignment = align(targetTokens: targetTokens, transcriptTokens: transcriptTokens)

        let targetMismatchIndexes = Set(alignment.operations.compactMap { operation in
            switch operation {
            case .match(let targetIndex, _):
                return alignment.matchedTargetIndexes.contains(targetIndex) ? nil : targetIndex
            case .delete(let targetIndex), .substitute(let targetIndex, _):
                return targetIndex
            case .insert:
                return nil
            }
        })

        let transcriptMismatchIndexes = Set(alignment.operations.compactMap { operation in
            switch operation {
            case .match(_, let transcriptIndex):
                return alignment.matchedTranscriptIndexes.contains(transcriptIndex) ? nil : transcriptIndex
            case .insert(let transcriptIndex), .substitute(_, let transcriptIndex):
                return transcriptIndex
            case .delete:
                return nil
            }
        })

        let expectedWordCount = max(targetTokens.count, 1)
        let accuracy = Int((Double(max(targetTokens.count - alignment.editDistance, 0)) / Double(expectedWordCount) * 100).rounded())
        let reviewResult: ReviewResult = accuracy >= 90 ? .correct : .missed

        return VoiceRecitationGrade(
            transcript: cleanedTranscript,
            accuracyPercent: accuracy,
            matchedWordCount: alignment.matchCount,
            expectedWordCount: targetTokens.count,
            reviewResult: reviewResult,
            targetAttributedText: attributedText(for: targetTokens, mismatchedIndexes: targetMismatchIndexes, showsMissingWords: true),
            transcriptAttributedText: attributedText(for: transcriptTokens, mismatchedIndexes: transcriptMismatchIndexes, showsMissingWords: false),
            mismatchCount: alignment.editDistance
        )
    }

    private static func comparableTokens(from text: String, filterFillers: Bool) -> [ComparableToken] {
        text
            .split(whereSeparator: \.isWhitespace)
            .compactMap { rawSubstring in
                let raw = String(rawSubstring)
                let normalized = raw
                    .lowercased()
                    .filter { $0.isLetter || $0.isNumber }

                guard !normalized.isEmpty else {
                    return nil
                }

                if filterFillers, fillerWords.contains(normalized) {
                    return nil
                }

                return ComparableToken(raw: raw, normalized: normalized)
            }
    }

    private static func attributedText(
        for tokens: [ComparableToken],
        mismatchedIndexes: Set<Int>,
        showsMissingWords: Bool
    ) -> AttributedString {
        guard !tokens.isEmpty else {
            return AttributedString(showsMissingWords ? "No verse text available." : "No transcript captured.")
        }

        var attributedText = AttributedString()

        for (index, token) in tokens.enumerated() {
            var tokenText = AttributedString(token.raw)

            if mismatchedIndexes.contains(index) {
                tokenText.foregroundColor = AppColors.weakness
                tokenText.backgroundColor = showsMissingWords ? AppColors.subtleMissed : AppColors.gold.opacity(0.16)
            } else {
                tokenText.foregroundColor = AppColors.textPrimary
            }

            attributedText.append(tokenText)

            if index < tokens.count - 1 {
                attributedText.append(AttributedString(" "))
            }
        }

        return attributedText
    }

    private static func align(
        targetTokens: [ComparableToken],
        transcriptTokens: [ComparableToken]
    ) -> AlignmentResult {
        let targetCount = targetTokens.count
        let transcriptCount = transcriptTokens.count

        var table = Array(
            repeating: Array(repeating: 0, count: transcriptCount + 1),
            count: targetCount + 1
        )

        for targetIndex in 0...targetCount {
            table[targetIndex][0] = targetIndex
        }

        for transcriptIndex in 0...transcriptCount {
            table[0][transcriptIndex] = transcriptIndex
        }

        guard targetCount > 0 || transcriptCount > 0 else {
            return AlignmentResult(editDistance: 0, matchCount: 0, operations: [], matchedTargetIndexes: [], matchedTranscriptIndexes: [])
        }

        for targetIndex in 1...targetCount {
            for transcriptIndex in 1...transcriptCount {
                if targetTokens[targetIndex - 1].normalized == transcriptTokens[transcriptIndex - 1].normalized {
                    table[targetIndex][transcriptIndex] = table[targetIndex - 1][transcriptIndex - 1]
                } else {
                    table[targetIndex][transcriptIndex] = min(
                        table[targetIndex - 1][transcriptIndex] + 1,
                        table[targetIndex][transcriptIndex - 1] + 1,
                        table[targetIndex - 1][transcriptIndex - 1] + 1
                    )
                }
            }
        }

        var targetIndex = targetCount
        var transcriptIndex = transcriptCount
        var operations: [AlignmentOperation] = []
        var matchedTargetIndexes: Set<Int> = []
        var matchedTranscriptIndexes: Set<Int> = []

        while targetIndex > 0 || transcriptIndex > 0 {
            if targetIndex > 0,
               transcriptIndex > 0,
               targetTokens[targetIndex - 1].normalized == transcriptTokens[transcriptIndex - 1].normalized,
               table[targetIndex][transcriptIndex] == table[targetIndex - 1][transcriptIndex - 1] {
                operations.append(.match(target: targetIndex - 1, transcript: transcriptIndex - 1))
                matchedTargetIndexes.insert(targetIndex - 1)
                matchedTranscriptIndexes.insert(transcriptIndex - 1)
                targetIndex -= 1
                transcriptIndex -= 1
            } else if targetIndex > 0,
                      transcriptIndex > 0,
                      table[targetIndex][transcriptIndex] == table[targetIndex - 1][transcriptIndex - 1] + 1 {
                operations.append(.substitute(target: targetIndex - 1, transcript: transcriptIndex - 1))
                targetIndex -= 1
                transcriptIndex -= 1
            } else if targetIndex > 0,
                      table[targetIndex][transcriptIndex] == table[targetIndex - 1][transcriptIndex] + 1 {
                operations.append(.delete(target: targetIndex - 1))
                targetIndex -= 1
            } else if transcriptIndex > 0 {
                operations.append(.insert(transcript: transcriptIndex - 1))
                transcriptIndex -= 1
            }
        }

        return AlignmentResult(
            editDistance: table[targetCount][transcriptCount],
            matchCount: matchedTargetIndexes.count,
            operations: operations.reversed(),
            matchedTargetIndexes: matchedTargetIndexes,
            matchedTranscriptIndexes: matchedTranscriptIndexes
        )
    }

    private static let fillerWords: Set<String> = [
        "um",
        "uh"
    ]

    private struct ComparableToken: Equatable {
        let raw: String
        let normalized: String
    }

    private struct AlignmentResult {
        let editDistance: Int
        let matchCount: Int
        let operations: [AlignmentOperation]
        let matchedTargetIndexes: Set<Int>
        let matchedTranscriptIndexes: Set<Int>
    }

    private enum AlignmentOperation {
        case match(target: Int, transcript: Int)
        case substitute(target: Int, transcript: Int)
        case delete(target: Int)
        case insert(transcript: Int)
    }
}
