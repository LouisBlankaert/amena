// AffiliateService : stocke le code créateur tapé manuellement par l'utilisateur
// et le rattache à l'abonné RevenueCat pour permettre le calcul des 50% de reversion.
//
// Fonctionnement :
// 1. Chaque créateur a un code texte unique (ex: "PAUL"), donné à la main par nous.
// 2. Le créateur le partage avec son audience ("utilise le code PAUL dans l'app").
// 3. L'utilisateur tape ce code dans le paywall (champ optionnel) — on le stocke
//    une seule fois en local (le premier code gagne, jamais réécrasé ensuite).
// 4. Quand l'utilisateur achète un abonnement (RevenueCatService.purchase()), on
//    envoie ce code à RevenueCat comme attribut subscriber ("referral_code"), pour
//    que le revenu soit filtrable par créateur dans le dashboard RevenueCat.

import RevenueCat
import Foundation

final class AffiliateService: @unchecked Sendable {
    static let shared = AffiliateService()
    private init() {}

    private let referralCodeKey = "referralCode"
    private let referralAttachedKey = "referralCodeAttachedToRevenueCat"

    var referralCode: String? {
        UserDefaults.standard.string(forKey: referralCodeKey)
    }

    // Le premier code gagne : on ne réattribue jamais un utilisateur à un autre créateur.
    func setReferralCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, UserDefaults.standard.string(forKey: referralCodeKey) == nil else { return }
        UserDefaults.standard.set(trimmed, forKey: referralCodeKey)
        UserDefaults.standard.set(false, forKey: referralAttachedKey)
    }

    // Envoie le code créateur à RevenueCat comme attribut subscriber, une seule fois.
    func attachReferralCodeToCurrentUser() {
        guard let code = referralCode,
              !UserDefaults.standard.bool(forKey: referralAttachedKey) else { return }
        Purchases.shared.attribution.setAttributes(["referral_code": code])
        UserDefaults.standard.set(true, forKey: referralAttachedKey)
    }
}
