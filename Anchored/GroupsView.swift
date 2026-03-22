import SwiftUI

struct GroupsView: View {
    @State private var groups: [Group] = []
    @State private var isShowingCreateGroupSheet = false
    @State private var isShowingAddFlow = false
    @State private var addFocusTrigger = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    if groups.isEmpty {
                        Spacer(minLength: 0)
                        emptyState
                        Spacer(minLength: BottomNavigationShellLayout.overlayClearance - 44)
                    } else {
                        groupsList
                    }
                }
            }
            .tint(AppColors.structuralAccent)
        }
        .sheet(isPresented: $isShowingCreateGroupSheet) {
            CreateGroupSheet { name in
                _ = GroupRepository.shared.createGroup(name: name)
                reloadGroups()
            }
        }
        .sheet(isPresented: $isShowingAddFlow) {
            AddHubView(showsCancelButton: true, focusTrigger: addFocusTrigger) { newVerse in
                VerseRepository.shared.addVerse(newVerse)
                reloadGroups()
            }
        }
        .onAppear {
            reloadGroups()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addFocusTrigger += 1
                    isShowingAddFlow = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .trailing) {
                Text("Groups")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)

                Button {
                    isShowingCreateGroupSheet = true
                } label: {
                    Label("Create", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .frame(height: 42)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .accessibilityLabel("Create group")
            }
            .frame(height: 44)

            Text("Memorize together without losing the focus of your personal library.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !groups.isEmpty {
                HStack(spacing: 12) {
                    headerMetric(title: "Groups", value: groups.count)
                    headerMetric(title: "Passages", value: totalAssignmentCount)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Shared memorization starts here")
                    .font(.system(size: 30, weight: .bold))

                Text("Create a group for the verses you want to memorize together. Group passages stay separate from your personal memorization library, so your own progress stays focused.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Label("Assign verses from your existing library", systemImage: "books.vertical.fill")
                Label("Add new verses without leaving the group", systemImage: "plus.circle.fill")
                Label("Keep group passages separate from your personal memorization library", systemImage: "square.stack.3d.down.right.fill")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppColors.textSecondary)

            Button("Create Group") {
                isShowingCreateGroupSheet = true
            }
            .buttonStyle(.glass(.regular.tint(AppColors.reviewPracticingActionBackground).interactive()))
            .foregroundStyle(AppColors.reviewPracticingActionText)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
        .padding(20)
    }

    private var groupsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        groupRow(group)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Archive", role: .destructive) {
                            archiveGroup(group.id)
                        }
                    }
                }

                Text("Groups and assignments stay on this device.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, max(BottomNavigationShellLayout.overlayClearance - 26, 18))
        }
    }

    private func groupRow(_ group: Group) -> some View {
        let assignmentCount = GroupRepository.shared.assignments(forGroupID: group.id).count
        let memberCount = GroupRepository.shared.memberships(forGroupID: group.id).count
        let createdDate = group.createdAt.formatted(.dateTime.month().day().year())

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Created \(createdDate)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, 4)
            }

            HStack(spacing: 10) {
                groupMetaPill(title: "\(memberCount)", subtitle: memberCount == 1 ? "Member" : "Members", systemImage: "person.2.fill")
                groupMetaPill(title: "\(assignmentCount)", subtitle: assignmentCount == 1 ? "Passage" : "Passages", systemImage: "text.book.closed.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var totalAssignmentCount: Int {
        groups.reduce(into: 0) { partialResult, group in
            partialResult += GroupRepository.shared.assignments(forGroupID: group.id).count
        }
    }

    private func headerMetric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value.formatted())
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private func groupMetaPill(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.gold)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(AppColors.subtleAccent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
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
