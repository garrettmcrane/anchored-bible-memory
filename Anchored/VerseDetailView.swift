import SwiftUI

struct VerseDetailView: View {
    fileprivate struct VerseEditDraft: Equatable {
        var reference: String
        var text: String
        var folderName: String
        var masteryStatus: VerseMasteryStatus

        init(reference: String, text: String, folderName: String, masteryStatus: VerseMasteryStatus) {
            self.reference = reference
            self.text = text
            self.folderName = folderName
            self.masteryStatus = masteryStatus
        }

        var normalizedReference: String {
            reference
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        var normalizedText: String {
            text
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        var isValid: Bool {
            !normalizedReference.isEmpty && !normalizedText.isEmpty
        }
    }

    private static let uncategorizedFolderName = "Uncategorized"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let verse: Verse
    let onStartReview: (Verse, ReviewMethod) -> Void
    let onVerseUpdated: (Verse) -> Void
    let onVerseDeleted: (Verse) -> Void

    @State private var currentVerse: Verse
    @State private var reviewStartConfiguration: ReviewStartConfiguration?
    @State private var isShowingMoveSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditSheet = false
    @State private var editDraft: VerseEditDraft

    init(
        verse: Verse,
        onStartReview: @escaping (Verse, ReviewMethod) -> Void,
        onVerseUpdated: @escaping (Verse) -> Void = { _ in },
        onVerseDeleted: @escaping (Verse) -> Void = { _ in }
    ) {
        self.verse = verse
        self.onStartReview = onStartReview
        self.onVerseUpdated = onVerseUpdated
        self.onVerseDeleted = onVerseDeleted
        _currentVerse = State(initialValue: verse)
        _editDraft = State(initialValue: VerseEditDraft(reference: verse.reference, text: verse.text, folderName: verse.folderName, masteryStatus: verse.masteryStatus))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                scriptureSection
                    .padding(.top, 20)

                Button {
                    reviewStartConfiguration = ReviewStartConfiguration(
                        title: "Review Verse",
                        description: "Choose a review method for \(currentVerse.reference).",
                        verses: [currentVerse]
                    )
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Start Review")
                    }
                }
                .buttonStyle(AnchoredPrimaryButtonStyle())

                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("Status")
                    statusCard

                    HStack(spacing: 12) {
                        signalCard(
                            title: "Last Reviewed",
                            value: lastReviewedText,
                            valueColor: lastReviewedColor
                        )

                        signalCard(
                            title: "Total Reviews",
                            value: "\(currentVerse.reviewCount)",
                            valueColor: AppColors.textPrimary
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("Details")

                    VStack(spacing: 12) {
                        detailRow(title: "Added", value: addedDateText)
                        detailRow(title: "Folder", value: folderName)
                        detailRow(title: "Status", value: currentVerse.masteryStatus.rawValue)
                        detailRow(title: "Times Reviewed", value: "\(currentVerse.reviewCount)")
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(AppColors.surface)
                    )
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete Verse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AnchoredDestructiveButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, BottomOverlayLayout.overlayClearance + 28)
        }
        .navigationTitle("Verse")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
        .tint(AppColors.structuralAccent)
        .onChange(of: verse) { _, newValue in
            currentVerse = newValue
            editDraft = VerseEditDraft(reference: newValue.reference, text: newValue.text, folderName: newValue.folderName, masteryStatus: newValue.masteryStatus)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    editDraft = VerseEditDraft(reference: currentVerse.reference, text: currentVerse.text, folderName: currentVerse.folderName, masteryStatus: currentVerse.masteryStatus)
                    isShowingEditSheet = true
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(item: $reviewStartConfiguration) { configuration in
            ReviewStartSheet(configuration: configuration) { method in
                onStartReview(currentVerse, method)
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            VerseEditSheet(
                draft: $editDraft,
                currentFolderName: currentVerse.folderName,
                onSave: saveEditedVerse
            )
        }
        .confirmationDialog("Delete Verse?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteVerse()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var folderName: String {
        let trimmedFolderName = currentVerse.folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsedWhitespaceFolderName = trimmedFolderName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsedWhitespaceFolderName.isEmpty else {
            return Self.uncategorizedFolderName
        }

        return collapsedWhitespaceFolderName.lowercased().localizedCapitalized
    }

    private var lastReviewedText: String {
        guard let lastReviewedAt = currentVerse.lastReviewedAt else {
            return "Not reviewed yet"
        }

        let calendar = Calendar.current

        if calendar.isDateInToday(lastReviewedAt) {
            return "Today"
        }

        if calendar.isDateInYesterday(lastReviewedAt) {
            return "Yesterday"
        }

        let daysAgo = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastReviewedAt),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        return "\(max(daysAgo, 0)) days ago"
    }

    private var lastReviewedColor: Color {
        currentVerse.masteryStatus.tintColor
    }

    private var addedDateText: String {
        currentVerse.createdAt.formatted(.dateTime.month(.wide).day().year())
    }

    private func signalCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.6)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(controlSurfaceColor)
        )
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(currentVerse.masteryStatus.badgeTitle, systemImage: currentVerse.masteryStatus.iconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(currentVerse.masteryStatus.tintColor)

            Text(statusSummary)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(currentVerse.masteryStatus.subtleFillColor)
        )
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(AnchoredFont.uiSubheadline)
        .padding(.vertical, 12)
    }

