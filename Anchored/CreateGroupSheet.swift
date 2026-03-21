import SwiftUI

struct CreateGroupSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (String) -> Void

    @State private var groupName = ""
    @FocusState private var isNameFieldFocused: Bool

    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("Sunday Memory Group", text: $groupName)
                        .textInputAutocapitalization(.words)
                        .focused($isNameFieldFocused)
                }

                Section {
                    Text("You’ll be added as the owner and first member.")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(trimmedGroupName)
                        dismiss()
                    }
                    .disabled(trimmedGroupName.isEmpty)
                }
            }
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}
