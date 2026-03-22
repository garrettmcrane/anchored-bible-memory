import SwiftUI

struct GroupMembersView: View {
    let group: Group
    let memberships: [GroupMembership]

    private var activeMemberships: [GroupMembership] {
        memberships.filter(\.isActive)
    }

    private var ownerMembership: GroupMembership? {
        activeMemberships.first(where: { $0.role == .owner })
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard

                    VStack(spacing: 12) {
                        ForEach(activeMemberships) { membership in
                            memberCard(for: membership)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("\(activeMemberships.count) member\(activeMemberships.count == 1 ? "" : "s") in this group.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func memberCard(for membership: GroupMembership) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(membership.role == .owner ? AppColors.subtleAccent : AppColors.elevatedSurface)
                    .frame(width: 42, height: 42)

                Image(systemName: membership.role == .owner ? "crown.fill" : "person.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(membership.role == .owner ? AppColors.gold : AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName(for: membership))
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle(for: membership))
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 12)

            if membership.id == ownerMembership?.id {
                Text("Owner")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppColors.selectionFill)
                    )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
    }

    private func displayName(for membership: GroupMembership) -> String {
        membership.userID == LocalSession.currentUserID ? "You" : membership.userID
    }

    private func subtitle(for membership: GroupMembership) -> String {
        if membership.userID == LocalSession.currentUserID {
            return membership.role == .owner ? "Group owner" : "Member"
        }

        return "Joined \(membership.joinedAt.formatted(.dateTime.month().day().year()))"
    }
}
