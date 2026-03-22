import SwiftUI

struct GroupDetailView: View {
    private enum PendingActionConfirmation: String, Identifiable {
        case deleteGroup
        case leaveGroup

        var id: String {
            rawValue
        }
    }

    @Environment(\.colorScheme) private var colorScheme
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

    private struct SingleVerseReviewPresentation: Identifiable {
        let verse: Verse
        let method: ReviewMethod

        var id: String {
            "\(verse.id)-\(method.rawValue)"
        }
    }

    @State private var group: Group
    @State private var memberships: [GroupMembership] = []
    @State private var assignedPassages: [AssignedPassage] = []
    @State private var availableVerses: [Verse] = []
    @State private var isShowingAssignSheet = false
    @State private var isShowingAddVerseSheet = false
    @State private var isShowingMembers = false
    @State private var isShowingOptions = false
    @State private var pendingConfirmation: PendingActionConfirmation?
    @State private var detailVerse: Verse?
    @State private var selectedVerseReview: SingleVerseReviewPresentation?
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
                let lhsRank = masteryRank(lhs.verse.masteryStatus)
                let rhsRank = masteryRank(rhs.verse.masteryStatus)

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                return lhs.assignment.assignedAt > rhs.assignment.assignedAt
            }
            .map(\.verse)
    }

    private var practicingReviewVerses: [Verse] {
        assignedPassages
            .filter { $0.verse.masteryStatus == .practicing }
            .map(\.verse)
    }

    private var practicingAssignedCount: Int {
        assignedPassages.filter { $0.verse.masteryStatus == .practicing }.count
    }

    private var memorizedAssignedCount: Int {
        assignedPassages.filter { $0.verse.masteryStatus == .memorized }.count
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    groupHeroSection
                    reviewSection
                    assignedPassagesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, bottomActionBarClearance)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingOptions = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Group options")
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomReviewBar
        }
        .navigationDestination(isPresented: $isShowingMembers) {
            GroupMembersView(group: group, memberships: activeMembers)
        }
        .navigationDestination(isPresented: $isShowingOptions) {
            GroupOptionsView(
                group: group,
                memberships: activeMembers,
                currentUserIsOwner: currentUserIsOwner,
                onDeleteGroup: deleteGroup,
                onLeaveGroup: leaveGroup
            )
        }
        .navigationDestination(isPresented: detailVersePresented) {
            if let verse = detailVerse {
                VerseDetailView(
                    verse: verse,
                    onStartReview: { verse, method in
                        selectedVerseReview = SingleVerseReviewPresentation(verse: verse, method: method)
                    },
                    onVerseUpdated: { updatedVerse in
                        detailVerse = updatedVerse
                        reloadGroup()
                    },
                    onVerseDeleted: { deletedVerse in
                        if detailVerse?.id == deletedVerse.id {
                            detailVerse = nil
                        }
                        reloadGroup()
                    }
                )
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
        .sheet(item: $selectedVerseReview) { presentation in
            switch presentation.method {
            case .flashcard:
                ReviewView(verse: presentation.verse) { _ in
                    reloadGroup()
                }
            case .progressiveWordHiding:
                ProgressiveWordHidingReviewView(verse: presentation.verse) { _ in
                    reloadGroup()
                }
            case .firstLetterTyping:
                FirstLetterTypingReviewView(verse: presentation.verse) { _ in
                    reloadGroup()
                }
            case .voiceRecitation:
                VoiceRecitationReviewSessionView(
                    descriptor: ReviewSessionDescriptor(title: presentation.method.title, method: presentation.method),
                    verses: [presentation.verse],
                    onUpdate: { _ in
                        reloadGroup()
                    },
                    groupID: group.id
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

    private var bottomActionBarClearance: CGFloat {
        BottomNavigationShellLayout.overlayClearance + 84
    }

    private var detailVersePresented: Binding<Bool> {
        Binding(
            get: { detailVerse != nil },
            set: { isPresented in
                if !isPresented {
                    detailVerse = nil
                }
            }
        )
    }

    private var groupHeroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(groupSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                heroAccentPill(
                    title: progressSummary.totalAssignedCount == 1 ? "Assigned Passage" : "Assigned Passages",
                    value: progressSummary.totalAssignedCount.formatted()
                )

                heroAccentPill(
                    title: "Group Review",
                    value: practicingReviewVerses.isEmpty ? "Up to Date" : "In Progress"
                )
            }
        }
        .padding(18)
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
                progressTag(value: practicingAssignedCount, title: "Practicing", tint: AppColors.statusPracticing)
                progressTag(value: memorizedAssignedCount, title: "Memorized", tint: AppColors.statusMemorized)
            }
        }
    }

    private var assignedPassagesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                sectionHeader(title: "Assigned Passages", subtitle: assignedPassages.isEmpty ? "Nothing is assigned yet." : "\(assignedPassages.count) passage\(assignedPassages.count == 1 ? "" : "s") ready for the group")

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

    private func heroAccentPill(title: String, value: String) -> some View {
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
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface.opacity(0.86))
        )
    }

    @ViewBuilder
    private var bottomReviewBar: some View {
        HStack(spacing: 10) {
            reviewButton(
                title: "Review Practicing",
                tint: AppColors.primaryButton,
                textColor: AppColors.primaryButtonText,
                isEnabled: !practicingReviewVerses.isEmpty
            ) {
                startGroupPracticingReview()
            }

            reviewButton(
                title: "Review All",
                tint: AppColors.gold,
                textColor: AppColors.textPrimary,
                isEnabled: !reviewVerses.isEmpty
            ) {
                startGroupAllReview()
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, BottomNavigationShellLayout.overlayClearance - 2)
    }

    private func reviewButton(
        title: String,
        tint: Color,
        textColor: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(isEnabled ? tint : AppColors.surface)
                )
                .overlay {
                    Capsule()
                        .stroke(isEnabled ? tint.opacity(0.18) : AppColors.divider, lineWidth: 1)
                }
                .shadow(color: AppColors.background.opacity(isEnabled ? 0.12 : 0), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func progressTag(value: Int, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text("\(value.formatted()) \(title)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
    }

    private func assignedPassageCard(for passage: AssignedPassage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                detailVerse = passage.verse
            } label: {
                VerseRowView(
                    verse: passage.verse,
                    showsChevron: true,
                    statusTintOverride: passage.verse.masteryStatus.tintColor
                )
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, 17)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Button("Remove", role: .destructive) {
                removeAssignment(passage.assignment.id)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.leading, 17)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleAssignedVerseMastery(for: passage.verse)
            } label: {
                Image(systemName: toggleAssignedVerseSystemImage(for: passage.verse))
            }
            .tint(toggleAssignedVerseTint(for: passage.verse))
        }
    }

    private func memberDisplayName(for membership: GroupMembership) -> String {
        membership.userID == LocalSession.currentUserID ? "You" : membership.userID
    }

    private var groupSubtitle: String {
        if currentUserIsOwner {
            return "Created group on \(group.createdAt.formatted(.dateTime.month().day().year()))"
        }

        if let currentUserMembership {
            return "Joined group on \(currentUserMembership.joinedAt.formatted(.dateTime.month().day().year()))"
        }

        return "Created group on \(group.createdAt.formatted(.dateTime.month().day().year()))"
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

    private func masteryRank(_ status: VerseMasteryStatus) -> Int {
        switch status {
        case .practicing:
            return 0
        case .memorized:
            return 1
        }
    }

    private func toggleAssignedVerseMastery(for verse: Verse) {
        let targetStatus: VerseMasteryStatus = verse.masteryStatus == .practicing ? .memorized : .practicing
        _ = VerseRepository.shared.updateMasteryStatus(forVerseID: verse.id, to: targetStatus)
        reloadGroup()
    }

    private func toggleAssignedVerseSystemImage(for verse: Verse) -> String {
        verse.masteryStatus == .practicing ? "checkmark.circle.fill" : "flame.fill"
    }

    private func toggleAssignedVerseTint(for verse: Verse) -> Color {
        verse.masteryStatus == .practicing ? AppColors.statusMemorized : AppColors.statusPracticing
    }
}

