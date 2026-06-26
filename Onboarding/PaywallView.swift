// Écran paywall : abonnement avec essai gratuit 3 jours
// 2 options : weekly (ancrage) et yearly (mis en avant)

import SwiftUI
import FirebaseAnalytics

struct PaywallView: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showPostPaywall = false
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var restoreMessage = ""
    @State private var purchasedPlan: SubscriptionPlan = .yearly

    // Date de fin d'essai = aujourd'hui + 3 jours
    private var trialEndDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        if showPostPaywall {
            PostPaywallView(plan: purchasedPlan, onNext: onNext)
        } else {
            mainPaywall
        }
    }

    private var mainPaywall: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()
                .onAppear {
                    // Paywall affiché → event "paywall_shown"
                    AnalyticsService.shared.log(.paywallShown)
                }

            ScrollView {
                VStack(spacing: 24) {
                    // En-tête : laurier + étoiles
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "laurel.leading")
                                .foregroundColor(Color.amenaPrimary)
                            Text(t("your daily prayer companion", "votre compagnon de prière quotidien"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.amenaText)
                            Image(systemName: "laurel.trailing")
                                .foregroundColor(Color.amenaPrimary)
                        }
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding(.top, 60)

                    // Titre : adapté selon le plan
                    Text(selectedPlan == .yearly ? t("try amena free for 3 days", "essayez amena gratuitement 3 jours") : t("start praying today", "commencez à prier aujourd'hui"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .animation(.easeInOut(duration: 0.2), value: selectedPlan)

                    // Timeline : uniquement pour yearly (free trial)
                    if selectedPlan == .yearly {
                        TrialTimeline(trialEndDate: trialEndDate)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Options d'abonnement
                    VStack(spacing: 12) {
                        // Weekly (ancrage psychologique)
                        PlanOptionCard(
                            plan: .weekly,
                            isSelected: selectedPlan == .weekly,
                            onSelect: { selectedPlan = .weekly }
                        )
                        // Yearly (mis en avant)
                        PlanOptionCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly,
                            onSelect: { selectedPlan = .yearly }
                        )
                    }
                    .padding(.horizontal, 24)

                    // "No Payment Due Now" uniquement pour yearly
                    if selectedPlan == .yearly {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.amenaPrimary)
                            Text(t("No Payment Due Now", "Aucun paiement maintenant"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.amenaText)
                        }
                        .transition(.opacity)
                    }

                    // Bouton principal orange
                    Button {
                        startTrial()
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.amenaPrimary)
                                .cornerRadius(16)
                                .padding(.horizontal, 24)
                        } else {
                            Text(selectedPlan == .yearly ? t("start my free trial", "commencer mon essai gratuit") : t("subscribe now", "s'abonner maintenant"))
                                .amenaPrimaryButton()
                        }
                    }

                    // Texte légal adapté au plan
                    Text(selectedPlan == .yearly
                         ? t("3 days free, then 89,99 €/year (1,73 €/week)", "3 jours gratuits, puis 89,99 €/an (1,73 €/semaine)")
                         : t("9,99 €/week — billed weekly, cancel anytime", "9,99 €/semaine — facturation hebdomadaire, annulation possible"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)

                    // Liens Privacy + Terms
                    HStack(spacing: 16) {
                        Button(t("Privacy", "Confidentialité")) {}
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                        Text("•")
                            .foregroundColor(Color.amenaTextSecondary)
                        Button(t("Terms", "Conditions")) {}
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                        Text("•")
                            .foregroundColor(Color.amenaTextSecondary)
                        Button(isRestoring ? t("Restoring...", "Restauration...") : t("Restore", "Restaurer")) {
                            restorePurchases()
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color.amenaTextSecondary)
                        .disabled(isRestoring)
                    }
                    if !restoreMessage.isEmpty {
                        Text(restoreMessage)
                            .font(.system(size: 12))
                            .foregroundColor(StoreKitService.shared.isPremium ? .green : Color.amenaTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true
        Task {
            do {
                try await StoreKitService.shared.restorePurchases()
                await MainActor.run {
                    isRestoring = false
                    if StoreKitService.shared.isPremium {
                        restoreMessage = "Purchase restored successfully!"
                        // Redirige vers l'app après un court délai
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showPostPaywall = true
                        }
                    } else {
                        restoreMessage = "No active subscription found."
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    restoreMessage = "Restore failed. Please try again."
                }
            }
        }
    }

    // Lance le processus d'achat via StoreKit
    private func startTrial() {
        isPurchasing = true
        Task {
            do {
                try await StoreKitService.shared.purchase(plan: selectedPlan)
                await MainActor.run {
                    isPurchasing = false
                    purchasedPlan = selectedPlan
                    AnalyticsService.shared.log(.trialStarted)
                    AnalyticsService.shared.log(.subscriptionPurchased(plan: selectedPlan.productId))
                    // Rappel fin d'essai uniquement pour le plan yearly (weekly = paiement immédiat)
                    if selectedPlan == .yearly {
                        NotificationService.shared.scheduleTrialEndingReminder()
                    }
                    showPostPaywall = true
                }
            } catch StoreKitError.userCancelled {
                await MainActor.run {
                    isPurchasing = false
                    // L'utilisateur a annulé → on reste sur le paywall
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    // Erreur → on reste sur le paywall
                }
            }
        }
    }
}

// Types d'abonnement disponibles
enum SubscriptionPlan {
    case weekly, yearly

    var productId: String {
        switch self {
        case .weekly: return "com.louis.Amena.weekly"
        case .yearly: return "com.louis.Amena.yearly"
        }
    }
}

// Timeline verticale "today → in 2 days → in 3 days"
struct TrialTimeline: View {
    let trialEndDate: String
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var steps: [(icon: String, time: String, description: String)] {
        [
            ("lock.open.fill", t("today", "aujourd'hui"), t("unlock all the app's features for free during your trial.", "débloquez toutes les fonctionnalités gratuitement pendant votre essai.")),
            ("bell.fill", t("in 2 Days", "dans 2 jours"), t("we'll send you a reminder that your trial is ending soon.", "nous vous enverrons un rappel que votre essai se termine bientôt.")),
            ("crown.fill", t("in 3 Days", "dans 3 jours"), t("you'll be charged unless you cancel anytime before.", "vous serez facturé sauf si vous annulez avant."))
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 16) {
                    // Icône dans un cercle orange
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color.amenaPrimary)
                                .frame(width: 36, height: 36)
                            Image(systemName: step.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        // Ligne verticale entre les icônes (sauf pour le dernier)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(Color.amenaPrimary.opacity(0.3))
                                .frame(width: 2, height: 32)
                        }
                    }

                    // Texte de l'étape
                    VStack(alignment: .leading, spacing: 3) {
                        Text(index == 2 ? trialEndDate : step.time)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.amenaText)
                        Text(step.description)
                            .font(.system(size: 13))
                            .foregroundColor(Color.amenaTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, index < steps.count - 1 ? 0 : 8)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
    }
}

