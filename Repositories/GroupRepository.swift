import Foundation

struct GroupRepository {
    static let shared = GroupRepository()

    func loadGroups() -> [Group] {
        let snapshot = GroupStore.load()
        let currentUserGroupIDs = Set(
            snapshot.memberships
                .filter { $0.userID == LocalSession.currentUserID && $0.isActive }
                .map(\.groupID)
        )

        return snapshot.groups
            .filter { !$0.isArchived && currentUserGroupIDs.contains($0.id) }
            .sorted(by: sortGroups)
    }

    func group(withID id: String) -> Group? {
        GroupStore.load().groups.first(where: { $0.id == id && !$0.isArchived })
    }

    func memberships(forGroupID groupID: String) -> [GroupMembership] {
        GroupStore.load().memberships
            .filter { $0.groupID == groupID && $0.isActive }
            .sorted { lhs, rhs in
                if lhs.role != rhs.role {
                    return roleRank(lhs.role) < roleRank(rhs.role)
                }

                return lhs.joinedAt < rhs.joinedAt
            }
    }

    func assignments(forGroupID groupID: String) -> [Assignment] {
        GroupStore.load().assignments
            .filter { $0.groupID == groupID && !$0.isArchived }
            .sorted { $0.assignedAt > $1.assignedAt }
    }

    func assignedVerses(forGroupID groupID: String) -> [(assignment: Assignment, verse: Verse)] {
        let assignments = assignments(forGroupID: groupID)
        let versesByID = Dictionary(uniqueKeysWithValues: VerseRepository.shared.loadAllOwnedVerses().map { ($0.id, $0) })

        return assignments.compactMap { assignment in
            guard let verse = versesByID[assignment.verseID] else {
                return nil
            }

            return (assignment, verse)
        }
    }

    func unassignedPersonalVerses(forGroupID groupID: String) -> [Verse] {
        let assignedVerseIDs = Set(assignments(forGroupID: groupID).map(\.verseID))

        return VerseRepository.shared.loadVerses()
            .filter { !assignedVerseIDs.contains($0.id) }
    }

    @discardableResult
    func createGroup(name: String) -> Group {
        let trimmedName = normalizedGroupName(name)
        let now = Date()
        let group = Group(
            id: UUID().uuidString,
            name: trimmedName,
            ownerUserID: LocalSession.currentUserID,
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        let membership = GroupMembership(
            id: UUID().uuidString,
            groupID: group.id,
            userID: LocalSession.currentUserID,
            role: .owner,
            joinedAt: now,
            isActive: true
        )

        var snapshot = GroupStore.load()
        snapshot.groups.append(group)
        snapshot.memberships.append(membership)
        GroupStore.save(
            groups: snapshot.groups,
            memberships: snapshot.memberships,
            assignments: snapshot.assignments
        )
        return group
    }

    func updateGroup(_ group: Group) {
        var snapshot = GroupStore.load()

        guard let index = snapshot.groups.firstIndex(where: { $0.id == group.id }) else {
            return
        }

        var updatedGroup = group
        updatedGroup.name = normalizedGroupName(group.name)
        updatedGroup.updatedAt = Date()
        snapshot.groups[index] = updatedGroup

        GroupStore.save(
            groups: snapshot.groups,
            memberships: snapshot.memberships,
            assignments: snapshot.assignments
        )
    }

    func archiveGroup(id: String) {
        var snapshot = GroupStore.load()
        let now = Date()

        guard let index = snapshot.groups.firstIndex(where: { $0.id == id }) else {
            return
        }

        snapshot.groups[index].isArchived = true
        snapshot.groups[index].updatedAt = now

        for membershipIndex in snapshot.memberships.indices where snapshot.memberships[membershipIndex].groupID == id {
            snapshot.memberships[membershipIndex].isActive = false
        }

        for assignmentIndex in snapshot.assignments.indices where snapshot.assignments[assignmentIndex].groupID == id {
            snapshot.assignments[assignmentIndex].isArchived = true
        }

        GroupStore.save(
            groups: snapshot.groups,
            memberships: snapshot.memberships,
            assignments: snapshot.assignments
        )
    }

    func leaveGroup(groupID: String, userID: String = LocalSession.currentUserID) {
        var snapshot = GroupStore.load()
        let now = Date()

        guard let membershipIndex = snapshot.memberships.firstIndex(where: {
            $0.groupID == groupID && $0.userID == userID && $0.isActive
        }) else {
            return
        }

        guard snapshot.memberships[membershipIndex].role != .owner else {
            return
        }

        snapshot.memberships[membershipIndex].isActive = false

        if let groupIndex = snapshot.groups.firstIndex(where: { $0.id == groupID }) {
            snapshot.groups[groupIndex].updatedAt = now
        }

        GroupStore.save(
            groups: snapshot.groups,
            memberships: snapshot.memberships,
            assignments: snapshot.assignments
        )
    }

    func assignVerses(groupID: String, verseIDs: [String], dueAt: Date? = nil) {
        let normalizedVerseIDs = Array(Set(verseIDs))

        guard !normalizedVerseIDs.isEmpty else {
            return
        }

        var snapshot = GroupStore.load()
        let existingAssignments = Set(
            snapshot.assignments
                .filter { $0.groupID == groupID && !$0.isArchived }
                .map(\.verseID)
        )
        let now = Date()

        for verseID in normalizedVerseIDs where !existingAssignments.contains(verseID) {
            snapshot.assignments.append(
                Assignment(
                    id: UUID().uuidString,
                    groupID: groupID,
                    verseID: verseID,
                    assignedByUserID: LocalSession.currentUserID,
                    assignedAt: now,
                    dueAt: dueAt,
                    isArchived: false
                )
            )
        }

        if let groupIndex = snapshot.groups.firstIndex(where: { $0.id == groupID }) {
            snapshot.groups[groupIndex].updatedAt = now
        }

        GroupStore.save(
            groups: snapshot.groups,
            memberships: snapshot.memberships,
            assignments: snapshot.assignments
        )
    }

    func archiveAssignment(id: String) {
        var snapshot = GroupStore.load()
        let now = Date()

        guard let index = snapshot.assignments.firstIndex(where: { $0.id == id }) else {
            return
        }

        snapshot.assignments[index].isArchived = true

        if let groupIndex = snapshot.groups.firstIndex(where: { $0.id == snapshot.assignments[index].groupID }) {
            snapshot.groups[groupIndex].updatedAt = now
        }

        GroupStore.save(
            groups: snapshot.groups,
            memberships: snapshot.memberships,
            assignments: snapshot.assignments
        )
    }

    private func normalizedGroupName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func sortGroups(_ lhs: Group, _ rhs: Group) -> Bool {
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt > rhs.updatedAt
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private func roleRank(_ role: GroupRole) -> Int {
        switch role {
        case .owner:
            return 0
        case .admin:
            return 1
        case .member:
            return 2
        }
    }
}
