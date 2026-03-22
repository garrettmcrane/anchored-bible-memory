import SwiftUI
import UIKit

struct ImportReferencesPreviewContext: Identifiable, Hashable {
    let id = UUID()
    let importablePassages: [ScripturePassage]
    let duplicatePassages: [ScripturePassage]
    let unresolvedEntries: [String]
    let duplicateReferenceCount: Int
}

struct ImportReferencesView: View {
    let onComplete: (() -> Void)?

    @State private var rawInput = ""
    @State private var previewContext: ImportReferencesPreviewContext?
    @State private var message: String?
    @FocusState private var isEditorFocused: Bool

    private let placeholderText = """
    Paste references here.

    One per line:
    John 3:16
    Romans 8:28

    Comma-separated:
    John 3:16, Romans 8:28, Psalm 119:11

    Mixed block:
    Memory list:
    John 3:16
    Romans 8:28, Psalm 119:11
    Jude 3
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pasted References")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppColors.surface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        isEditorFocused ? AppColors.structuralAccent.opacity(0.28) : AppColors.background.opacity(0.05),
                                        lineWidth: 1
                                    )
                            }

                        TextEditor(text: $rawInput)
                            .focused($isEditorFocused)
                            .scrollContentBackground(.hidden)
                            .font(.body)
                            .frame(minHeight: 260)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                        if rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(placeholderText)
                                .font(.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }

                    HStack {
                        Text("We’ll extract recognized references, merge exact repeats, and show anything unresolved separately.")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()

                        Button("Paste") {
                            rawInput = UIPasteboard.general.string ?? rawInput
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }

                if let message {
                    AddFlowMessageCard(
                        message: message,
                        tint: message.contains("ready") ? AppColors.success : AppColors.warning
                    )
                }

                Button("Preview Import") {
                    buildPreview()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Import References")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $previewContext) { context in
            ImportReferencesPreviewView(
                context: context,
                onComplete: onComplete
            )
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Paste a memory list and review everything before it touches your library.")
                .font(.title3.weight(.semibold))

            Text("Import V1 supports pasted plain text references. File uploads, images, and OCR stay out of this flow.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.selectionFill)
        )
    }

    private func buildPreview() {
        do {
            let parseResult = try ReferenceParser.parseImportBlock(rawInput)
            guard !parseResult.references.isEmpty else {
                message = parseResult.unresolvedEntries.isEmpty
                    ? "No valid references found in that paste."
                    : "No valid references found. Review the unresolved entries and try again."
                return
            }

            let provider = try ScriptureProviderFactory.makeProvider(for: .kjv)
            var resolvedPassages: [ScripturePassage] = []
            var unresolvedEntries = parseResult.unresolvedEntries

            for reference in parseResult.references {
                do {
                    resolvedPassages.append(try provider.fetchPassage(for: reference))
                } catch {
                    unresolvedEntries.append(reference.normalizedReference)
                }
            }

            guard !resolvedPassages.isEmpty else {
                message = "We couldn't resolve any passages from that paste."
                return
            }

            let existingReferenceKeys = Set(
                VerseRepository.shared.loadVerses().map { verse in
                    ScriptureAddPipeline.normalizedReferenceKey(verse.reference)
                }
            )

            var importablePassages: [ScripturePassage] = []
            var duplicatePassages: [ScripturePassage] = []

            for passage in resolvedPassages {
                let referenceKey = ScriptureAddPipeline.normalizedReferenceKey(passage.normalizedReference)
                if existingReferenceKeys.contains(referenceKey) {
                    duplicatePassages.append(passage)
                } else {
                    importablePassages.append(passage)
                }
            }

            previewContext = ImportReferencesPreviewContext(
                importablePassages: importablePassages,
                duplicatePassages: duplicatePassages,
                unresolvedEntries: deduplicatedEntries(unresolvedEntries),
                duplicateReferenceCount: parseResult.duplicateReferenceCount
            )

            let readyCount = importablePassages.count
            let duplicateCount = duplicatePassages.count
            let unresolvedCount = deduplicatedEntries(unresolvedEntries).count
            message = summaryMessage(
                readyCount: readyCount,
                duplicateCount: duplicateCount,
                unresolvedCount: unresolvedCount
            )
        } catch {
            message = error.localizedDescription
        }
    }

    private func deduplicatedEntries(_ entries: [String]) -> [String] {
        var seen: Set<String> = []
        var deduplicated: [String] = []

        for entry in entries {
            let normalizedEntry = ScriptureAddPipeline.normalizedReferenceKey(entry)
            if seen.insert(normalizedEntry).inserted {
                deduplicated.append(entry)
            }
        }

        return deduplicated
    }

    private func summaryMessage(
        readyCount: Int,
        duplicateCount: Int,
        unresolvedCount: Int
    ) -> String {
        var parts: [String] = []

        if readyCount > 0 {
            parts.append("\(readyCount) ready to import")
        }

        if duplicateCount > 0 {
            parts.append("\(duplicateCount) already in library")
        }

        if unresolvedCount > 0 {
            parts.append("\(unresolvedCount) unresolved")
        }

        return parts.isEmpty ? "No valid references found in that paste." : parts.joined(separator: " • ")
    }
}

private struct ImportReferencesPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let context: ImportReferencesPreviewContext
    let onComplete: (() -> Void)?

    @State private var selectedFolder = "Uncategorized"
    @State private var isAddingNewFolder = false
    @State private var newFolderName = ""
    @State private var masteryStatus: VerseMasteryStatus = .practicing
    @State private var successMessage: String?
    @State private var isSaving = false

    private var existingFolders: [String] {
        ScriptureAddPipeline.existingFolderNames(including: [selectedFolder])
    }

    private var resolvedCount: Int {
        context.importablePassages.count + context.duplicatePassages.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                saveButton
                defaultsCard

                if context.importablePassages.isEmpty {
                    AddFlowMessageCard(
                        message: "Everything that resolved is already in your library. Nothing new will be imported.",
                        tint: AppColors.gold
                    )
                } else {
                    passageSection(
                        title: context.importablePassages.count == 1 ? "Ready to Import" : "Ready to Import (\(context.importablePassages.count))",
                        subtitle: "These passages will be saved with the defaults below.",
                        passages: context.importablePassages
                    )
                }

                if !context.duplicatePassages.isEmpty {
                    passageSection(
                        title: context.duplicatePassages.count == 1 ? "Already in Library" : "Already in Library (\(context.duplicatePassages.count))",
                        subtitle: "These resolved correctly, but they will be skipped on save.",
                        passages: context.duplicatePassages,
                        badgeTitle: "Already Saved",
                        badgeTint: AppColors.warning
                    )
                }

                if !context.unresolvedEntries.isEmpty {
                    unresolvedSection
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Import Preview")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let successMessage {
                FeedbackToast(message: successMessage, systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: successMessage)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summaryHeadline)
                .font(.title3.weight(.semibold))

            Text(summaryDetail)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            if context.duplicateReferenceCount > 0 {
                Text("\(context.duplicateReferenceCount) repeated reference\(context.duplicateReferenceCount == 1 ? "" : "s") in the pasted text \(context.duplicateReferenceCount == 1 ? "was" : "were") merged automatically.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.structuralAccent.opacity(0.1))
        )
    }

    private var defaultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Default Status")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Picker("Status", selection: $masteryStatus) {
                    ForEach(VerseMasteryStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Default Folder")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                folderMenu(
                    selection: selectedFolder,
                    title: selectedFolder,
                    tint: AppColors.textPrimary
                ) { folder in
                    selectedFolder = folder
                }

                Button(isAddingNewFolder ? "Cancel New Folder" : "New Folder") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAddingNewFolder.toggle()
                    }
                }
                .font(.subheadline.weight(.semibold))

                if isAddingNewFolder {
                    VStack(spacing: 8) {
                        TextField("New folder name", text: $newFolderName)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppColors.surface)
                            )

                        Button("Save Folder") {
                            saveNewFolder()
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppColors.structuralAccent.opacity(0.12))
                        )
                        .disabled(normalizedCandidateFolderName == nil)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var saveButton: some View {
        Button {
            saveImport()
        } label: {
            Text(isSaving ? "Importing..." : saveButtonTitle)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(context.importablePassages.isEmpty ? AppColors.textSecondary : AppColors.structuralAccent)
                )
                .shadow(color: AppColors.background.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isSaving || context.importablePassages.isEmpty)
    }

    private var unresolvedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(context.unresolvedEntries.count == 1 ? "Unresolved Entry" : "Unresolved Entries (\(context.unresolvedEntries.count))")
                .font(.headline)

            Text("These could not be parsed or resolved, and they will not be saved.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            ForEach(context.unresolvedEntries, id: \.self) { entry in
                Text(entry)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.gold.opacity(0.1))
                    )
            }
        }
    }

    private var summaryHeadline: String {
        if context.importablePassages.isEmpty {
            return resolvedCount == 1 ? "1 valid reference found" : "\(resolvedCount) valid references found"
        }

        return context.importablePassages.count == 1
            ? "1 verse ready to import"
            : "\(context.importablePassages.count) verses ready to import"
    }

    private var summaryDetail: String {
        var parts: [String] = []
        parts.append("\(resolvedCount) valid")

        if !context.duplicatePassages.isEmpty {
            parts.append("\(context.duplicatePassages.count) already in library")
        }

        if !context.unresolvedEntries.isEmpty {
            parts.append("\(context.unresolvedEntries.count) unresolved")
        }

        return parts.joined(separator: " • ")
    }

    private var saveButtonTitle: String {
        context.importablePassages.count == 1 ? "Import Verse" : "Import Verses"
    }

    private func passageSection(
        title: String,
        subtitle: String,
        passages: [ScripturePassage],
        badgeTitle: String? = nil,
        badgeTint: Color = AppColors.textSecondary
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            ForEach(passages) { passage in
                importPassageCard(
                    for: passage,
                    badgeTitle: badgeTitle,
                    badgeTint: badgeTint
                )
            }
        }
    }

    private func importPassageCard(
        for passage: ScripturePassage,
        badgeTitle: String?,
        badgeTint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(passage.normalizedReference)
                    .font(.headline)

                if let badgeTitle {
                    Text(badgeTitle)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(badgeTint.opacity(0.14)))
                        .foregroundStyle(badgeTint)
                }

                Spacer(minLength: 0)
            }

            Text(passage.text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func folderMenu(
        selection: String,
        title: String,
        tint: Color,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            Button("Uncategorized") {
                onSelect("Uncategorized")
            }

            ForEach(existingFolders, id: \.self) { folder in
                Button(folder) {
                    onSelect(folder)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.surface)
            )
        }
        .buttonStyle(.plain)
    }

    private var normalizedCandidateFolderName: String? {
        let normalizedName = ScriptureAddPipeline.normalizedFolderName(newFolderName)
        return normalizedName.isEmpty ? nil : normalizedName
    }

    private func saveNewFolder() {
        guard let normalizedName = normalizedCandidateFolderName else {
            return
        }

        let savedFolder = existingFolders.first(where: {
            $0.compare(normalizedName, options: .caseInsensitive) == .orderedSame
        }) ?? normalizedName

        selectedFolder = savedFolder
        newFolderName = ""
        isAddingNewFolder = false
    }

    private func saveImport() {
        guard !isSaving, !context.importablePassages.isEmpty else {
            return
        }

        isSaving = true

        let verses = ScriptureAddPipeline.makeVerses(
            from: context.importablePassages,
            options: ScriptureSaveOptions(
                folderName: selectedFolder,
                masteryStatus: masteryStatus
            )
        )
        VerseRepository.shared.addVerses(verses)

        successMessage = context.importablePassages.count == 1
            ? "1 verse imported"
            : "\(context.importablePassages.count) verses imported"

        Task {
            try? await Task.sleep(for: .seconds(1.1))
            await MainActor.run {
                onComplete?()
                if onComplete == nil {
                    dismiss()
                }
            }
        }
    }
}
