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

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LibraryView()
                .tag(Tab.library)
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }

            AddTabView(focusTrigger: addFocusTrigger)
                .tag(Tab.add)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }

            GroupsView()
                .tag(Tab.groups)
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            ProgressTabView()
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
            if newValue == .add {
                addFocusTrigger += 1
            }
        }
    }
}

#Preview {
    RootTabView()
}
