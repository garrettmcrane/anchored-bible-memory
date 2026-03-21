import SwiftUI

struct AssignVersesSheet: View {
    @Environment(\.dismiss) private var dismiss

    let availableVerses: [Verse]
    let onAssign: (Set<String>) -> Void
    let onAddNewVerse: () -> Void

    @State private var selectedVerseIDs: Set<String> = []

    private var assignButtonTitle: String {
        selectedVerseIDs.isEmpty ? "Assign" : "Assign \(selectedVerseIDs.count)"
    }

    var body: some View {
        NavigationStack {
            VStack {
                if availableVerses.isEmpty {
                    ContentUnavailableView(
                        "No Verses Ready to Assign",
                        systemImage: "books.vertical",
                        description: Text("Add a new verse or choose from your personal memorization library once verses are available.")
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
                            Text("Assigned passages stay separate from your personal memorization library.")
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

                ToolbarItem(placement: .bottomBar) {
                    Button("Add New Verse") {
                        dismiss()
                        onAddNewVerse()
                    }
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
