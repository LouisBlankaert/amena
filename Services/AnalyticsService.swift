// AnalyticsService : wrapper autour de Firebase Analytics
// Centralise tous les events pour pouvoir les modifier facilement
// FirebaseAnalytics doit être importé — disponible après résolution SPM dans Xcode

import Foundation
import FirebaseAnalytics

// Enum des noms d'events (évite les fautes de frappe avec des strings brutes)
enum AnalyticsEvent {
    case onboardingStarted
    case onboardingCompleted
    case prayerStarted
    case prayerCompleted
    case paywallShown
    case trialStarted
    case subscriptionPurchased(plan: String)

    // Nom exact de l'event tel qu'il apparaîtra dans Firebase Console
    var name: String {
        switch self {
        case .onboardingStarted:      return "onboarding_started"
        case .onboardingCompleted:    return "onboarding_completed"
        case .prayerStarted:          return "prayer_started"
        case .prayerCompleted:        return "prayer_completed"
        case .paywallShown:           return "paywall_shown"
        case .trialStarted:           return "trial_started"
        case .subscriptionPurchased:  return "subscription_purchased"
        }
    }

    // Paramètres supplémentaires envoyés avec l'event (optionnels)
    var parameters: [String: Any]? {
        switch self {
        case .subscriptionPurchased(let plan):
            return ["plan": plan]   // ex: "yearly" ou "weekly"
        default:
            return nil
        }
    }
}

// Singleton pour logger des events depuis n'importe où dans l'app
final class AnalyticsService: @unchecked Sendable {
    static let shared = AnalyticsService()
    private init() {}

    // Log un event Firebase Analytics
    // Appelé comme : AnalyticsService.shared.log(.prayerCompleted)
    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
