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
    @State private var purchaseErrorMessage = ""
    @State private var showReferralField = false
    @State private var referralCode = ""
    // Prix réels de l'App Store (monnaie du pays) + droit à l'essai, chargés à l'affichage
    @State private var prices = PlanPrices.fallback
    @State private var pricesLoaded = false
    @State private var purchasedWithTrial = false

    // L'essai gratuit ne concerne que l'annuel, et seulement si la personne y a encore droit
    private var showsTrial: Bool { selectedPlan == .yearly && prices.isTrialEligible }

    // Date de fin d'essai = aujourd'hui + 3 jours
    private var trialEndDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        if showPostPaywall {
            PostPaywallView(plan: purchasedPlan, hadTrial: purchasedWithTrial, prices: prices, onNext: onNext)
        } else {
            mainPaywall
        }
    }

    private var mainPaywall: some View {
        ZStack {
            // Ciel en haut (rebond du scroll), blanc en bas : continuité avec le panneau
            VStack(spacing: 0) {
                SkyMoment.current.colors.first!.frame(height: 300)
                Color.amenaBackground
            }
            .ignoresSafeArea()
            .onAppear {
                // Si l'utilisateur est déjà abonné (ex: reset onboarding après un achat réel),
                // on ne lui redemande pas de payer — StoreKit sait déjà qu'il est premium.
                guard !RevenueCatService.shared.isPremium else {
                    onNext()
                    return
                }
                // Paywall affiché → event "paywall_shown"
                AnalyticsService.shared.log(.paywallShown)
            }

            ScrollView {
                VStack(spacing: 0) {
                    // En-tête sous le ciel : ce qu'on obtient, avant de parler prix
                    VStack(alignment: .leading, spacing: 18) {
                        Text(showsTrial ? t("Try amena free for 3 days", "Essayez amena gratuitement 3 jours") : t("Start praying today", "Commencez à prier aujourd'hui"))
                            .font(.system(size: 32, weight: .regular, design: .serif))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(.easeInOut(duration: 0.2), value: selectedPlan)

                        VStack(alignment: .leading, spacing: 12) {
                            PaywallBenefit(icon: "hands.sparkles.fill", text: t("A new prayer every day, written about what you're living", "Chaque jour, une nouvelle prière écrite sur ce que vous vivez"))
                            PaywallBenefit(icon: "book.closed.fill", text: t("The verse of the day at 10 a.m., straight from the Bible", "Le verset du jour à 10 h, tiré de la Bible"))
                            PaywallBenefit(icon: "flame.fill", text: t("Your prayer journal and your streak, day after day", "Votre journal de prière et votre série, jour après jour"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .padding(.bottom, 64)
                    .background(SkyBackground(moment: SkyMoment.current).ignoresSafeArea(edges: .top))

                    VStack(spacing: 24) {
                        // Timeline : uniquement pour yearly (free trial)
                        if showsTrial {
                            TrialTimeline(trialEndDate: trialEndDate)
                                .padding(.horizontal, 24)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Options d'abonnement
                        VStack(spacing: 12) {
                            // Weekly (ancrage psychologique)
                            PlanOptionCard(
                                plan: .weekly,
                                prices: prices,
                                isSelected: selectedPlan == .weekly,
                                onSelect: { selectedPlan = .weekly }
                            )
                            // Yearly (mis en avant)
                            PlanOptionCard(
                                plan: .yearly,
                                prices: prices,
                                isSelected: selectedPlan == .yearly,
                                onSelect: { selectedPlan = .yearly }
                            )
                        }
                        .padding(.horizontal, 24)
                        // Masque les prix de secours tant que l'App Store n'a pas répondu
                        .redacted(reason: pricesLoaded ? [] : .placeholder)

                        // "No Payment Due Now" uniquement pour yearly
                        if showsTrial {
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
                                Text(showsTrial ? t("start my free trial", "commencer mon essai gratuit") : t("subscribe now", "s'abonner maintenant"))
                                    .amenaPrimaryButton()
                            }
                        }

                        // Texte légal adapté au plan
                        Text(legalText)
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .redacted(reason: pricesLoaded ? [] : .placeholder)

                        // Code de parrainage (optionnel) — discret, replié par défaut
                        VStack(spacing: 8) {
                            if showReferralField {
                                TextField(t("referral code", "code de parrainage"), text: $referralCode)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .multilineTextAlignment(.center)
                                    .padding(12)
                                    .background(Color.amenaSecondaryBackground)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 24)
                            } else {
                                Button(t("have a referral code?", "un code de parrainage ?")) {
                                    withAnimation { showReferralField = true }
                                }
                                .font(.system(size: 12))
                                .foregroundColor(Color.amenaTextSecondary)
                            }
                        }

                        // Liens Privacy + Terms
                        HStack(spacing: 16) {
                            Link(t("Privacy", "Confidentialité"), destination: URL(string: "https://louisblankaert.github.io/amena/privacy.html")!)
                                .font(.system(size: 12))
                                .foregroundColor(Color.amenaTextSecondary)
                            Text("•")
                                .foregroundColor(Color.amenaTextSecondary)
                            Link(t("Terms", "Conditions"), destination: URL(string: "https://louisblankaert.github.io/amena/terms.html")!)
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
                                .foregroundColor(RevenueCatService.shared.isPremium ? .green : Color.amenaTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        if !purchaseErrorMessage.isEmpty {
                            Text(purchaseErrorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 28)
                    .background(Color.amenaBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .padding(.top, -32)
                }
            }
        }
        .task {
            prices = await RevenueCatService.shared.loadPrices()
            pricesLoaded = true
        }
    }

    // Texte légal sous le bouton : le montant réellement facturé, toujours visible
    private var legalText: String {
        switch selectedPlan {
        case .yearly where prices.isTrialEligible:
            return t("3 days free, then \(prices.yearly)/year (\(prices.yearlyPerWeek)/week), cancel anytime",
                     "3 jours gratuits, puis \(prices.yearly)/an (\(prices.yearlyPerWeek)/semaine), annulation possible")
        case .yearly:
            return t("\(prices.yearly)/year (\(prices.yearlyPerWeek)/week), billed yearly, cancel anytime",
                     "\(prices.yearly)/an (\(prices.yearlyPerWeek)/semaine), facturation annuelle, annulation possible")
        case .weekly:
            return t("\(prices.weekly)/week, billed weekly, cancel anytime",
                     "\(prices.weekly)/semaine, facturation hebdomadaire, annulation possible")
        }
    }

    private func restorePurchases() {
        isRestoring = true
        Task {
            do {
                try await RevenueCatService.shared.restorePurchases()
                await MainActor.run {
                    isRestoring = false
                    if RevenueCatService.shared.isPremium {
                        restoreMessage = t("Purchase restored!", "Achat restauré !")
                        // Redirige vers l'app après un court délai
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showPostPaywall = true
                        }
                    } else {
                        restoreMessage = t("No active subscription found.", "Aucun abonnement actif trouvé.")
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    restoreMessage = t("Restore failed. Please try again.", "La restauration a échoué. Veuillez réessayer.")
                }
            }
        }
    }

    // Lance le processus d'achat via StoreKit
    private func startTrial() {
        isPurchasing = true
        purchaseErrorMessage = ""
        if !referralCode.isEmpty {
            AffiliateService.shared.setReferralCode(referralCode)
        }
        Task {
            do {
                try await RevenueCatService.shared.purchase(plan: selectedPlan)
                await MainActor.run {
                    isPurchasing = false
                    purchasedPlan = selectedPlan
                    purchasedWithTrial = showsTrial
                    AnalyticsService.shared.log(.trialStarted)
                    AnalyticsService.shared.log(.subscriptionPurchased(plan: selectedPlan.productId))
                    // Rappel fin d'essai uniquement s'il y a vraiment un essai (weekly = paiement immédiat)
                    if purchasedWithTrial {
                        NotificationService.shared.scheduleTrialEndingReminder()
                    }
                    showPostPaywall = true
                }
            } catch PurchaseError.userCancelled {
                await MainActor.run {
                    isPurchasing = false
                    // L'utilisateur a annulé → on reste sur le paywall
                }
            } catch PurchaseError.productNotFound {
                await MainActor.run {
                    isPurchasing = false
                    purchaseErrorMessage = t(
                        "Couldn't reach the App Store. Please check your connection and try again.",
                        "Impossible de contacter l'App Store. Vérifiez votre connexion et réessayez."
                    )
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseErrorMessage = t(
                        "Something went wrong. Please try again.",
                        "Une erreur est survenue. Veuillez réessayer."
                    )
                }
            }
        }
    }
}

// Une ligne d'avantage sous le ciel du paywall
private struct PaywallBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 16))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.white)
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
    let prices: PlanPrices
    let isSelected: Bool
    let onSelect: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var title: String {
        plan == .weekly ? t("weekly", "hebdomadaire") : t("yearly", "annuel")
    }

    // Prix par semaine : affiché en subordonné (Apple 3.1.2(c) — le montant facturé
    // doit être l'élément le plus visible, le calcul par semaine passe en second plan)
    private var pricePerWeekSubordinate: String {
        plan == .weekly ? "" : t("(\(prices.yearlyPerWeek)/week)", "(\(prices.yearlyPerWeek)/semaine)")
    }

    private var totalPrice: String {
        plan == .weekly ? t("\(prices.weekly)/week", "\(prices.weekly)/semaine") : t("\(prices.yearly)/year", "\(prices.yearly)/an")
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
                        if plan == .yearly && prices.isTrialEligible {
                            Text(t("3-day free trial", "3 jours gratuits"))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.amenaPrimary)
                                .cornerRadius(6)
                        }
                    }
                }

                Spacer()

                // Montant réellement facturé : élément dominant (gros, bold, couleur primaire)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(totalPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? Color.amenaPrimary : Color.amenaText)
                    // Équivalent hebdo : subordonné (petit, gris)
                    if !pricePerWeekSubordinate.isEmpty {
                        Text(pricePerWeekSubordinate)
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                    }
                }
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
    let hadTrial: Bool
    let prices: PlanPrices
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
                        Image(systemName: hadTrial ? "bell.fill" : "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.amenaPrimary)
                    }
                    if hadTrial {
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
                    Text(hadTrial
                         ? t("we'll send you a reminder before your free trial ends", "nous vous enverrons un rappel avant la fin de votre essai gratuit")
                         : t("you're all set! welcome to amena.", "tout est prêt ! bienvenue sur amena."))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if hadTrial {
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
                        Text(hadTrial ? t("continue for FREE", "continuer GRATUITEMENT") : t("start praying", "commencer à prier"))
                            .amenaPrimaryButton()
                    }

                    Text(plan == .yearly
                         ? t("\(prices.yearly) per year (\(prices.yearlyPerWeek)/week), cancel anytime", "\(prices.yearly) par an (\(prices.yearlyPerWeek)/semaine), annulation possible")
                         : t("\(prices.weekly)/week, cancel anytime", "\(prices.weekly)/semaine, annulation possible"))
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
