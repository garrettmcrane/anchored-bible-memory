import SwiftUI

struct ProgressTabView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Progress")
                        .font(.system(size: 34, weight: .bold))

                    Text("Your trends, insights, and longer-term progress will land here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 14) {
                        ProgressPreviewRow(title: "Consistency", subtitle: "Weekly rhythm and streaks")
                        ProgressPreviewRow(title: "Retention", subtitle: "What is sticking and what needs review")
                        ProgressPreviewRow(title: "Growth", subtitle: "How your memory library expands over time")
                    }
                    .padding(20)
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

private struct ProgressPreviewRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.blue.opacity(0.16))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.blue)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    ProgressTabView()
}
