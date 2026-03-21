import SwiftUI

struct StatCardView: View {
    let title: String
    let value: Int
    let systemImage: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)
                .font(.title3)

            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.lightTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppColors.lightSurface)
        )
    }
}

#Preview {
    HStack {
        StatCardView(title: "Learning", value: 4, systemImage: "brain.head.profile", iconColor: AppColors.brandBlue)
        StatCardView(title: "Memorized", value: 12, systemImage: "checkmark.circle.fill", iconColor: AppColors.gold)
    }
    .padding()
}
