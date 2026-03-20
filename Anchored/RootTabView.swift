import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }

            AddTabView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }

            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    RootTabView()
}
