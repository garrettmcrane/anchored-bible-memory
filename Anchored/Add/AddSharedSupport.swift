import SwiftUI

struct ScriptureAddPreviewContext: Identifiable, Hashable {
    let id = UUID()
    let passages: [ScripturePassage]
}

struct ScriptureSaveOptions {
    var folderName: String = "Uncategorized"
    var masteryStatus: VerseMasteryStatus = .learning
}

enum ScriptureAddPipeline {
    static func makeVerses(from passages: [ScripturePassage], options: ScriptureSaveOptions) -> [Verse] {
        let normalizedFolder = normalizedFolderName(options.folderName)
        let finalFolder = normalizedFolder.isEmpty ? "Uncategorized" : normalizedFolder

        return passages.map { passage in
            Verse(
                reference: passage.normalizedReference,
                text: passage.text,
                folderName: finalFolder,
                isMastered: options.masteryStatus == .memorized
            )
        }
    }

    static func normalizedFolderName(_ folderName: String) -> String {
        let trimmedFolderName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsedWhitespaceFolderName.isEmpty else {
            return ""
        }

        return collapsedWhitespaceFolderName.lowercased().localizedCapitalized
    }
}

struct TranslationPickerSection: View {
    @Binding var selection: BibleTranslation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Translation")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(BibleTranslation.allCases) { translation in
                Button {
                    selection = translation
                } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(translation.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(translation.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if translation == selection {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        } else if !translation.isAvailable {
                            Text("Soon")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.orange.opacity(0.14)))
                                .foregroundStyle(Color.orange)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(translation == selection ? Color.blue.opacity(0.25) : Color.clear, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AddFlowMessageCard: View {
    let message: String
    var tint: Color = .secondary

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.09))
            )
    }
}
