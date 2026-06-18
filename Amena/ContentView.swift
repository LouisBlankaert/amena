// ContentView : décide quel écran afficher selon l'état de l'utilisateur
// Si l'onboarding n'est pas terminé → IntroSlidesView
// Si l'onboarding est terminé → HomeView (écran principal)

import SwiftUI

struct ContentView: View {
    // @AppStorage lit/écrit dans UserDefaults automatiquement
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            HomeView()
        } else {
            OnboardingCoordinator()
        }
    }
}

#Preview {
    ContentView()
}
