// Écran paywall : abonnement avec essai gratuit 3 jours
// 2 options : weekly (ancrage) et yearly (mis en avant)
// Suivi de Superwall SDK (sera intégré après setup SPM)

import SwiftUI

struct PaywallView: View {
    let onNext: () -> Void

    // Option sélectionnée par défaut : yearly (mis en avant)
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showPostPaywall = false
    @State private var isPurchasing = false

    // Date de fin d'essai = aujourd'hui + 3 jours
    private var trialEndDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        if showPostPaywall {
            PostPaywallView(onNext: onNext)
        } else {
            mainPaywall
        }
    }

    private var mainPaywall: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // En-tête : laurier + étoiles
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "laurel.leading")
                                .foregroundColor(Color.amenaPrimary)
                            Text("the #1 prayer habit app")
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

                    // Titre principal
                    Text("start your 3-day FREE trial to continue")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Timeline verticale des 3 étapes
                    TrialTimeline(trialEndDate: trialEndDate)
                        .padding(.horizontal, 24)

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

                    // Badge "No Payment Due Now"
                    HStack(spacing: 6) {
                        Text("✓")
                            .foregroundColor(Color.amenaPrimary)
                            .fontWeight(.bold)
                        Text("No Payment Due Now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.amenaText)
                        Text("👇")
                    }
                    .font(.system(size: 14))

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
                            Text("start my free trial")
                                .amenaPrimaryButton()
                        }
                    }

                    // Texte légal petit
                    Text("3 days free, then 89,99 €/year (1,73 €/week)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)

                    // Liens Privacy + Terms
                    HStack(spacing: 16) {
                        Button("Privacy") {}
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                        Text("•")
                            .foregroundColor(Color.amenaTextSecondary)
                        Button("Terms") {}
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                        Text("•")
                            .foregroundColor(Color.amenaTextSecondary)
                        Button("Restore") {}
                            .font(.system(size: 12))
                            .foregroundColor(Color.amenaTextSecondary)
                    }
                    .padding(.bottom, 40)
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
                    showPostPaywall = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    // En cas d'erreur, on laisse passer quand même (MVP)
                    showPostPaywall = true
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

    private let steps: [(icon: String, time: String, description: String)] = [
        ("lock.open.fill", "today", "unlock all the app's features for free during your trial."),
        ("bell.fill", "in 2 Days", "we'll send you a reminder that your trial is ending soon."),
        ("crown.fill", "in 3 Days", "you'll be charged unless you cancel anytime before.")
    ]

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

    private var title: String {
        plan == .weekly ? "weekly" : "yearly"
    }

    private var pricePerWeek: String {
        plan == .weekly ? "9,99€/week" : "1,73€/week"
    }

    private var totalPrice: String {
        plan == .weekly ? "9,99€/week" : "89,99€/year"
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
                            Text("3-day free trial")
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
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Illustration cloche avec badge "1"
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.amenaOrangePale)
                            .frame(width: 120, height: 120)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.amenaPrimary)
                    }
                    // Badge rouge "1"
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 24, height: 24)
                        Text("1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(spacing: 12) {
                    Text("we'll send you a reminder before your free trial ends")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    HStack(spacing: 6) {
                        Text("✓")
                            .foregroundColor(Color.amenaPrimary)
                            .fontWeight(.bold)
                        Text("No Payment Due Now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.amenaText)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Button {
                        onNext()
                    } label: {
                        Text("continue for FREE")
                            .amenaPrimaryButton()
                    }

                    Text("just 89,99 € per year (1,73 €/week)")
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
