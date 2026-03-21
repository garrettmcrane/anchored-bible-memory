import SwiftUI

struct GroupDetailView: View {
    private struct AssignedPassage: Identifiable {
        let assignment: Assignment
        let verse: Verse

        var id: String {
            assignment.id
        }
    }

    @State private var group: Group
    @State private var memberships: [GroupMembership] = []
    @State private var assignedPassages: [AssignedPassage] = []
    @State private var availableVerses: [Verse] = []
    @State private var isShowingAssignSheet = false

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

            Section("Assigned Passages") {
                if assignedPassages.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No passages assigned yet.")
                            .font(.subheadline.weight(.semibold))

                        Text("Assign verses from your personal library to give this group a focused memorization set.")
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
                                Text("Assigned \(passage.assignment.assignedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button("Remove", role: .destructive) {
                                    removeAssignment(passage.assignment.id)
                                }
                                .font(.caption.weight(.semibold))
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
                Text("Groups v1 is local-only. New groups automatically include you as the owner and first member.")
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
                .disabled(availableVerses.isEmpty)
                .accessibilityLabel("Assign verse")
            }
        }
        .sheet(isPresented: $isShowingAssignSheet) {
            AssignVersesSheet(availableVerses: availableVerses) { verseIDs in
                assignVerses(verseIDs)
            }
        }
        .onAppear {
            reloadGroup()
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
            return "Local member"
        }

        return "Joined \(membership.joinedAt.formatted(.dateTime.month().day().year()))"
    }

    private func reloadGroup() {
        if let refreshedGroup = GroupRepository.shared.group(withID: group.id) {
            group = refreshedGroup
        }

        memberships = GroupRepository.shared.memberships(forGroupID: group.id)
        assignedPassages = GroupRepository.shared
            .assignedVerses(forGroupID: group.id)
            .map { AssignedPassage(assignment: $0.assignment, verse: $0.verse) }
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
