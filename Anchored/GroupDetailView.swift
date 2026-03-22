import SwiftUI

struct GroupDetailView: View {
    private enum PendingActionConfirmation: String, Identifiable {
        case deleteGroup
        case leaveGroup

        var id: String {
            rawValue
        }
    }

    @Environment(\.dismiss) private var dismiss

    private struct AssignedPassage: Identifiable {
        let assignment: Assignment
        let verse: Verse
        let progress: GroupVerseProgress

        var id: String {
            assignment.id
        }
    }

    private struct BatchReviewPresentation: Identifiable {
        let id = UUID()
        let descriptor: ReviewSessionDescriptor
        let verses: [Verse]
    }

    @State private var group: Group
    @State private var memberships: [GroupMembership] = []
    @State private var assignedPassages: [AssignedPassage] = []
    @State private var availableVerses: [Verse] = []
    @State private var isShowingAssignSheet = false
    @State private var isShowingAddVerseSheet = false
    @State private var pendingConfirmation: PendingActionConfirmation?
    @State private var reviewStartConfiguration: ReviewStartConfiguration?
    @State private var activeBatchReview: BatchReviewPresentation?
    @State private var progressSummary = GroupProgressSummary(
        totalAssignedCount: 0,
        practicingCount: 0,
        memorizedCount: 0
    )

    init(group: Group) {
        _group = State(initialValue: group)
    }

    private var activeMembers: [GroupMembership] {
        memberships.filter(\.isActive)
    }

    private var ownerMembership: GroupMembership? {
        activeMembers.first(where: { $0.role == .owner })
    }

    private var memberCountText: String {
        "\(activeMembers.count) member\(activeMembers.count == 1 ? "" : "s")"
    }

    private var currentUserMembership: GroupMembership? {
        activeMembers.first(where: { $0.userID == LocalSession.currentUserID })
    }

    private var currentUserIsOwner: Bool {
        currentUserMembership?.role == .owner
    }

    private var reviewVerses: [Verse] {
        assignedPassages
            .sorted { lhs, rhs in
                let lhsRank = progressRank(lhs.progress.status)
                let rhsRank = progressRank(rhs.progress.status)

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                return lhs.assignment.assignedAt > rhs.assignment.assignedAt
            }
            .map(\.verse)
    }

