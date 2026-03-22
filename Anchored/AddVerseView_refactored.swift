import SwiftUI
import UIKit

private struct AddVerseReviewContext: Identifiable, Hashable {
    let id = UUID()
    let passages: [ScripturePassage]
    let unresolvedEntries: [String]
    let duplicateReferenceCount: Int
    let existingReferenceKeys: Set<String>
}

struct AddVerseView: View {
    let focusTrigger: Int
    let onSave: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var translation: BibleTranslation = .kjv
    @State private var rawInput = ""
    @State private var reviewContext: AddVerseReviewContext?
    @State private var message: String?
    @FocusState private var isReferenceEditorFocused: Bool

    init(
        showsCancelButton: Bool = true,
        focusTrigger: Int = 0,
        onSave: @escaping (Verse) -> Void,
        onComplete: (() -> Void)? = nil
    ) {
        self.focusTrigger = focusTrigger
        self.onSave = onSave
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                inputCard

                if let message {
                    AddFlowMessageCard(
                        message: message,
                        tint: message.contains("ready") ? AppColors.success : AppColors.warning
                    )
                }

                continueButton
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Type Verses")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $reviewContext) { context in
            AddVerseReviewView(
                context: context,
                onSave: onSave,
                onComplete: onComplete
            )
        }
        .onChange(of: focusTrigger) { _, _ in
            isReferenceEditorFocused = true
        }
        .onAppear {
            if focusTrigger > 0 {
                isReferenceEditorFocused = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isReferenceEditorFocused = false
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter one or more verses")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Anchored will identify what you type or paste into verses you can add to your library.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            TranslationPickerSection(selection: $translation)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColors.addHeroTint)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Passage Input")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Spacer(minLength: 12)

                Button("Paste") {
                    rawInput = UIPasteboard.general.string ?? rawInput
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.structuralAccent)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColors.addComposerBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                isReferenceEditorFocused ? AppColors.structuralAccent.opacity(0.3) : AppColors.addComposerBorder,
                                lineWidth: 1
                            )
                    }

                TextEditor(text: $rawInput)
                    .focused($isReferenceEditorFocused)
                    .scrollContentBackground(.hidden)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(minHeight: 280)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                if rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.structuralAccent)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text("""
                        John 3:16
                        Genesis 1:3-5, Romans 8:28
                        Memory list: John 3:16, Romans 12:2, Jude 24-25
                        """)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)
                    .allowsHitTesting(false)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var continueButton: some View {
        Button("Continue") {
            continueToReview()
        }
        .buttonStyle(.plain)
        .font(.headline.weight(.semibold))
        .foregroundStyle(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.textSecondary : AppColors.reviewPracticingActionText)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
            Capsule(style: .continuous)
                .fill(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.secondarySurface : AppColors.reviewPracticingActionBackground)
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppColors.divider.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: AppColors.shadow.opacity(0.18), radius: 12, y: 6)
        .disabled(rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func continueToReview() {
        guard translation.isAvailable else {
            message = "\(translation.title) is not available yet."
            return
        }

        do {
            let parseResult = try ReferenceParser.parseAddIntake(rawInput)
            guard !parseResult.references.isEmpty else {
                reviewContext = nil
                message = parseResult.unresolvedEntries.isEmpty
                    ? "No valid references found."
                    : "\(parseResult.unresolvedEntries.count) unresolved. Adjust the input and try again."
                return
            }

            let provider = try ScriptureProviderFactory.makeProvider(for: translation)
            var passages: [ScripturePassage] = []
            var unresolvedEntries = parseResult.unresolvedEntries

            for reference in parseResult.references {
                do {
                    passages.append(try provider.fetchPassage(for: reference))
                } catch {
                    unresolvedEntries.append(reference.normalizedReference)
                }
            }

            guard !passages.isEmpty else {
                reviewContext = nil
                message = "We couldn't resolve any passages from that input."
                return
            }

            let deduplicatedUnresolvedEntries = deduplicatedEntries(unresolvedEntries)
            reviewContext = AddVerseReviewContext(
                passages: passages,
                unresolvedEntries: deduplicatedUnresolvedEntries,
                duplicateReferenceCount: parseResult.duplicateReferenceCount,
                existingReferenceKeys: ScriptureAddPipeline.existingReferenceKeys()
            )

            var parts: [String] = ["\(passages.count) resolved"]
            let duplicateCount = duplicateCount(for: passages)
            if duplicateCount > 0 {
                parts.append("\(duplicateCount) already saved")
            }
            if !deduplicatedUnresolvedEntries.isEmpty {
                parts.append("\(deduplicatedUnresolvedEntries.count) unresolved")
            }
            message = parts.joined(separator: " • ")
        } catch {
            reviewContext = nil
            message = error.localizedDescription
        }
    }

    private func duplicateCount(for passages: [ScripturePassage]) -> Int {
        let existingKeys = ScriptureAddPipeline.existingReferenceKeys()
        return passages.reduce(into: 0) { total, passage in
            if existingKeys.contains(ScriptureAddPipeline.normalizedReferenceKey(passage.normalizedReference)) {
                total += 1
            }
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
}

private struct AddVerseReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let context: AddVerseReviewContext
    let onSave: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var selectedFolder = "Uncategorized"
    @State private var isResolvedListExpanded = true
    @State private var isSaving = false
    @State private var successMessage: String?
    @State private var isShowingCreateFolderPrompt = false
    @State private var newFolderName = ""

    private var existingFolders: [String] {
        ScriptureAddPipeline.existingFolderNames(including: [selectedFolder])
    }

    private var saveItems: [ScriptureAddSaveItem] {
        ScriptureAddPipeline.makeSaveItems(from: context.passages)
    }

    private var readyItems: [ScriptureAddSaveItem] {
        saveItems.filter { item in
            !context.existingReferenceKeys.contains(item.id)
        }
    }

    private var duplicateItems: [ScriptureAddSaveItem] {
        saveItems.filter { item in
            context.existingReferenceKeys.contains(item.id)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                folderCard
                resolvedDisclosure

                if !context.unresolvedEntries.isEmpty {
                    unresolvedSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(AppColors.background)
        .navigationTitle("Review & Save")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
        .overlay(alignment: .bottom) {
            if let successMessage {
                FeedbackToast(message: successMessage, systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: successMessage)
        .alert("Create New Folder", isPresented: $isShowingCreateFolderPrompt) {
            TextField("Folder name", text: $newFolderName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                createFolder()
            }
            .disabled(normalizedCandidateFolderName == nil)
        } message: {
            Text("New verses will save into this folder.")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary.opacity(0.78))

            Text(summaryTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            if !duplicateItems.isEmpty || !context.unresolvedEntries.isEmpty {
                HStack(spacing: 10) {
                    if !duplicateItems.isEmpty {
                        summaryBadge(title: "Existing", value: "\(duplicateItems.count)")
                    }

                    if !context.unresolvedEntries.isEmpty {
                        summaryBadge(title: "Unresolved", value: "\(context.unresolvedEntries.count)")
                    }
                }
            }

            if context.duplicateReferenceCount > 0 {
                Text("\(context.duplicateReferenceCount) repeated reference\(context.duplicateReferenceCount == 1 ? "" : "s") in your pasted input \(context.duplicateReferenceCount == 1 ? "was" : "were") merged automatically.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.84))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 18, y: 10)
    }

    private func summaryBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary.opacity(0.74))

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.12))
        )
    }

    private var folderCard: some View {
        HStack(spacing: 14) {
            Text("Folder")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
            folderMenu
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var folderMenu: some View {
        Menu {
            Button("Uncategorized") {
                selectedFolder = "Uncategorized"
            }

            ForEach(existingFolders, id: \.self) { folder in
                Button(folder) {
                    selectedFolder = folder
                }
            }

            Divider()

            Button("Create New Folder...") {
                isShowingCreateFolderPrompt = true
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedFolder)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.secondarySurface)
            )
        }
        .buttonStyle(.plain)
    }

    private var resolvedDisclosure: some View {
        DisclosureGroup(isExpanded: $isResolvedListExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(saveItems) { item in
                    resolvedItemCard(for: item)
                }
            }
            .padding(.top, 12)
        } label: {
            Text(resolvedSectionTitle)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func resolvedItemCard(for item: ScriptureAddSaveItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.reference)
                    .font(.headline)

                if duplicateItems.contains(item) {
                    Text("Already Saved")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.gold.opacity(0.14)))
                        .foregroundStyle(AppColors.warning)
                }

                Spacer(minLength: 0)
            }

            Text(item.text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var unresolvedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(context.unresolvedEntries.count == 1 ? "Unresolved Reference" : "Unresolved References (\(context.unresolvedEntries.count))")
                .font(.headline)

            Text("These reference attempts could not be parsed or resolved and will not be saved.")
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
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                save()
            } label: {
                Text(isSaving ? "Saving..." : saveButtonTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(readyItems.isEmpty ? AppColors.textSecondary : AppColors.reviewPracticingActionText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(readyItems.isEmpty ? AppColors.secondarySurface : AppColors.reviewPracticingActionBackground)
                    )
                    .overlay {
                        Capsule()
                            .stroke(AppColors.divider.opacity(0.9), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(isSaving || readyItems.isEmpty)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var normalizedCandidateFolderName: String? {
        let normalizedName = ScriptureAddPipeline.normalizedFolderName(newFolderName)
        return normalizedName.isEmpty ? nil : normalizedName
    }

    private var summaryTitle: String {
        if readyItems.isEmpty {
            return duplicateItems.isEmpty ? "Nothing new to save" : "Everything is already saved"
        }

        return readyItems.count == 1 ? "1 verse ready to save" : "\(readyItems.count) verses ready to save"
    }

    private var resolvedSectionTitle: String {
        saveItems.count == 1 ? "Identified Verse: 1" : "Identified Verses: \(saveItems.count)"
    }

    private var saveButtonTitle: String {
        if readyItems.isEmpty {
            return "Nothing New to Save"
        }

        return readyItems.count == 1 ? "Save Verse" : "Save \(readyItems.count) Verses"
    }

    private func createFolder() {
        guard let normalizedName = normalizedCandidateFolderName else {
            return
        }

        let savedFolder = existingFolders.first(where: {
            $0.compare(normalizedName, options: .caseInsensitive) == .orderedSame
        }) ?? normalizedName

        selectedFolder = savedFolder
        newFolderName = ""
    }

    private func save() {
        guard !isSaving, !readyItems.isEmpty else {
            return
        }

        isSaving = true
        let options = ScriptureSaveOptions(folderName: selectedFolder)

        for item in readyItems {
            onSave(ScriptureAddPipeline.makeVerse(from: item, options: options))
        }

        let skippedCount = duplicateItems.count
        successMessage = skippedCount > 0
            ? "\(readyItems.count) saved • \(skippedCount) skipped"
            : (readyItems.count == 1 ? "1 verse added" : "\(readyItems.count) verses added")

        Task {
            try? await Task.sleep(for: .seconds(1.1))
            await MainActor.run {
                isSaving = false
                onComplete?()
                if onComplete == nil {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddVerseView(onSave: { _ in })
    }
}
