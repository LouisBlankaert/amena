// Point d'entrée de l'app Amena
// @main = Swift sait que c'est ici que l'app démarre

import SwiftUI
import FirebaseCore

@main
struct AmenaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Stocke le listener pour éviter qu'il soit désalloué
    // Il tourne en background pendant toute la vie de l'app
    private let transactionListener = StoreKitService.shared.startTransactionListener()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // L'ap p est conçue uniquement en light mode (palette fixe dans Color+Theme.swift).
                // Sans ça, les éléments système sans couleur explicite (ex: DatePicker wheel)
                // passent en texte blanc sous iOS Dark Mode, illisible sur nos fonds blancs codés en dur.
                .preferredColorScheme(.light)
                .task {
                    // Vérifie l'état de l'abonnement à chaque lancement
                    await StoreKitService.shared.checkCurrentSubscription()
                }
        }
    }
}

// AppDelegate : classe de cycle de vie de l'app (style UIKit)
// Firebase a besoin d'être configuré ici, avant que quoi que ce soit d'autre se charge
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase avec le fichier GoogleService-Info.plist
        // Ce fichier doit être ajouté manuellement dans Xcode (voir instructions ci-dessous)
        FirebaseApp.configure()
        return true
    }
}
