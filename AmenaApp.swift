// Point d'entrée de l'app Amena
// @main = Swift sait que c'est ici que l'app démarre

import SwiftUI
import FirebaseCore  // Firebase doit être initialisé au démarrage de l'app

@main
struct AmenaApp: App {
    // @UIApplicationDelegateAdaptor permet d'utiliser un AppDelegate en SwiftUI
    // Nécessaire pour FirebaseApp.configure() qui doit être appelé dans didFinishLaunching
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
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
