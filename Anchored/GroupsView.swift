import SwiftUI

struct GroupsView: View {
    @State private var groups: [Group] = []
    @State private var isShowingCreateGroupSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCreateGroupSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create group")
                }
            }
        }
        .sheet(isPresented: $isShowingCreateGroupSheet) {
            CreateGroupSheet { name in
                _ = GroupRepository.shared.createGroup(name: name)
                reloadGroups()
            }
        }
        .onAppear {
            reloadGroups()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Build a shared memorization circle")
                    .font(.system(size: 30, weight: .bold))

                Text("Create a local group to organize shared passages without mixing them into your personal library.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Label("Assign verses from your existing library", systemImage: "books.vertical.fill")
                Label("Stay separate from your personal memorization system", systemImage: "square.stack.3d.down.right.fill")
                Label("Start simple with local-only ownership", systemImage: "person.crop.circle.badge.checkmark")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

            Button("Create Group") {
                isShowingCreateGroupSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
        .padding(20)
    }

    private var groupsList: some View {
        List {
            Section {
                ForEach(groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        groupRow(group)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Archive", role: .destructive) {
                            archiveGroup(group.id)
                        }
                    }
                }
            } footer: {
                Text("Groups are stored locally on this device in v1.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func groupRow(_ group: Group) -> some View {
        let assignmentCount = GroupRepository.shared.assignments(forGroupID: group.id).count
        let memberCount = GroupRepository.shared.memberships(forGroupID: group.id).count

        return VStack(alignment: .leading, spacing: 8) {
            Text(group.name)
                .font(.headline)

            HStack(spacing: 12) {
                Label("\(memberCount) member\(memberCount == 1 ? "" : "s")", systemImage: "person.2.fill")
                Label("\(assignmentCount) passage\(assignmentCount == 1 ? "" : "s")", systemImage: "text.book.closed.fill")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func reloadGroups() {
        groups = GroupRepository.shared.loadGroups()
    }

    private func archiveGroup(_ id: String) {
        GroupRepository.shared.archiveGroup(id: id)
        reloadGroups()
    }
}

#Preview {
    GroupsView()
}
