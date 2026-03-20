import SwiftUI

struct AddVerseView: View {
    private static let uncategorizedFolder = "Uncategorized"

    private enum Field {
        case reference
    }

    @Environment(\.dismiss) private var dismiss

    var showsCancelButton: Bool = true
    let onSave: (Verse) -> Void

    @State private var reference = ""
    @State private var text = ""
    @State private var folderName = Self.uncategorizedFolder
    @State private var selectedFolder: String = Self.uncategorizedFolder
    @State private var isAddingNewFolder = false
    @State private var newFolderName = ""
    @State private var lookupMessage: String?
    @FocusState private var focusedField: Field?

    private var canSave: Bool {
        !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var existingFolders: [String] {
        var normalizedFolders = Set(
            VerseRepository.shared.loadVerses().map { normalizedFolderName($0.folderName) }
        )

        normalizedFolders.remove(Self.uncategorizedFolder)

        if selectedFolder != Self.uncategorizedFolder {
            normalizedFolders.insert(selectedFolder)
        }

        return normalizedFolders.sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reference") {
                    TextField("John 3:16", text: $reference)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .reference)
                        .onSubmit {
                            autoFillVerseIfPossible()
                        }

                    Button("Auto-Fill Verse Text") {
                        autoFillVerseIfPossible()
                    }

                    if let lookupMessage {
                        Text(lookupMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Verse Text") {
                    TextField("Paste the verse text here", text: $text, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section("Folder") {
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAddingNewFolder.toggle()
                            }
                        } label: {
                            folderCard(
                                title: "Add New Folder",
                                systemImage: "chevron.right",
                                isSelected: false,
                                tint: Color(.secondarySystemBackground)
                            )
                        }
                        .buttonStyle(.plain)

                        if isAddingNewFolder {
                            HStack(spacing: 12) {
                                TextField("New folder name", text: $newFolderName)
                                    .textInputAutocapitalization(.words)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        saveNewFolder()
                                    }

                                Button("Save") {
                                    saveNewFolder()
                                }
                                .fontWeight(.semibold)
                                .disabled(normalizedCandidateFolderName == nil)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }

                        Button {
                            selectFolder(Self.uncategorizedFolder)
                        } label: {
                            folderCard(
                                title: Self.uncategorizedFolder,
                                systemImage: "checkmark",
                                isSelected: selectedFolder == Self.uncategorizedFolder,
                                tint: selectedFolder == Self.uncategorizedFolder ? Color.blue.opacity(0.14) : Color(.secondarySystemBackground)
                            )
                        }
                        .buttonStyle(.plain)

                        ForEach(existingFolders, id: \.self) { folder in
                            Button {
                                selectFolder(folder)
                            } label: {
                                folderCard(
                                    title: folder,
                                    systemImage: "checkmark",
                                    isSelected: selectedFolder == folder,
                                    tint: selectedFolder == folder ? Color.blue.opacity(0.14) : Color(.secondarySystemBackground)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Verse")
            .onAppear {
                folderName = selectedFolder
                DispatchQueue.main.async {
                    focusedField = .reference
                }
            }
            .onChange(of: selectedFolder) { _, newValue in
                folderName = newValue
            }
            .toolbar {
                if showsCancelButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let newVerse = Verse(
                            reference: reference.trimmingCharacters(in: .whitespacesAndNewlines),
                            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                            folderName: selectedFolder
                        )
                        onSave(newVerse)
                        handleSuccessfulSave()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func autoFillVerseIfPossible() {
        let cleanedReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedReference.isEmpty else {
            lookupMessage = "Enter a reference first."
            return
        }

        if let foundText = VerseReferenceLibrary.lookup(reference: cleanedReference) {
            text = foundText
            lookupMessage = "Verse text found and filled in automatically."
            focusedField = nil
        } else {
            lookupMessage = "No match found in the local sample library yet. You can still paste the text manually."
        }
    }

    private func handleSuccessfulSave() {
        if showsCancelButton {
            dismiss()
        } else {
            reference = ""
            text = ""
            selectedFolder = Self.uncategorizedFolder
            folderName = Self.uncategorizedFolder
            isAddingNewFolder = false
            newFolderName = ""
            lookupMessage = "Verse saved."

            DispatchQueue.main.async {
                focusedField = .reference
            }
        }
    }

    @ViewBuilder
    private func folderCard(
        title: String,
        systemImage: String,
        isSelected: Bool,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .blue : .secondary)
                .opacity(isSelected || systemImage == "chevron.right" ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.22) : Color.clear, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var normalizedCandidateFolderName: String? {
        let normalizedName = normalizedFolderName(newFolderName)
        return normalizedName.isEmpty ? nil : normalizedName
    }

    private func saveNewFolder() {
        guard let normalizedName = normalizedCandidateFolderName else {
            return
        }

        if let matchingFolder = existingFolders.first(where: {
            $0.compare(normalizedName, options: .caseInsensitive) == .orderedSame
        }) {
            selectFolder(matchingFolder)
        } else {
            selectFolder(normalizedName)
        }

        newFolderName = ""

        withAnimation(.easeInOut(duration: 0.2)) {
            isAddingNewFolder = false
        }
    }

    private func selectFolder(_ folder: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFolder = folder
        }
    }

    private func normalizedFolderName(_ folderName: String) -> String {
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

#Preview {
    AddVerseView(onSave: { _ in })
}
