import SwiftUI

struct GroupsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Groups")
                        .font(.system(size: 34, weight: .bold))

                    Text("Shared memorization and group review will be here soon.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)

                        Text("Group memorization is coming soon")
                            .font(.headline)

                        Text("You’ll be able to join a group, review together, and track your progress with others here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    GroupsView()
}
