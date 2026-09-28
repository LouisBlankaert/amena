// Écran paywall : abonnement avec essai gratuit 3 jours
// 2 options : mensuel et annuel (mis en avant, avec l'économie affichée)

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
        formatter.locale = appLocale
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
                            // Mensuel
                            PlanOptionCard(
                                plan: .monthly,
                                prices: prices,
                                isSelected: selectedPlan == .monthly,
                                onSelect: { selectedPlan = .monthly }
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
                                    .foregroundColor(Color.amenaNightBlue)
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
                                    .background(Color.amenaNightBlue)
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
            return t("3 days free, then \(prices.yearly)/year (\(prices.yearlyPerMonth)/month), cancel anytime",
                     "3 jours gratuits, puis \(prices.yearly)/an (\(prices.yearlyPerMonth)/mois), annulation possible")
        case .yearly:
            return t("\(prices.yearly)/year (\(prices.yearlyPerMonth)/month), billed yearly, cancel anytime",
                     "\(prices.yearly)/an (\(prices.yearlyPerMonth)/mois), facturation annuelle, annulation possible")
        case .monthly:
            return t("\(prices.monthly)/month, billed monthly, cancel anytime",
                     "\(prices.monthly)/mois, facturation mensuelle, annulation possible")
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
                    // Rappel fin d'essai uniquement s'il y a vraiment un essai (mensuel = paiement immédiat)
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
    case monthly, yearly

    var productId: String {
        switch self {
        case .monthly: return "com.louis.Amena.monthly"
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
                                .fill(Color.amenaNightBlue)
                                .frame(width: 36, height: 36)
                            Image(systemName: step.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        // Ligne verticale entre les icônes (sauf pour le dernier)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(Color.amenaNightBlue.opacity(0.3))
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
        plan == .monthly ? t("monthly", "mensuel") : t("yearly", "annuel")
    }

    // Prix par semaine : affiché en subordonné (Apple 3.1.2(c) — le montant facturé
    // doit être l'élément le plus visible, le calcul par semaine passe en second plan)
    private var pricePerMonthSubordinate: String {
        plan == .monthly ? "" : t("(\(prices.yearlyPerMonth)/month)", "(\(prices.yearlyPerMonth)/mois)")
    }

    private var totalPrice: String {
        plan == .monthly ? t("\(prices.monthly)/month", "\(prices.monthly)/mois") : t("\(prices.yearly)/year", "\(prices.yearly)/an")
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Checkmark ou cercle vide
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.amenaNightBlue : Color.amenaTextSecondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.amenaNightBlue)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.amenaText)
                        // Annuel : l'économie par rapport au mensuel, toujours visible
                        if plan == .yearly && prices.yearlySavingsPercent > 0 {
                            Text("−\(prices.yearlySavingsPercent) %")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.amenaGold)
                                .clipShape(Capsule())
                        }
                    }
                    // Essai gratuit : seulement si la personne y a droit
                    if plan == .yearly && prices.isTrialEligible {
                        Text(t("3 days free", "3 jours gratuits"))
                            .font(.system(size: 13))
                            .foregroundColor(Color.amenaTextSecondary)
                    }
                }

                Spacer()

                // Montant réellement facturé : élément dominant (gros, bold, couleur primaire)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(totalPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? Color.amenaNightBlue : Color.amenaText)
                    // Équivalent par mois : subordonné (petit, gris)
                    if !pricePerMonthSubordinate.isEmpty {
                        Text(pricePerMonthSubordinate)
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
                    .stroke(isSelected ? Color.amenaNightBlue : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.amenaNightBlue.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// Écran après l'achat : confirmation, sous le ciel comme le reste du parcours
struct PostPaywallView: View {
    let plan: SubscriptionPlan
    let hadTrial: Bool
    let prices: PlanPrices
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        ZStack {
            SkyBackground(moment: SkyMoment.current).ignoresSafeArea()
            Color.black.opacity(0.12).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Image(systemName: hadTrial ? "bell.fill" : "sun.max.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())

                Text(hadTrial
                     ? t("Your 3 free days start now.", "Vos 3 jours gratuits commencent.")
                     : t("Welcome to amena.", "Bienvenue sur amena."))
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)

                Text(hadTrial
                     ? t("Nothing to pay today. We'll remind you the day before your trial ends.",
                         "Rien à payer aujourd'hui. Nous vous préviendrons la veille de la fin de l'essai.")
                     : t("Your first prayer is waiting for you, every day.",
                         "Votre prière vous attend, chaque jour."))
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                Spacer()

                OnboardingButton(title: t("Start praying", "Commencer à prier"), action: onNext)

                Text(plan == .yearly
                     ? t("\(prices.yearly) per year, cancel anytime", "\(prices.yearly) par an, annulation possible à tout moment")
                     : t("\(prices.monthly) per month, cancel anytime", "\(prices.monthly) par mois, annulation possible à tout moment"))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    PaywallView(onNext: {})
}
