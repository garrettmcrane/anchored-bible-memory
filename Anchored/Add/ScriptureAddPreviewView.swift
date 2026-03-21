import SwiftUI

struct ScriptureAddPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let passages: [ScripturePassage]
    let onSaveVerse: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var selectedFolder = "Uncategorized"
    @State private var isAddingNewFolder = false
    @State private var newFolderName = ""
    @State private var masteryStatus: VerseMasteryStatus = .learning
    @State private var folderOverrides: [String: String] = [:]
    @State private var successMessage: String?
    @State private var isSaving = false

    private var existingFolders: [String] {
        var normalizedFolders = Set(
            VerseRepository.shared.loadVerses().map { ScriptureAddPipeline.normalizedFolderName($0.folderName) }
        )
        normalizedFolders.remove("Uncategorized")
        if selectedFolder != "Uncategorized" {
            normalizedFolders.insert(selectedFolder)
        }
        for folder in folderOverrides.values where folder != "Uncategorized" {
            normalizedFolders.insert(folder)
        }
        return normalizedFolders.sorted()
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
        .background(Color(.systemGroupedBackground))
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

            Text("Single verses and ranges save as one unit. Separate references save separately.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var defaultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Status")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

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
                    .foregroundStyle(.secondary)

                folderMenu(
                    selection: selectedFolder,
                    title: selectedFolder,
                    tint: .primary
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
                                    .fill(Color(.systemBackground))
                            )

                        Button("Save Folder") {
                            saveNewFolder()
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.blue.opacity(0.12))
                        )
                        .disabled(normalizedCandidateFolderName == nil)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var saveButton: some View {
        Button {
            savePassages()
        } label: {
            Text(isSaving ? "Saving..." : "Save Verses")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
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
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }

            HStack {
                Text("Folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                let override = folderOverride(for: passage)
                folderMenu(
                    selection: override ?? selectedFolder,
                    title: override ?? "Use Default",
                    tint: override == nil ? .secondary : .primary,
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
                .fill(Color(.secondarySystemBackground))
        )
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
                    .fill(Color(.systemBackground))
            )
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
