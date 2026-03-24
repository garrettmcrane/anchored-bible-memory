import SwiftUI

struct ScriptureAddPreviewContext: Identifiable, Hashable {
    let id = UUID()
    let passages: [ScripturePassage]
}

struct ScriptureSaveOptions {
    var folderName: String = "Uncategorized"
    var masteryStatus: VerseMasteryStatus = .practicing
}

struct ScriptureAddSaveItem: Identifiable, Hashable {
    let reference: String
    let text: String
    let passages: [ScripturePassage]

    var id: String {
        ScriptureAddPipeline.normalizedReferenceKey(reference)
    }
}

enum ScriptureAddPipeline {
    static func makeVerse(from passage: ScripturePassage, options: ScriptureSaveOptions) -> Verse {
        makeVerse(
            from: ScriptureAddSaveItem(
                reference: passage.normalizedReference,
                text: passage.text,
                passages: [passage]
            ),
            options: options
        )
    }

    static func makeVerse(from saveItem: ScriptureAddSaveItem, options: ScriptureSaveOptions) -> Verse {
        let normalizedFolder = normalizedFolderName(options.folderName)
        let finalFolder = normalizedFolder.isEmpty ? "Uncategorized" : normalizedFolder

        return Verse(
            reference: saveItem.reference,
            text: saveItem.text,
            folderName: finalFolder,
            isMastered: options.masteryStatus == .memorized
        )
    }

    static func makeVerses(from passages: [ScripturePassage], options: ScriptureSaveOptions) -> [Verse] {
        return passages.map { passage in
            makeVerse(from: passage, options: options)
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

    static func existingFolderNames(including additionalFolders: [String] = []) -> [String] {
        var normalizedFolders = Set(
            VerseRepository.shared.loadVerses().map { normalizedFolderName($0.folderName) }
        )
        normalizedFolders.remove("Uncategorized")

        for folder in additionalFolders {
            let normalizedFolder = normalizedFolderName(folder)
            if !normalizedFolder.isEmpty, normalizedFolder != "Uncategorized" {
                normalizedFolders.insert(normalizedFolder)
            }
        }

        return normalizedFolders.sorted()
    }

    static func normalizedReferenceKey(_ reference: String) -> String {
        reference
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }

    static func makeSaveItems(from passages: [ScripturePassage]) -> [ScriptureAddSaveItem] {
        passages.map { passage in
            ScriptureAddSaveItem(
                reference: passage.normalizedReference,
                text: passage.text,
                passages: [passage]
            )
        }
    }

    static func existingReferenceKeys() -> Set<String> {
        Set(
            VerseRepository.shared.loadVerses().map { verse in
                normalizedReferenceKey(verse.reference)
            }
        )
    }
}

struct TranslationPickerSection: View {
    @Binding var selection: BibleTranslation

    var body: some View {
        HStack {
            Text("Translation")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Menu {
                ForEach(BibleTranslation.allCases) { translation in
                    if translation.isAvailable {
                        Button {
                            selection = translation
                        } label: {
                            if translation == selection {
                                Label(translation.title, systemImage: "checkmark")
                            } else {
                                Text(translation.title)
                            }
                        }
                    } else {
                        Text("\(translation.title) • Coming soon")
                    }
                }
            } label: {
                AnchoredCapsuleMenuLabel(title: selection.title)
            }
            .buttonStyle(.plain)
        }
    }
}

struct AddFlowMessageCard: View {
    let message: String
    var tint: Color = AppColors.textSecondary

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.surface)
            )
    }
}

struct FeedbackToast: View {
    let message: String
    let systemImage: String
    var tint: Color = AppColors.structuralAccent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(message)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
    }
}
