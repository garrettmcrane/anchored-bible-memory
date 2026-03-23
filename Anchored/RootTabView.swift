import SwiftUI

struct RootTabView: View {
    private enum RootTab: Int, CaseIterable, Hashable {
        case home
        case library
        case groups
        case me
        case add

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
            case .add:
                return "Add"
            }
        }

        var systemImage: String {
            switch self {
            case .home:
                return "house"
            case .library:
                return "books.vertical"
            case .groups:
                return "person.3"
            case .me:
                return "person.crop.circle"
            case .add:
                return "plus"
            }
        }
    }

    @State private var selectedTab: RootTab = .home
    @State private var previousRealTab: RootTab = .home
    @State private var addFocusTrigger = 0
    @State private var isShowingAddFlow = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(RootTab.home.title, systemImage: RootTab.home.systemImage, value: RootTab.home) {
                HomeView()
            }

            Tab(RootTab.library.title, systemImage: RootTab.library.systemImage, value: RootTab.library) {
                LibraryView()
            }

            Tab(RootTab.groups.title, systemImage: RootTab.groups.systemImage, value: RootTab.groups) {
                GroupsView()
            }

            Tab(RootTab.me.title, systemImage: RootTab.me.systemImage, value: RootTab.me) {
                ProgressTabView()
            }

            Tab(RootTab.add.title, systemImage: RootTab.add.systemImage, value: RootTab.add, role: .search) {
                Color.clear
            }
        }
        .tint(AppColors.structuralAccent)
        .onChange(of: selectedTab) { oldValue, newValue in
            guard newValue != oldValue else {
                return
            }

            if newValue == .add {
                addFocusTrigger += 1
                isShowingAddFlow = true
                selectedTab = previousRealTab
            } else {
                previousRealTab = newValue
            }
        }
        .sheet(isPresented: $isShowingAddFlow) {
            AddHubView(showsCancelButton: true, focusTrigger: addFocusTrigger) { newVerse in
                VerseRepository.shared.addVerse(newVerse)
            }
        }
    }
}

struct BottomOverlayLayout {
    static let tabBarHeight: CGFloat = 58
    static let bottomPadding: CGFloat = 0
    static let verticalOffset: CGFloat = 8
    static let overlayClearance: CGFloat = tabBarHeight + bottomPadding + verticalOffset + 12
}

#Preview("Light") {
    RootTabView()
}

#Preview("Dark") {
    RootTabView()
        .preferredColorScheme(.dark)
}
