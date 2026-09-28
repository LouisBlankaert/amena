// ContentView : décide quel écran afficher selon l'état de l'utilisateur
// Si l'onboarding n'est pas terminé → IntroSlidesView
// Si l'onboarding est terminé → MainTabView (Home + Journal)

import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        #if DEBUG
        // Raccourci de test : lancer avec l'argument -debugPaywall affiche le paywall seul
        if ProcessInfo.processInfo.arguments.contains("-debugPaywall") {
            PaywallView(onNext: {})
        } else {
            mainContent
        }
        #else
        mainContent
        #endif
    }

    @ViewBuilder
    private var mainContent: some View {
        if onboardingCompleted {
            MainTabView()
        } else {
            OnboardingCoordinator()
        }
    }
}

struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(t("Home", "Accueil"), systemImage: "sun.horizon.fill")
                }
                .tag(0)
            JournalView()
                .tabItem {
                    Label(t("Notebook", "Carnet"), systemImage: "book.closed.fill")
                }
                .tag(1)
        }
        .tint(Color.amenaNightBlue)
    }
}


#Preview {
    ContentView()
}