private struct GroupOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    let group: Group
    let memberships: [GroupMembership]
    let currentUserIsOwner: Bool
    let onDeleteGroup: () -> Void
    let onLeaveGroup: () -> Void

    @State private var pendingConfirmation: GroupOptionsConfirmation?

    private var ownerMembership: GroupMembership? {
        memberships.first(where: { $0.role == .owner })
    }

    private var ownerLabel: String {
        guard let ownerMembership else {
            return "You"
        }

        return ownerMembership.userID == LocalSession.currentUserID ? "You" : ownerMembership.userID
    }

    private var memberCountText: String {
        "\(memberships.count) member\(memberships.count == 1 ? "" : "s")"
    }

    var body: some View {
        List {
            Section("Group") {
                LabeledContent("Name", value: group.name)
                LabeledContent("Owner", value: ownerLabel)
                LabeledContent("Members", value: memberCountText)
            }

            Section {
                NavigationLink {
                    GroupMembersView(group: group, memberships: memberships)
                } label: {
                    Label("View Members", systemImage: "person.2")
                }
            }

            Section("Danger Zone") {
                Button(currentUserIsOwner ? "Delete Group" : "Leave Group", role: .destructive) {
                    pendingConfirmation = currentUserIsOwner ? .deleteGroup : .leaveGroup
                }
            }
        }
        .navigationTitle("Group Options")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(confirmationTitle, isPresented: confirmationPresented, titleVisibility: .visible) {
            switch pendingConfirmation {
            case .deleteGroup:
                Button("Delete Group", role: .destructive) {
                    dismiss()
                    onDeleteGroup()
                }
            case .leaveGroup:
                Button("Leave Group", role: .destructive) {
                    dismiss()
                    onLeaveGroup()
                }
            case .none:
                EmptyView()
            }

            Button("Cancel", role: .cancel) {
                pendingConfirmation = nil
            }
        } message: {
            Text(confirmationMessage)
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
}

private enum GroupOptionsConfirmation: String, Identifiable {
    case deleteGroup
    case leaveGroup

    var id: String { rawValue }
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

#Preview("Group Options") {
    NavigationStack {
        GroupOptionsView(
            group: Group(
                id: UUID().uuidString,
                name: "Sunday Night Men",
                ownerUserID: LocalSession.currentUserID,
                createdAt: .now,
                updatedAt: .now,
                isArchived: false
            ),
            memberships: [
                GroupMembership(
                    id: UUID().uuidString,
                    groupID: UUID().uuidString,
                    userID: LocalSession.currentUserID,
                    role: .owner,
                    joinedAt: .now,
                    isActive: true
                )
            ],
            currentUserIsOwner: true,
            onDeleteGroup: {},
            onLeaveGroup: {}
        )
    }
}
