import SwiftUI

struct ScriptureAddPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let passages: [ScripturePassage]
    let onSaveVerse: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var selectedFolder = "Uncategorized"
    @State private var isAddingNewFolder = false
    @State private var newFolderName = ""
    @State private var masteryStatus: VerseMasteryStatus = .practicing
    @State private var folderOverrides: [String: String] = [:]
    @State private var successMessage: String?
    @State private var isSaving = false

    private var existingFolders: [String] {
        ScriptureAddPipeline.existingFolderNames(
            including: [selectedFolder] + Array(folderOverrides.values)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                saveButton
                defaultsCard

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(passages) { passage in
                        previewCard(for: passage)
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Preview")
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
        VStack(alignment: .leading, spacing: 8) {
            Text(passages.count == 1 ? "1 memorization item ready" : "\(passages.count) memorization items ready")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Single verses and ranges save as one unit. Separate references save separately.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.secondarySurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var defaultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Status")
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
                                .fill(AppColors.selectionFill)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppColors.divider, lineWidth: 1)
                        }
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
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var saveButton: some View {
        Button {
            savePassages()
        } label: {
            Text(isSaving ? "Saving..." : "Save Verses")
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primaryButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(AppColors.primaryButton)
                )
                .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func previewCard(for passage: ScripturePassage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(passage.normalizedReference)
                        .font(.headline)

                    Text(passage.text)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer(minLength: 0)
            }

            HStack {
                Text("Folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                let override = folderOverride(for: passage)
                folderMenu(
                    selection: override ?? selectedFolder,
                    title: override ?? "Use Default",
                    tint: override == nil ? AppColors.textSecondary : AppColors.textPrimary,
                    onSelect: { folder in
                    if folder == selectedFolder {
                        folderOverrides.removeValue(forKey: passage.id)
                    } else {
                        folderOverrides[passage.id] = folder
                    }
                },
                    includeUseDefault: true
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private func folderMenu(
        selection: String,
        title: String,
        tint: Color,
        onSelect: @escaping (String) -> Void,
        includeUseDefault: Bool = false
    ) -> some View {
        Menu {
            if includeUseDefault {
                Button("Use Default Folder") {
                    onSelect(selectedFolder)
                }
            }

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
                    .fill(AppColors.elevatedSurface)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func folderOverride(for passage: ScripturePassage) -> String? {
        folderOverrides[passage.id]
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

    private func savePassages() {
        guard !isSaving else {
            return
        }

        isSaving = true

        for passage in passages {
            let folderName = folderOverride(for: passage) ?? selectedFolder
            let verse = ScriptureAddPipeline.makeVerse(
                from: passage,
                options: ScriptureSaveOptions(folderName: folderName, masteryStatus: masteryStatus)
            )
            onSaveVerse(verse)
        }

        successMessage = passages.count == 1 ? "1 verse added" : "\(passages.count) verses added"

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