// Carte d'option d'abonnement
struct PlanOptionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var title: String {
        plan == .weekly ? t("weekly", "hebdomadaire") : t("yearly", "annuel")
    }

    private var pricePerWeek: String {
        plan == .weekly ? t("9,99€/week", "9,99€/semaine") : t("1,73€/week", "1,73€/semaine")
    }

    private var totalPrice: String {
        plan == .weekly ? t("9,99€/week", "9,99€/semaine") : t("89,99€/year", "89,99€/an")
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Checkmark ou cercle vide
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.amenaPrimary : Color.amenaTextSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.amenaPrimary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.amenaText)
                        // Badge "3-day free trial" uniquement sur l'option yearly
                        if plan == .yearly {
                            Text(t("3-day free trial", "3 jours gratuits"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.amenaPrimary)
                                .cornerRadius(6)
                        }
                    }
                    Text(totalPrice)
                        .font(.system(size: 13))
                        .foregroundColor(Color.amenaTextSecondary)
                }

                Spacer()

                // Prix par semaine
                Text(pricePerWeek)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? Color.amenaPrimary : Color.amenaText)
            }
            .padding(16)
            .background(isSelected ? Color.white : Color.amenaSecondaryBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.amenaPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.amenaPrimary.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// Écran post-paywall : confirmation de démarrage de l'essai
struct PostPaywallView: View {
    let plan: SubscriptionPlan
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.amenaOrangePale)
                            .frame(width: 120, height: 120)
                        Image(systemName: plan == .yearly ? "bell.fill" : "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.amenaPrimary)
                    }
                    if plan == .yearly {
                        ZStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 24, height: 24)
                            Text("1")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text(plan == .yearly
                         ? t("we'll send you a reminder before your free trial ends", "nous vous enverrons un rappel avant la fin de votre essai gratuit")
                         : t("you're all set! welcome to amena.", "tout est prêt ! bienvenue sur amena."))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if plan == .yearly {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.amenaPrimary)
                                .fontWeight(.bold)
                            Text(t("No Payment Due Now", "Aucun paiement maintenant"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.amenaText)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Button {
                        onNext()
                    } label: {
                        Text(plan == .yearly ? t("continue for FREE", "continuer GRATUITEMENT") : t("start praying", "commencer à prier"))
                            .amenaPrimaryButton()
                    }

                    Text(plan == .yearly
                         ? t("just 89,99 € per year (1,73 €/week)", "seulement 89,99 € par an (1,73 €/semaine)")
                         : t("9,99 €/week — cancel anytime", "9,99 €/semaine — annulation possible"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.amenaTextSecondary)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    PaywallView(onNext: {})
}
