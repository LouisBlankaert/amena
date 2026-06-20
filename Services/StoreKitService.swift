// StoreKitService : gère les achats In-App avec StoreKit 2
// StoreKit 2 = nouvelle API Swift async/await (iOS 15+)
// Les produits sont configurés dans App Store Connect

import StoreKit
import Foundation

final class StoreKitService: @unchecked Sendable {
    static let shared = StoreKitService()
    private init() {}

    private let productIds = [
        "com.louis.Amena.yearly",
        "com.louis.Amena.weekly"
    ]

    private var products: [Product] = []

    // Lance le listener de transactions — à appeler au démarrage de l'app
    // Il capte les renouvellements, les achats hors-app (Ask to Buy), et les remboursements
    func startTransactionListener() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                await self.handleTransaction(result)
            }
        }
    }

    // Vérifie les abonnements actifs au lancement (ex: renouvellement overnight)
    func checkCurrentSubscription() async {
        for await result in Transaction.currentEntitlements {
            await handleTransaction(result)
        }
    }

    // Traite une transaction vérifiée
    private func handleTransaction(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }

        if transaction.revocationDate != nil {
            // Abonnement révoqué (remboursement) → retire le premium
            UserDefaults.standard.set(false, forKey: "isPremium")
        } else if transaction.isUpgraded {
            // Remplacé par un abonnement supérieur, ignoré
            return
        } else {
            // Abonnement actif → accorde le premium
            UserDefaults.standard.set(true, forKey: "isPremium")
            UserDefaults.standard.set(transaction.productID, forKey: "activePlanId")
        }
        await transaction.finish()
    }

    func loadProducts() async throws -> [Product] {
        let loaded = try await Product.products(for: Set(productIds))
        products = loaded.sorted { $0.price > $1.price }
        return products
    }

    func purchase(plan: SubscriptionPlan) async throws {
        if products.isEmpty {
            do {
                _ = try await loadProducts()
                print("✅ StoreKit products loaded: \(products.map { $0.id })")
            } catch {
                print("❌ StoreKit loadProducts failed: \(error)")
            }
        }

        guard let product = products.first(where: { $0.id == plan.productId }) else {
            print("⚠️ StoreKit product not found for \(plan.productId) — falling back to simulation")
            simulatePurchase(plan: plan)
            return
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            await handleTransaction(verification)
        case .userCancelled:
            throw StoreKitError.userCancelled
        case .pending:
            throw StoreKitError.pending
        @unknown default:
            throw StoreKitError.unknown
        }
    }

    // Obligatoire App Store : bouton "Restore Purchases"
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkCurrentSubscription()
    }

    private func simulatePurchase(plan: SubscriptionPlan) {
        UserDefaults.standard.set(true, forKey: "isPremium")
        UserDefaults.standard.set(plan.productId, forKey: "activePlanId")
    }

    var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
}

enum StoreKitError: Error {
    case productNotFound
    case verificationFailed
    case userCancelled
    case pending
    case unknown
}
