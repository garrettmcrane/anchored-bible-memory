import SwiftUI

struct RootTabView: View {
    private enum Tab: Hashable {
        case home
        case library
        case add
        case groups
        case progress
    }

    @State private var selectedTab: Tab = .home
    @State private var addFocusTrigger = 0
    @State private var loadedTabs: Set<Tab> = [.home]

    var body: some View {
        TabView(selection: $selectedTab) {
            tabContent(for: .home)
                .tag(Tab.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            tabContent(for: .library)
                .tag(Tab.library)
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }

            tabContent(for: .add)
                .tag(Tab.add)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }

            tabContent(for: .groups)
                .tag(Tab.groups)
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            tabContent(for: .progress)
                .tag(Tab.progress)
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .onAppear {
            if selectedTab == .add {
                addFocusTrigger += 1
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            loadedTabs.insert(newValue)
            if newValue == .add {
                addFocusTrigger += 1
            }
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
            case .add:
                AddTabView(focusTrigger: addFocusTrigger)
            case .groups:
                GroupsView()
            case .progress:
                ProgressTabView()
            }
        }
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

#Preview {
    RootTabView()
}