    private var practicingReviewVerses: [Verse] {
        assignedPassages
            .filter { $0.progress.status == .practicing }
            .map(\.verse)
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    groupHeroSection
                    reviewSection
                    progressSection
                    assignedPassagesSection
                    membersSection
                    secondaryActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, BottomNavigationShellLayout.overlayClearance + 22)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAssignSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Assign verse")
            }
        }
        .sheet(isPresented: $isShowingAssignSheet) {
            AssignVersesSheet(
                availableVerses: availableVerses,
                onAssign: { verseIDs in
                    assignVerses(verseIDs)
                },
                onAddNewVerse: {
                    isShowingAddVerseSheet = true
                }
            )
        }
        .sheet(isPresented: $isShowingAddVerseSheet) {
            AddHubView(showsCancelButton: true) { newVerse in
                var groupVerse = newVerse
                groupVerse.sourceType = .groupAssignment
                VerseRepository.shared.addVerse(groupVerse)
                GroupRepository.shared.assignVerses(groupID: group.id, verseIDs: [groupVerse.id])
            } onComplete: {
                isShowingAddVerseSheet = false
                reloadGroup()
            }
        }
        .sheet(item: $reviewStartConfiguration) { configuration in
            ReviewStartSheet(configuration: configuration) { method in
                activeBatchReview = BatchReviewPresentation(
                    descriptor: ReviewSessionDescriptor(title: configuration.title, method: method),
                    verses: configuration.verses
                )
            }
        }
        .sheet(item: $activeBatchReview, onDismiss: reloadGroup) { presentation in
            switch presentation.descriptor.method {
            case .flashcard:
                ReviewSessionView(
                    descriptor: presentation.descriptor,
                    verses: presentation.verses,
                    onUpdate: { _ in },
                    groupID: group.id
                )
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewSessionView(
                    descriptor: presentation.descriptor,
                    verses: presentation.verses,
                    onUpdate: { _ in },
                    groupID: group.id
                )
            case .firstLetterTyping:
                FirstLetterTypingReviewSessionView(
                    descriptor: presentation.descriptor,
                    verses: presentation.verses,
                    onUpdate: { _ in },
                    groupID: group.id
                )
            case .voiceRecitation:
                VoiceRecitationReviewSessionView(
                    descriptor: presentation.descriptor,
                    verses: presentation.verses,
                    onUpdate: { _ in },
                    groupID: group.id
                )
            }
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationPresented,
            titleVisibility: .visible
        ) {
            if pendingConfirmation == .deleteGroup {
                Button("Delete Group", role: .destructive) {
                    deleteGroup()
                }
            }

            if pendingConfirmation == .leaveGroup {
                Button("Leave Group", role: .destructive) {
                    leaveGroup()
                }
            }

            Button("Cancel", role: .cancel) {
                pendingConfirmation = nil
            }
        } message: {
            Text(confirmationMessage)
        }
        .onAppear {
            reloadGroup()
        }
    }

    private var groupHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Keep shared passages, group review, and member context together in one place.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                heroStat(title: "Owner", value: ownerLabel)
                heroStat(title: "Members", value: activeMembers.count.formatted())
                heroStat(title: "Assigned", value: progressSummary.totalAssignedCount.formatted())
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Review", subtitle: "Start from the verses this group is actively working on.")

            HStack(spacing: 10) {
                reviewActionButton(
                    title: "Review Practicing",
                    tint: AppColors.primaryButton,
                    textColor: AppColors.primaryButtonText,
                    isEnabled: !practicingReviewVerses.isEmpty
                ) {
                    startGroupPracticingReview()
                }

                reviewActionButton(
                    title: "Review All",
                    tint: AppColors.surface,
                    textColor: AppColors.textPrimary,
                    isEnabled: !reviewVerses.isEmpty
                ) {
                    startGroupAllReview()
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Progress Summary")

            HStack(spacing: 12) {
                progressMetricCard(value: progressSummary.totalAssignedCount, title: "Assigned")
                progressMetricCard(value: progressSummary.practicingCount, title: "Practicing")
                progressMetricCard(value: progressSummary.memorizedCount, title: "Memorized")
            }
        }
    }

    private var assignedPassagesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                sectionHeader(title: "Assigned Passages", subtitle: assignedPassages.isEmpty ? "Nothing is assigned yet." : "\(assignedPassages.count) passage\(assignedPassages.count == 1 ? "" : "s") in this group")

                Spacer(minLength: 12)

                Button {
                    isShowingAssignSheet = true
                } label: {
                    Text("Assign")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
            }

            if assignedPassages.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Assign verses from your personal library or add new verses directly into the group.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)

                    HStack(spacing: 10) {
                        Button("Assign from Library") {
                            isShowingAssignSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primaryButton)

                        Button("Add New Verse") {
                            isShowingAddVerseSheet = true
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.structuralAccent)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
            } else {
                VStack(spacing: 12) {
                    ForEach(assignedPassages) { passage in
                        assignedPassageCard(for: passage)
                    }
                }
            }
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Members")

            NavigationLink {
                GroupMembersView(group: group, memberships: activeMembers)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppColors.subtleAccent)
                            .frame(width: 42, height: 42)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(memberCountText)
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Owner: \(ownerLabel)")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var secondaryActionsSection: some View {
        if currentUserIsOwner || currentUserMembership != nil {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "Group Settings")

                VStack(alignment: .leading, spacing: 12) {
                    Text(currentUserIsOwner
                         ? "Deleting removes the group and its assignments from this device."
                         : "Leaving removes your membership from this group on this device.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)

                    Button(currentUserIsOwner ? "Delete Group" : "Leave Group", role: .destructive) {
                        pendingConfirmation = currentUserIsOwner ? .deleteGroup : .leaveGroup
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.weakness)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
            }
        }
    }

    private var confirmationPresented: Binding<Bool> {
        Binding(
            get: { pendingConfirmation != nil },
            set: { isPresented in
                if !isPresented {
                    pendingConfirmation = nil
                }
            }
        )
    }

    private var confirmationTitle: String {
        switch pendingConfirmation {
        case .deleteGroup:
            return "Delete this group?"
        case .leaveGroup:
            return "Leave this group?"
        case .none:
            return ""
        }
    }

    private var confirmationMessage: String {
        switch pendingConfirmation {
        case .deleteGroup:
            return "This will remove the group and its assigned passages from this device."
        case .leaveGroup:
            return "You’ll be removed from this group on this device."
        case .none:
            return ""
        }
    }

    private var ownerLabel: String {
        guard let ownerMembership else {
            return "You"
        }

        return memberDisplayName(for: ownerMembership)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
    }

    private func sectionHeader(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func heroStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.86))
        )
    }

    private func reviewActionButton(
        title: String,
        tint: Color,
        textColor: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isEnabled ? textColor : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isEnabled ? tint : AppColors.surface)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isEnabled ? tint.opacity(0.2) : AppColors.divider, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func progressMetricCard(value: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value.formatted())
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private func assignedPassageCard(for passage: AssignedPassage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VerseRowView(verse: passage.verse, showsChevron: false)

            HStack(alignment: .center, spacing: 10) {
                progressBadge(for: passage.progress)

                if let lastReviewedAt = passage.progress.lastReviewedAt {
                    metaPill(lastReviewedAt.formatted(.relative(presentation: .named)))
                }

                metaPill("Assigned \(passage.assignment.assignedAt.formatted(.relative(presentation: .named)))")

                Spacer(minLength: 0)
            }

            Button("Remove", role: .destructive) {
                removeAssignment(passage.assignment.id)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func metaPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.elevatedSurface)
            )
    }

    private func memberDisplayName(for membership: GroupMembership) -> String {
        membership.userID == LocalSession.currentUserID ? "You" : membership.userID
    }

    private func memberSubtitle(for membership: GroupMembership) -> String {
        if membership.userID == LocalSession.currentUserID {
            return currentUserIsOwner ? "Group owner" : "Member"
        }

        return "Joined \(membership.joinedAt.formatted(.dateTime.month().day().year()))"
    }

    private func reloadGroup() {
        if let refreshedGroup = GroupRepository.shared.group(withID: group.id) {
            group = refreshedGroup
        }

        memberships = GroupRepository.shared.memberships(forGroupID: group.id)
        let assignedVerses = GroupRepository.shared.assignedVerses(forGroupID: group.id)
        let progressByVerseID = GroupProgressRepository.shared.progressByVerseID(
            forGroupID: group.id,
            verseIDs: assignedVerses.map(\.verse.id)
        )
        assignedPassages = assignedVerses.map { passage in
            AssignedPassage(
                assignment: passage.assignment,
                verse: passage.verse,
                progress: progressByVerseID[passage.verse.id] ?? GroupVerseProgress(
                    verseID: passage.verse.id,
                    status: .practicing,
                    reviewCount: 0,
                    lastReviewedAt: nil
                )
            )
        }
        progressSummary = GroupProgressRepository.shared.summary(
            forGroupID: group.id,
            verseIDs: assignedVerses.map(\.verse.id)
        )
        availableVerses = GroupRepository.shared.unassignedPersonalVerses(forGroupID: group.id)
    }

    private func assignVerses(_ verseIDs: Set<String>) {
        guard !verseIDs.isEmpty else {
            return
        }

        GroupRepository.shared.assignVerses(groupID: group.id, verseIDs: Array(verseIDs))
        reloadGroup()
    }

    private func removeAssignment(_ assignmentID: String) {
        GroupRepository.shared.archiveAssignment(id: assignmentID)
        reloadGroup()
    }

    private func deleteGroup() {
        GroupRepository.shared.archiveGroup(id: group.id)
        pendingConfirmation = nil
        dismiss()
    }

    private func leaveGroup() {
        GroupRepository.shared.leaveGroup(groupID: group.id)
        pendingConfirmation = nil
        dismiss()
    }

    private func startGroupPracticingReview() {
        guard !practicingReviewVerses.isEmpty else {
            return
        }

        reviewStartConfiguration = ReviewStartConfiguration(
            title: "Review Practicing",
            description: "Review only the group verses you are still working on. Group progress stays separate from your personal library.",
            verses: practicingReviewVerses
        )
    }

    private func startGroupAllReview() {
        guard !reviewVerses.isEmpty else {
            return
        }

        reviewStartConfiguration = ReviewStartConfiguration(
            title: "Review All",
            description: "Review every verse assigned to this group. Group progress stays separate from your personal library.",
            verses: reviewVerses
        )
    }

    private func progressRank(_ status: GroupVerseProgressStatus) -> Int {
        switch status {
        case .practicing:
            return 0
        case .memorized:
            return 1
        }
    }

    private func progressBadge(for progress: GroupVerseProgress) -> some View {
        Text(progress.status.title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(progressTint(for: progress.status).opacity(0.14)))
            .foregroundStyle(progressTint(for: progress.status))
    }

    private func progressTint(for status: GroupVerseProgressStatus) -> Color {
        switch status {
        case .practicing:
            return AppColors.statusPracticing
        case .memorized:
            return AppColors.statusMemorized
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(
            group: Group(
                id: UUID().uuidString,
                name: "Sunday Night Men",
                ownerUserID: LocalSession.currentUserID,
                createdAt: .now,
                updatedAt: .now,
                isArchived: false
            )
        )
    }
}
