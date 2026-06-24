// ContentView : décide quel écran afficher selon l'état de l'utilisateur
// Si l'onboarding n'est pas terminé → IntroSlidesView
// Si l'onboarding est terminé → MainTabView (Home + Journal)

import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            MainTabView()
        } else {
            OnboardingCoordinator()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
        }
        .tint(Color.amenaPrimary)
    }
}


#Preview {
    ContentView()
}
