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
    @State private var didSave = false

    private var existingFolders: [String] {
        var normalizedFolders = Set(
            VerseRepository.shared.loadVerses().map { ScriptureAddPipeline.normalizedFolderName($0.folderName) }
        )
        normalizedFolders.remove("Uncategorized")
        if selectedFolder != "Uncategorized" {
            normalizedFolders.insert(selectedFolder)
        }
        return normalizedFolders.sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard

                ForEach(passages) { passage in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(passage.normalizedReference)
                            .font(.headline)

                        Text(passage.text)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(.primary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                folderSection
                statusSection

                if didSave {
                    AddFlowMessageCard(message: "Verses saved.", tint: .green)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    savePassages()
                }
                .fontWeight(.semibold)
            }
        }
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

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folder")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Menu {
                Button("Uncategorized") {
                    selectedFolder = "Uncategorized"
                }

                ForEach(existingFolders, id: \.self) { folder in
                    Button(folder) {
                        selectedFolder = folder
                    }
                }
            } label: {
                HStack {
                    Text(selectedFolder)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)

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
                                .fill(Color(.secondarySystemBackground))
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

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Picker("Status", selection: $masteryStatus) {
                ForEach(VerseMasteryStatus.allCases) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var normalizedCandidateFolderName: String? {
        let normalizedName = ScriptureAddPipeline.normalizedFolderName(newFolderName)
        return normalizedName.isEmpty ? nil : normalizedName
    }

    private func saveNewFolder() {
        guard let normalizedName = normalizedCandidateFolderName else {
            return
        }

        selectedFolder = existingFolders.first(where: {
            $0.compare(normalizedName, options: .caseInsensitive) == .orderedSame
        }) ?? normalizedName
        newFolderName = ""
        isAddingNewFolder = false
    }

    private func savePassages() {
        let verses = ScriptureAddPipeline.makeVerses(
            from: passages,
            options: ScriptureSaveOptions(folderName: selectedFolder, masteryStatus: masteryStatus)
        )

        for verse in verses {
            onSaveVerse(verse)
        }

        didSave = true
        onComplete?()
        if onComplete == nil {
            dismiss()
        }
    }
}
