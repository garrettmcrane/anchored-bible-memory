import SwiftUI
import UIKit

struct AddVerseView: View {
    private static let uncategorizedFolder = "Uncategorized"

    private enum Field {
        case reference
        case text
        case newFolder
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var showsCancelButton: Bool = true
    var focusTrigger: Int = 0
    let onSave: (Verse) -> Void

    @State private var reference = ""
    @State private var text = ""
    @State private var folderName = Self.uncategorizedFolder
    @State private var selectedFolder: String = Self.uncategorizedFolder
    @State private var isAddingNewFolder = false
    @State private var newFolderName = ""
    @State private var masteryStatus: VerseMasteryStatus = .learning
    @State private var lookupMessage: String?
    @State private var referenceFocusRequestID = 0
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
                    AutoFocusReferenceField(
                        text: $reference,
                        focusRequestID: referenceFocusRequestID,
                        onSubmit: {
                            autoFillVerseIfPossible()
                        }
                    )
                    .frame(minHeight: 22)

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
                        .focused($focusedField, equals: .text)
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
                                    .focused($focusedField, equals: .newFolder)
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

                Section("Status") {
                    Picker("Status", selection: $masteryStatus) {
                        ForEach(VerseMasteryStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Verse")
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                folderName = selectedFolder
                requestReferenceFocus(after: 0.3)
            }
            .task {
                requestReferenceFocus(after: 0.3)
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else {
                    return
                }

                requestReferenceFocus(after: 0.3)
            }
            .onChange(of: focusTrigger) { _, _ in
                requestReferenceFocus(after: 0.3)
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
                            folderName: selectedFolder,
                            isMastered: masteryStatus == .memorized
                        )
                        onSave(newVerse)
                        handleSuccessfulSave()
                    }
                    .disabled(!canSave)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        dismissKeyboard()
                    }
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
            dismissKeyboard()
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
            masteryStatus = .learning
            lookupMessage = "Verse saved."

            requestReferenceFocus(after: 0.3)
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

        dismissKeyboard()
    }

    private func selectFolder(_ folder: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFolder = folder
        }
    }

    private func requestReferenceFocus(after delay: TimeInterval) {
        Task { @MainActor in
            let delayInNanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayInNanoseconds)
            referenceFocusRequestID += 1
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

private struct AutoFocusReferenceField: UIViewRepresentable {
    @Binding var text: String
    let focusRequestID: Int
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeUIView(context: Context) -> ReferenceFieldContainerView {
        let containerView = ReferenceFieldContainerView()
        let textField = containerView.textField

        textField.borderStyle = .none
        textField.placeholder = "John 3:16"
        textField.autocapitalizationType = .words
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)

        containerView.onTap = {
            textField.requestFirstResponder()
        }

        return containerView
    }

    func updateUIView(_ uiView: ReferenceFieldContainerView, context: Context) {
        if uiView.textField.text != text {
            uiView.textField.text = text
        }

        if context.coordinator.lastFocusRequestID != focusRequestID {
            context.coordinator.lastFocusRequestID = focusRequestID
            uiView.textField.requestFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onSubmit: () -> Void
        var lastFocusRequestID = -1

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            _text = text
            self.onSubmit = onSubmit
        }

        @objc
        func textDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return true
        }
    }
}

private final class ReferenceFieldContainerView: UIView {
    let textField = FocusableTextField()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}

private final class FocusableTextField: UITextField {
    private var pendingFocusWorkItem: DispatchWorkItem?

    func requestFirstResponder() {
        pendingFocusWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            guard window != nil else {
                requestFirstResponder()
                return
            }

            becomeFirstResponder()
        }

        pendingFocusWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
}

#Preview {
    AddVerseView(onSave: { _ in })
}
