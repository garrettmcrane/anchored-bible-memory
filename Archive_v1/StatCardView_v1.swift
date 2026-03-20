import SwiftUI

struct StatCardView: View {
    let title: String
    let value: Int
    let systemImage: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)
                .font(.title3)

            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    HStack {
        StatCardView(title: "Learning", value: 4, systemImage: "brain.head.profile", iconColor: .blue)
        StatCardView(title: "Mastered", value: 12, systemImage: "checkmark.circle.fill", iconColor: .green)
    }
    .padding()
}
