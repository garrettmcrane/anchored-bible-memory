import SwiftUI

struct AddVerseView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (Verse) -> Void

    @State private var reference = ""
    @State private var text = ""
    @State private var lookupMessage: String?

    private var canSave: Bool {
        !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reference") {
                    TextField("John 3:16", text: $reference)
                        .textInputAutocapitalization(.words)
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
            }
            .navigationTitle("Add Verse")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let newVerse = Verse(
                            reference: reference.trimmingCharacters(in: .whitespacesAndNewlines),
                            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(newVerse)
                        dismiss()
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
        } else {
            lookupMessage = "No match found in the local sample library yet. You can still paste the text manually."
        }
    }
}

#Preview {
    AddVerseView(onSave: { _ in })
}
