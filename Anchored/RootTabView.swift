import SwiftUI

struct RootTabView: View {
    private enum Tab: String, CaseIterable, Hashable {
        case home
        case library
        case groups
        case me

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .library:
                return "Library"
            case .groups:
                return "Groups"
            case .me:
                return "Me"
            }
        }

        var systemImage: String {
            switch self {
            case .home:
                return "house.fill"
            case .library:
                return "books.vertical.fill"
            case .groups:
                return "person.3.fill"
            case .me:
                return "person.crop.circle.fill"
            }
        }
    }

    @State private var selectedTab: Tab = .home
    @State private var addFocusTrigger = 0
    @State private var loadedTabs: Set<Tab> = [.home]
    @State private var isShowingAddFlow = false

    var body: some View {
        GeometryReader { proxy in
            let shellMetrics = BottomShellMetrics()

            ZStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    LazyTabContainer(isLoaded: loadedTabs.contains(tab)) {
                        tabContent(for: tab)
                    }
                    .opacity(selectedTab == tab ? 1 : 0)
                    .allowsHitTesting(selectedTab == tab)
                    .accessibilityHidden(selectedTab != tab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                bottomNavigationShell(metrics: shellMetrics)
                    .ignoresSafeArea(edges: .bottom)
            }
            .sheet(isPresented: $isShowingAddFlow) {
                AddHubView(showsCancelButton: true, focusTrigger: addFocusTrigger) { newVerse in
                    VerseRepository.shared.addVerse(newVerse)
                }
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            loadedTabs.insert(newValue)
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        LazyTabContainer(isLoaded: loadedTabs.contains(tab)) {
            switch tab {
            case .home:
                HomeView()
            case .library:
                LibraryView()
            case .groups:
                GroupsView()
            case .me:
                ProgressTabView()
            }
        }
    }

    private func bottomNavigationShell(metrics: BottomShellMetrics) -> some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.tabBarBackground.opacity(0.98))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(AppColors.divider.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: AppColors.shadow, radius: 18, x: 0, y: 10)

            addButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, metrics.bottomPadding)
        .offset(y: BottomNavigationShellLayout.verticalOffset)
        .frame(maxWidth: .infinity, alignment: .bottom)
    }

    private func tabButton(for tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 16, weight: .semibold))

                Text(tab.title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(selectedTab == tab ? AppColors.structuralAccent : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule(style: .continuous)
                    .fill(selectedTab == tab ? AppColors.selectionFill : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
    }

    private var addButton: some View {
        Button {
            addFocusTrigger += 1
            isShowingAddFlow = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.primaryButtonText)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(AppColors.primaryButton)
                )
                .overlay {
                    Circle()
                        .stroke(AppColors.divider.opacity(0.45), lineWidth: 1)
                }
                .shadow(color: AppColors.shadow.opacity(0.9), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

private struct LazyTabContainer<Content: View>: View {
    let isLoaded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isLoaded {
            content()
        } else {
            Color.clear
        }
    }
}

private struct BottomShellMetrics {
    let bottomPadding = BottomNavigationShellLayout.bottomPadding
}

struct BottomNavigationShellLayout {
    static let shellHeight: CGFloat = 58
    static let bottomPadding: CGFloat = 0
    static let verticalOffset: CGFloat = 8
    static let overlayClearance: CGFloat = shellHeight + bottomPadding + verticalOffset + 12
}

#Preview("Light") {
    RootTabView()
}

#Preview("Dark") {
    RootTabView()
        .preferredColorScheme(.dark)
}
