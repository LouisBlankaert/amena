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

    // Accès créateur : débloqué via un geste caché + code secret dans Settings.
    // Stocké dans le Keychain (et non UserDefaults) pour survivre à une suppression
    // de l'app, et conservé indépendamment du vrai statut RevenueCat pour ne pas
    // être écrasé par checkCurrentSubscription().
    private let founderAccessKey = "founderAccess"

    var hasFounderAccess: Bool {
        KeychainHelper.bool(forKey: founderAccessKey)
    }

    func enableFounderAccess() {
        KeychainHelper.setBool(true, forKey: founderAccessKey)
        UserDefaults.standard.set(true, forKey: "isPremium")
    }

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

    // Prix réels lus depuis l'App Store, dans la monnaie du pays de l'utilisateur
    // (l'app est vendue en EUR, USD, CAD et CHF : jamais de prix écrit en dur),
    // et droit à l'essai gratuit (une personne qui l'a déjà utilisé n'y a plus droit —
    // lui afficher "3 jours gratuits" serait trompeur, Apple refuse ça).
    func loadPrices() async -> PlanPrices {
        guard let offering = try? await Purchases.shared.offerings().current else {
            return .fallback
        }
        func product(_ plan: SubscriptionPlan) -> StoreProduct? {
            offering.availablePackages.first { $0.storeProduct.productIdentifier == plan.productId }?.storeProduct
        }

        var prices = PlanPrices.fallback
        if let weekly = product(.weekly) {
            prices.weekly = weekly.localizedPriceString
        }
        if let yearly = product(.yearly) {
            prices.yearly = yearly.localizedPriceString
            prices.yearlyPerWeek = yearly.localizedPricePerWeek ?? prices.yearlyPerWeek
            if yearly.introductoryDiscount == nil {
                prices.isTrialEligible = false
            } else {
                // .unknown (statut indéterminable) : on laisse l'essai, c'est StoreKit
                // qui aura le dernier mot au moment de l'achat
                let status = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: yearly)
                prices.isTrialEligible = status != .ineligible && status != .noIntroOfferExists
            }
        }
        return prices
    }

    // Obligatoire App Store : bouton "Restore Purchases"
    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        applyEntitlement(from: info)
    }

    private func applyEntitlement(from info: CustomerInfo) {
        let isActive = info.entitlements[premiumEntitlementId]?.isActive == true
        UserDefaults.standard.set(isActive || hasFounderAccess, forKey: "isPremium")
        if let productId = info.entitlements[premiumEntitlementId]?.productIdentifier {
            UserDefaults.standard.set(productId, forKey: "activePlanId")
        }
    }

    // Vérifié à chaque lancement (voir AmenaApp) pour que l'accès créateur soit
    // restauré automatiquement même si l'app a été supprimée puis réinstallée,
    // sans attendre que checkCurrentSubscription() ait pu tourner.
    func restoreFounderAccessIfNeeded() {
        if hasFounderAccess {
            UserDefaults.standard.set(true, forKey: "isPremium")
        }
    }

    var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
}

// Prix affichés sur le paywall, déjà formatés dans la monnaie de l'utilisateur
struct PlanPrices: Sendable {
    var weekly: String
    var yearly: String
    var yearlyPerWeek: String
    var isTrialEligible: Bool

    // Utilisé seulement si l'App Store ne répond pas : prix du pays de base (Belgique)
    static let fallback = PlanPrices(weekly: "4,99 €", yearly: "29,99 €", yearlyPerWeek: "0,58 €", isTrialEligible: true)
}

enum PurchaseError: Error {
    case productNotFound
    case userCancelled
}
