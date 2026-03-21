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
        notStartedCount: 0,
        inProgressCount: 0,
        masteredCount: 0
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

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.name)
                        .font(.system(size: 30, weight: .bold))

                    HStack(spacing: 10) {
                        Label("Owner: \(ownerLabel)", systemImage: "crown.fill")
                        Label(memberCountText, systemImage: "person.2.fill")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section {
                Button {
                    startGroupReview()
                } label: {
                    Text("Review Group Verses")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(reviewVerses.isEmpty)
            }

            Section("Progress") {
                HStack(spacing: 0) {
                    progressMetric(value: progressSummary.totalAssignedCount, title: "Assigned")
                    progressMetric(value: progressSummary.notStartedCount, title: "Not Started")
                    progressMetric(value: progressSummary.inProgressCount, title: "In Progress")
                    progressMetric(value: progressSummary.masteredCount, title: "Mastered")
                }
                .padding(.vertical, 4)
            }

            Section("Assigned Passages") {
                if assignedPassages.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No passages assigned yet.")
                            .font(.subheadline.weight(.semibold))

                        Text("Assign verses from your personal memorization library or add brand new verses for this group.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Assign Passage") {
                            isShowingAssignSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(assignedPassages) { passage in
                        VStack(alignment: .leading, spacing: 8) {
                            VerseRowView(verse: passage.verse, showsChevron: false)

                            HStack {
                                progressBadge(for: passage.progress)

                                if let lastReviewedAt = passage.progress.lastReviewedAt {
                                    Text(lastReviewedAt.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text("Assigned \(passage.assignment.assignedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button("Remove", role: .destructive) {
                                    removeAssignment(passage.assignment.id)
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                ownerMemberRow

                if activeMembers.count > 1 {
                    ForEach(activeMembers.filter { $0.role != .owner }) { membership in
                        memberRow(for: membership)
                    }
                }
            } header: {
                Text("Members")
            } footer: {
                Text("The group owner is added automatically when the group is created.")
            }

            Section {
                if currentUserIsOwner {
                    Button("Delete Group", role: .destructive) {
                        pendingConfirmation = .deleteGroup
                    }
                } else if currentUserMembership != nil {
                    Button("Leave Group", role: .destructive) {
                        pendingConfirmation = .leaveGroup
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Group")
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

    private var ownerMemberRow: some View {
        memberRow(for: ownerMembership ?? GroupMembership(
            id: UUID().uuidString,
            groupID: group.id,
            userID: LocalSession.currentUserID,
            role: .owner,
            joinedAt: group.createdAt,
            isActive: true
        ))
    }

    private func memberRow(for membership: GroupMembership) -> some View {
        HStack(spacing: 12) {
            Image(systemName: membership.role == .owner ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                .font(.title3)
                .foregroundStyle(membership.role == .owner ? .yellow : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(memberDisplayName(for: membership))
                    .font(.body.weight(.semibold))

                Text(memberSubtitle(for: membership))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if membership.role == .owner {
                Text("Owner")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
                    status: .notStarted,
                    reviewCount: 0,
                    consecutiveCorrectCount: 0,
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

    private func startGroupReview() {
        guard !reviewVerses.isEmpty else {
            return
        }

        reviewStartConfiguration = ReviewStartConfiguration(
            title: "Group Review",
            description: "Review only the verses assigned to this group. Group progress stays separate from your personal memorization library.",
            verses: reviewVerses
        )
    }

    private func progressRank(_ status: GroupVerseProgressStatus) -> Int {
        switch status {
        case .notStarted:
            return 0
        case .inProgress:
            return 1
        case .mastered:
            return 2
        }
    }

    private func progressMetric(value: Int, title: String) -> some View {
        VStack(spacing: 4) {
            Text(value.formatted())
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
        case .notStarted:
            return .secondary
        case .inProgress:
            return Color(red: 0.72, green: 0.56, blue: 0.18)
        case .mastered:
            return Color(red: 0.24, green: 0.55, blue: 0.41)
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
