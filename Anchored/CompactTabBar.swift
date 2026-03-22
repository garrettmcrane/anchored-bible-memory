import SwiftUI

// MARK: - Models

struct CompactTabBarItem: Identifiable, Hashable {
    let id = UUID()
    let systemImage: String
    let title: String
    let tag: Int
}

// MARK: - Compact Tab Bar

struct CompactTabBar: View {
    let items: [CompactTabBarItem]
    @Binding var selection: Int

    // Style
    var barWidth: CGFloat = 320
    var barHeight: CGFloat = 64
    var cornerRadius: CGFloat = 16
    var barBackground: Color = AppColors.elevatedSurface
    var barStroke: Color = AppColors.divider
    var activeTint: Color = Color.accentColor
    var inactiveTint: Color = AppColors.textSecondary
    var useCircularStyle: Bool = false // If true, uses ShellCircularIconLabel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    if selection != item.tag {
                        selection = item.tag
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                } label: {
                    if useCircularStyle {
                        VStack(spacing: 4) {
                            ShellCircularIconLabel(
                                systemImage: item.systemImage,
                                tint: selection == item.tag ? activeTint : inactiveTint
                            )
                            Text(item.title)
                                .font(.caption2)
                                .foregroundStyle(selection == item.tag ? activeTint : inactiveTint)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selection == item.tag ? activeTint : inactiveTint)
                            Text(item.title)
                                .font(.caption2)
                                .foregroundStyle(selection == item.tag ? activeTint : inactiveTint)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(item.title))
                .accessibilityAddTraits(selection == item.tag ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .frame(width: barWidth, height: barHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(barBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(barStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        .padding(.horizontal)
        .frame(maxWidth: .infinity) // centers horizontally
    }
}

// MARK: - Container that hosts content + tab bar

struct CompactTabContainer<Content: View>: View {
    @State private var selection: Int = 0
    let items: [CompactTabBarItem]
    var useCircularStyle: Bool = false
    @ViewBuilder var content: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            content(selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.surface.ignoresSafeArea())

            VStack(spacing: 0) {
                AppColors.divider.frame(height: 0.5).padding(.horizontal, 20)
                CompactTabBar(
                    items: items,
                    selection: $selection,
                    barWidth: 320,
                    barHeight: useCircularStyle ? 80 : 64,
                    cornerRadius: 16,
                    barBackground: AppColors.elevatedSurface,
                    barStroke: AppColors.divider,
                    activeTint: Color.accentColor,
                    inactiveTint: AppColors.textSecondary,
                    useCircularStyle: useCircularStyle
                )
                .padding(.vertical, 8)
                .padding(.bottom, 8)
            }
            .background(AppColors.surface.ignoresSafeArea(edges: .bottom))
        }
    }
}
// MARK: - Preview / Example usage

#Preview("CompactTabBar Demo") {
    let items: [CompactTabBarItem] = [
        .init(systemImage: "house.fill", title: "Home", tag: 0),
        .init(systemImage: "magnifyingglass", title: "Search", tag: 1),
        .init(systemImage: "heart.fill", title: "Favorites", tag: 2),
        .init(systemImage: "person.fill", title: "Profile", tag: 3)
    ]

    return CompactTabContainer(items: items, useCircularStyle: true) { selection in
        ZStack {
            AppColors.surface.ignoresSafeArea()
            Text(["Home", "Search", "Favorites", "Profile"][min(max(selection, 0), 3)])
                .font(.title)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

