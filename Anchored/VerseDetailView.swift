import SwiftUI

struct VerseDetailView: View {
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
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .background(primaryCTAColor)
                .foregroundStyle(primaryCTATextColor)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: isLightMode ? AppColors.structuralAccent.opacity(0.14) : .clear, radius: 12, y: 6)

                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("Status")
                    statusCard
                    masteryPicker

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

                    VStack(spacing: 0) {
                        folderRow
                        detailDivider
                        detailRow(title: "Added", value: addedDateText)
                        detailDivider
                        detailRow(title: "Times Reviewed", value: "\(currentVerse.reviewCount)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(AppColors.surface)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppColors.divider, lineWidth: 1)
                    }
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete Verse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(isLightMode ? AppColors.weakness : AppColors.warning)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, BottomNavigationShellLayout.overlayClearance + 28)
        }
        .navigationTitle("Verse")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
        .tint(AppColors.structuralAccent)
        .onChange(of: verse) { _, newValue in
            currentVerse = newValue
        }
        .sheet(item: $reviewStartConfiguration) { configuration in
            ReviewStartSheet(configuration: configuration) { method in
                onStartReview(currentVerse, method)
            }
        }
        .sheet(isPresented: $isShowingMoveSheet) {
            FolderDestinationSheet(
                title: "Move to Folder",
                currentFolderName: currentVerse.folderName,
                additionalFolders: []
            ) { folderName in
                moveVerse(to: folderName)
            }
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

    private var masteryPicker: some View {
        HStack(spacing: 10) {
            ForEach(VerseMasteryStatus.allCases) { status in
                let isSelected = currentVerse.masteryStatus == status

                Button {
                    updateMasteryStatus(to: status)
                } label: {
                    Text(status.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isSelected ? selectionFillColor : controlSurfaceColor)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(isSelected ? selectionStrokeColor : AppColors.divider, lineWidth: 1)
                        }
                        .foregroundStyle(isSelected ? selectionTextColor : AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(controlTrayColor)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
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

    private var detailDivider: some View {
        Divider()
            .overlay(AppColors.divider)
    }

    private var folderRow: some View {
        Button {
            isShowingMoveSheet = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("Folder")
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                HStack(spacing: 8) {
                    Text(folderName)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.trailing)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColors.structuralAccent)
                }
            }
            .font(.subheadline)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
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
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(currentVerse.masteryStatus.tintColor.opacity(0.18), lineWidth: 1)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
    }

    private var scriptureSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Scripture")

                Text(currentVerse.reference)
                    .font(.system(size: 31, weight: .bold, design: .serif))
                    .foregroundStyle(referenceColor)
            }

            Text(currentVerse.text)
                .font(.system(size: 19, weight: .regular, design: .serif))
                .lineSpacing(6)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(scriptureSurfaceColor)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(scriptureBorderColor, lineWidth: 1)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
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

    private var scriptureBorderColor: Color {
        isLightMode ? AppColors.divider.opacity(0.9) : AppColors.divider
    }

    private var controlSurfaceColor: Color {
        isLightMode ? AppColors.surface : AppColors.elevatedSurface
    }

    private var controlTrayColor: Color {
        isLightMode ? AppColors.secondarySurface : AppColors.surface
    }

    private var referenceColor: Color {
        isLightMode ? AppColors.structuralAccent : AppColors.scriptureAccent
    }

    private var primaryCTAColor: Color {
        isLightMode ? AppColors.structuralAccent : AppColors.primaryButton
    }

    private var primaryCTATextColor: Color {
        isLightMode ? AppColors.surface : AppColors.primaryButtonText
    }

    private var selectionFillColor: Color {
        isLightMode ? AppColors.structuralAccent.opacity(0.12) : AppColors.selectionFill
    }

    private var selectionStrokeColor: Color {
        isLightMode ? AppColors.structuralAccent.opacity(0.35) : AppColors.structuralAccent.opacity(0.24)
    }

    private var selectionTextColor: Color {
        isLightMode ? AppColors.structuralAccent : AppColors.textPrimary
    }

    private var statusSummary: String {
        switch currentVerse.masteryStatus {
        case .practicing:
            return "Still working on this verse. A successful review will move it to Memorized."
        case .memorized:
            return "You currently know this verse well. A missed review will move it back to Practicing."
        }
    }

    private func updateMasteryStatus(to status: VerseMasteryStatus) {
        guard currentVerse.masteryStatus != status else {
            return
        }

        guard let updatedVerse = VerseRepository.shared.updateMasteryStatus(forVerseID: currentVerse.id, to: status) else {
            return
        }

        currentVerse = updatedVerse
        onVerseUpdated(updatedVerse)
    }

    private func moveVerse(to folderName: String) {
        guard let updatedVerse = VerseRepository.shared.moveVerse(id: currentVerse.id, toFolder: folderName) else {
            return
        }

        currentVerse = updatedVerse
        onVerseUpdated(updatedVerse)
    }

    private func deleteVerse() {
        VerseRepository.shared.softDeleteVerse(id: currentVerse.id)
        let deletedVerse = currentVerse
        dismiss()
        onVerseDeleted(deletedVerse)
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
