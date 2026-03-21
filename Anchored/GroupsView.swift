import SwiftUI

struct GroupsView: View {
    @State private var groups: [Group] = []
    @State private var isShowingCreateGroupSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground
                    .ignoresSafeArea()

                if groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .tint(AppColors.gold)
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
                Text("Shared memorization starts here")
                    .font(.system(size: 30, weight: .bold))

                Text("Create a group for the verses you want to memorize together. Group passages stay separate from your personal memorization library, so your own progress stays focused.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.darkTextSecondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Label("Assign verses from your existing library", systemImage: "books.vertical.fill")
                Label("Add new verses without leaving the group", systemImage: "plus.circle.fill")
                Label("Keep group passages separate from your personal memorization library", systemImage: "square.stack.3d.down.right.fill")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppColors.darkTextSecondary)

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
                .fill(AppColors.darkSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.darkDivider, lineWidth: 1)
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
                Text("Groups and assignments stay on this device.")
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
            .foregroundStyle(AppColors.darkTextSecondary)
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
