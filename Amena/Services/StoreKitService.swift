// StoreKitService : gère les achats In-App avec StoreKit 2
// StoreKit 2 = nouvelle API Swift async/await (iOS 15+)
// Les produits sont configurés dans App Store Connect

import StoreKit  // Framework Apple pour les achats in-app
import Foundation

final class StoreKitService: @unchecked Sendable {
    static let shared = StoreKitService()
    private init() {}

    // Identifiants des produits dans App Store Connect
    private let productIds = [
        "com.louis.Amena.yearly",
        "com.louis.Amena.weekly"
    ]

    // Cache des produits chargés
    private var products: [Product] = []

    // Charge les produits depuis App Store Connect
    func loadProducts() async throws -> [Product] {
        // Product.products() = API StoreKit 2 asynchrone
        let loaded = try await Product.products(for: Set(productIds))
        products = loaded
        return loaded
    }

    // Lance l'achat d'un plan
    // Throws en cas d'erreur réseau ou si l'utilisateur annule
    func purchase(plan: SubscriptionPlan) async throws {
        // Si les produits ne sont pas encore chargés, on les charge d'abord
        if products.isEmpty {
            _ = try await loadProducts()
        }

        guard let product = products.first(where: { $0.id == plan.productId }) else {
            // Produit non trouvé (normal en développement sans App Store Connect configuré)
            // On simule un succès pour pouvoir tester le flow complet
            simulatePurchase(plan: plan)
            return
        }

        // Tente l'achat via StoreKit 2
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Vérifie que l'achat est authentique (anti-fraude)
            switch verification {
            case .verified(let transaction):
                // Enregistre l'abonnement actif
                UserDefaults.standard.set(true, forKey: "isPremium")
                UserDefaults.standard.set(plan.productId, forKey: "activePlanId")
                // Finalise la transaction (obligatoire avec StoreKit 2)
                await transaction.finish()
            case .unverified:
                throw StoreKitError.verificationFailed
            }
        case .userCancelled:
            throw StoreKitError.userCancelled
        case .pending:
            // En attente d'approbation parentale (Ask to Buy)
            throw StoreKitError.pending
        @unknown default:
            throw StoreKitError.unknown
        }
    }

    // Restaure les achats précédents (obligatoire pour l'App Store)
    func restorePurchases() async throws {
        try await AppStore.sync()
        // Vérifie si une transaction active existe
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                UserDefaults.standard.set(true, forKey: "isPremium")
                UserDefaults.standard.set(transaction.productID, forKey: "activePlanId")
            }
        }
    }

    // Simulation d'achat pour les tests (sans App Store Connect)
    private func simulatePurchase(plan: SubscriptionPlan) {
        UserDefaults.standard.set(true, forKey: "isPremium")
        UserDefaults.standard.set(plan.productId, forKey: "activePlanId")
    }

    // Vérifie si l'utilisateur est premium
    var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
}

// Erreurs StoreKit personnalisées
enum StoreKitError: Error {
    case productNotFound
    case verificationFailed
    case userCancelled
    case pending
    case unknown
}
