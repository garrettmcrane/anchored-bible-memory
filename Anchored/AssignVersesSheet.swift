import SwiftUI

struct AssignVersesSheet: View {
    @Environment(\.dismiss) private var dismiss

    let availableVerses: [Verse]
    let onAssign: (Set<String>) -> Void

    @State private var selectedVerseIDs: Set<String> = []

    private var assignButtonTitle: String {
        selectedVerseIDs.isEmpty ? "Assign" : "Assign \(selectedVerseIDs.count)"
    }

    var body: some View {
        NavigationStack {
            VStack {
                if availableVerses.isEmpty {
                    ContentUnavailableView(
                        "No Personal Verses Left to Assign",
                        systemImage: "books.vertical",
                        description: Text("Add verses to your personal library first, or remove an existing assignment from this group.")
                    )
                    .padding(.horizontal, 24)
                } else {
                    List {
                        Section {
                            ForEach(availableVerses) { verse in
                                Button {
                                    toggleSelection(for: verse.id)
                                } label: {
                                    VerseRowView(
                                        verse: verse,
                                        showsChevron: false,
                                        selectionState: .init(isSelected: selectedVerseIDs.contains(verse.id))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        } footer: {
                            Text("Assignments stay separate from your personal library.")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Assign Passages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(assignButtonTitle) {
                        onAssign(selectedVerseIDs)
                        dismiss()
                    }
                    .disabled(selectedVerseIDs.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(for verseID: String) {
        if selectedVerseIDs.contains(verseID) {
            selectedVerseIDs.remove(verseID)
        } else {
            selectedVerseIDs.insert(verseID)
        }
    }
}
