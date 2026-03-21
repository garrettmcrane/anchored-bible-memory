import SwiftUI

struct FolderDestinationSheet: View {
    private static let uncategorizedFolderName = "Uncategorized"

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNewFolderFieldFocused: Bool

    let title: String
    let currentFolderName: String
    let additionalFolders: [String]
    let onSelect: (String) -> Void

    @State private var newFolderName = ""

    private var normalizedCurrentFolderName: String {
        let normalizedFolderName = ScriptureAddPipeline.normalizedFolderName(currentFolderName)
        return normalizedFolderName.isEmpty ? Self.uncategorizedFolderName : normalizedFolderName
    }

    private var existingFolders: [String] {
        ScriptureAddPipeline
            .existingFolderNames(including: additionalFolders + [normalizedCurrentFolderName])
            .filter { $0 != Self.uncategorizedFolderName }
    }

    private var normalizedNewFolderName: String {
        ScriptureAddPipeline.normalizedFolderName(newFolderName)
    }

    private var canCreateFolder: Bool {
        !normalizedNewFolderName.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Move To") {
                    folderRow(title: Self.uncategorizedFolderName)

                    ForEach(existingFolders, id: \.self) { folder in
                        folderRow(title: folder)
                    }
                }

                Section("Create New Folder") {
                    TextField("Folder name", text: $newFolderName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isNewFolderFieldFocused)

                    Button("Create and Move") {
                        submitNewFolder()
                    }
                    .disabled(!canCreateFolder)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func folderRow(title: String) -> some View {
        Button {
            selectFolder(title)
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundStyle(AppColors.lightTextPrimary)

                Spacer()

                if title == normalizedCurrentFolderName {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.lightTextSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func submitNewFolder() {
        guard canCreateFolder else {
            isNewFolderFieldFocused = true
            return
        }

        selectFolder(normalizedNewFolderName)
    }

    private func selectFolder(_ folderName: String) {
        onSelect(folderName)
        dismiss()
    }
}

