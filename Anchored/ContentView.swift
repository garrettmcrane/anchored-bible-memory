import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingOnboarding = false

    var body: some View {
        RootTabView()
            .fullScreenCover(isPresented: $isShowingOnboarding) {
                OnboardingView {
                    hasCompletedOnboarding = true
                    isShowingOnboarding = false
                }
            }
            .task {
                guard !hasCompletedOnboarding else {
                    return
                }

                isShowingOnboarding = true
            }
    }
}

#Preview {
    ContentView()
}