    private var scriptureSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Scripture")

                Text(currentVerse.reference)
                    .font(AnchoredFont.editorial(32))
                    .foregroundStyle(referenceColor)
            }

            Text(currentVerse.text)
                .font(AnchoredFont.scripture(25))
                .lineSpacing(8)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(scriptureSurfaceColor)
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(AnchoredFont.uiCaption)
            .foregroundStyle(AppColors.textSecondary)
            .tracking(0.8)
            .textCase(.uppercase)
    }

    private var isLightMode: Bool {
        colorScheme == .light
    }

    private var scriptureSurfaceColor: Color {
        isLightMode ? AppColors.surface : AppColors.elevatedSurface
    }

    private var controlSurfaceColor: Color {
        isLightMode ? AppColors.surface : AppColors.elevatedSurface
    }

    private var referenceColor: Color {
        isLightMode ? AppColors.structuralAccent : AppColors.scriptureAccent
    }

    private var statusSummary: String {
        switch currentVerse.masteryStatus {
        case .practicing:
            return "Still working on this verse. A successful review will move it to Memorized."
        case .memorized:
            return "You currently know this verse well. A missed review will move it back to Learning."
        }
    }

    private func deleteVerse() {
        VerseRepository.shared.softDeleteVerse(id: currentVerse.id)
        let deletedVerse = currentVerse
        dismiss()
        onVerseDeleted(deletedVerse)
    }

    private func saveEditedVerse() {
        guard let updatedVerse = VerseRepository.shared.updateVerseContent(
            forVerseID: currentVerse.id,
            reference: editDraft.normalizedReference,
            text: editDraft.normalizedText
        ) else {
            return
        }

        var finalVerse = updatedVerse

        if updatedVerse.masteryStatus != editDraft.masteryStatus,
           let masteryUpdatedVerse = VerseRepository.shared.updateMasteryStatus(forVerseID: updatedVerse.id, to: editDraft.masteryStatus) {
            finalVerse = masteryUpdatedVerse
        }

        if ScriptureAddPipeline.normalizedFolderName(finalVerse.folderName) != ScriptureAddPipeline.normalizedFolderName(editDraft.folderName),
           let movedVerse = VerseRepository.shared.moveVerse(id: finalVerse.id, toFolder: editDraft.folderName) {
            finalVerse = movedVerse
        }

        currentVerse = finalVerse
        editDraft = VerseEditDraft(reference: finalVerse.reference, text: finalVerse.text, folderName: finalVerse.folderName, masteryStatus: finalVerse.masteryStatus)
        isShowingEditSheet = false
        onVerseUpdated(finalVerse)
    }
}

private struct VerseEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: VerseDetailView.VerseEditDraft
    let currentFolderName: String
    let onSave: () -> Void

    @State private var isShowingFolderSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reference") {
                    TextField("John 3:16", text: $draft.reference, axis: .vertical)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section("Verse Text") {
                    TextField("Enter verse text", text: $draft.text, axis: .vertical)
                        .lineLimit(6...12)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Status") {
                    Picker("Status", selection: $draft.masteryStatus) {
                        ForEach(VerseMasteryStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Folder") {
                    Button {
                        isShowingFolderSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Text("Folder")
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()

                            Text(displayFolderName)
                                .foregroundStyle(AppColors.textSecondary)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if draft.folderName.trimmingCharacters(in: .whitespacesAndNewlines) != currentFolderName.trimmingCharacters(in: .whitespacesAndNewlines) {
                        Text("This verse will move to the updated folder when you save.")
                            .font(.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Edit Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!draft.isValid)
                }
            }
            .sheet(isPresented: $isShowingFolderSheet) {
                FolderDestinationSheet(
                    title: "Choose Folder",
                    currentFolderName: draft.folderName,
                    additionalFolders: []
                ) { folderName in
                    if ScriptureAddPipeline.normalizedFolderName(folderName) == "Uncategorized" {
                        draft.folderName = ""
                    } else {
                        draft.folderName = folderName
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var displayFolderName: String {
        let normalizedFolder = ScriptureAddPipeline.normalizedFolderName(draft.folderName)
        return normalizedFolder.isEmpty ? "No Folder" : normalizedFolder
    }
}

#Preview {
    NavigationStack {
        VerseDetailView(
            verse: Verse(
                reference: "Romans 8:28",
                text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
                folderName: "Encouragement",
                correctCount: 2,
                reviewCount: 3,
                createdAt: .now.addingTimeInterval(-86400 * 14),
                lastReviewedAt: .now.addingTimeInterval(-86400)
            ),
            onStartReview: { _, _ in }
        )
    }
    .preferredColorScheme(.light)
}
