// AffiliateService : capte le code créateur via un lien Branch et le rattache
// à l'abonné RevenueCat pour permettre le calcul des 50% de reversion.
//
// Fonctionnement :
// 1. Un créateur reçoit un lien Branch unique contenant "referral_code": "nomducreateur"
//    (créé manuellement dans dashboard.branch.io pour le MVP, pas de self-serve).
// 2. Quand un nouvel utilisateur ouvre l'app via ce lien (même si l'app n'était pas
//    encore installée — "deferred deep link"), Branch redonne ce paramètre à l'app
//    au premier lancement.
// 3. On stocke ce code une seule fois en local (le premier lien gagne, on ne
//    l'écrase jamais après), puis on l'envoie à RevenueCat comme attribut subscriber
//    dès qu'un achat a lieu, pour que le revenu soit filtrable par créateur.
//
// IMPORTANT avant que ça fonctionne réellement :
// 1. Créer un compte sur dashboard.branch.io, y déclarer le bundle ID com.louis.Amena
//    + le domaine de lien (ex: amena.app.link) + les Universal Links associés.
// 2. Remplacer Secrets.branchKey par la vraie clé live.
// 3. Ajouter les entitlements Associated Domains dans Xcode pour les Universal Links.

import BranchSDK
import RevenueCat
import UIKit

final class AffiliateService: @unchecked Sendable {
    static let shared = AffiliateService()
    private init() {}

    private let referralCodeKey = "referralCode"
    private let referralAttachedKey = "referralCodeAttachedToRevenueCat"

    // À appeler dans AppDelegate.didFinishLaunchingWithOptions, avant tout le reste.
    func initSession(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        Branch.setBranchKey(Secrets.branchKey)
        Branch.getInstance().initSession(launchOptions: launchOptions) { [weak self] params, _ in
            guard let code = params?["referral_code"] as? String else { return }
            self?.storeReferralCodeIfNeeded(code)
        }
    }

    // Universal Links (https://amena.app.link/...)
    func continueUserActivity(_ userActivity: NSUserActivity) -> Bool {
        Branch.getInstance().continue(userActivity)
    }

    // Custom URL scheme (amena://...)
    func handleOpenURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        Branch.getInstance().application(UIApplication.shared, open: url, options: options)
    }

    // Le premier lien gagne : on ne réattribue jamais un utilisateur à un autre créateur.
    private func storeReferralCodeIfNeeded(_ code: String) {
        guard UserDefaults.standard.string(forKey: referralCodeKey) == nil else { return }
        UserDefaults.standard.set(code, forKey: referralCodeKey)
        UserDefaults.standard.set(false, forKey: referralAttachedKey)
    }

    var referralCode: String? {
        UserDefaults.standard.string(forKey: referralCodeKey)
    }

    // Envoie le code créateur à RevenueCat comme attribut subscriber, une seule fois.
    func attachReferralCodeToCurrentUser() {
        guard let code = referralCode,
              !UserDefaults.standard.bool(forKey: referralAttachedKey) else { return }
        Purchases.shared.attribution.setAttributes(["referral_code": code])
        UserDefaults.standard.set(true, forKey: referralAttachedKey)
    }
}
