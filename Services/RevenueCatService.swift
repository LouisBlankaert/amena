// RevenueCatService : gère les achats via RevenueCat (remplace StoreKitService)
// RevenueCat s'appuie sur StoreKit 2 en interne — il ajoute le suivi du revenu
// par attribut (utilisé ici pour l'affiliation, voir AffiliateService) et
// simplifie la vérification des reçus.
//
// IMPORTANT avant que ça fonctionne réellement :
// 1. Créer un compte sur dashboard.revenuecat.com, y connecter l'app com.louis.Amena
//    (clé API App Store Connect / shared secret côté RevenueCat).
// 2. Créer un Entitlement nommé "premium" et l'attacher aux deux produits
//    com.louis.Amena.yearly / com.louis.Amena.weekly.
// 3. Créer une Offering (ex: "default") avec un Package par produit.
// 4. Remplacer Secrets.revenueCatAPIKey par la vraie clé publique du SDK.

import RevenueCat
import Foundation

final class RevenueCatService: @unchecked Sendable {
    static let shared = RevenueCatService()
    private init() {}

    // Nom de l'entitlement configuré dans le dashboard RevenueCat.
    private let premiumEntitlementId = "premium"

    // À appeler une seule fois, au lancement de l'app (avant tout achat/restore).
    func configure() {
        Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
    }

    // Vérifie l'abonnement actif au lancement (équivalent de checkCurrentSubscription)
    func checkCurrentSubscription() async {
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        applyEntitlement(from: info)
    }

    func purchase(plan: SubscriptionPlan) async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == plan.productId
        }) else {
            throw PurchaseError.productNotFound
        }

        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            throw PurchaseError.userCancelled
        }
        applyEntitlement(from: result.customerInfo)

        // Attache le code d'affiliation courant (s'il existe) à ce nouvel abonné,
        // pour que RevenueCat puisse rattacher ce revenu au créateur d'origine.
        AffiliateService.shared.attachReferralCodeToCurrentUser()
    }

    // Obligatoire App Store : bouton "Restore Purchases"
    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        applyEntitlement(from: info)
    }

    private func applyEntitlement(from info: CustomerInfo) {
        let isActive = info.entitlements[premiumEntitlementId]?.isActive == true
        UserDefaults.standard.set(isActive, forKey: "isPremium")
        if let productId = info.entitlements[premiumEntitlementId]?.productIdentifier {
            UserDefaults.standard.set(productId, forKey: "activePlanId")
        }
    }

    var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
}

enum PurchaseError: Error {
    case productNotFound
    case userCancelled
}
