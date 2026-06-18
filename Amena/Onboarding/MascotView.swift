// Écran 10 : mascotte mouton
// Carte "trading card" avec nom, niveau, barre FAITH, verset

import SwiftUI

struct MascotView: View {
    @Binding var sheepName: String
    let onNext: () -> Void

    // Verset biblique affiché sur la carte de la mascotte
    private let verse = "\"I am the good shepherd; I know my sheep and my sheep know me.\" — John 10:14"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 9, totalSteps: 9)
                    .padding(.top, 60)

                ScrollView {
                    VStack(spacing: 28) {
                        // Illustration mouton (SF Symbol)
                        ZStack {
                            // Fond sombre représentant l'obscurité/addiction
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#1a1a2e"))
                                .frame(height: 200)
                            VStack(spacing: 8) {
                                Text("🐑")
                                    .font(.system(size: 70))
                                Text("your sheep is chained to the phone...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Champ de nom
                        VStack(alignment: .leading, spacing: 10) {
                            Text("your sheep's name")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.amenaText)

                            TextField("Nour", text: $sheepName)
                                .font(.system(size: 17))
                                .padding(16)
                                .background(Color.amenaSecondaryBackground)
                                .cornerRadius(12)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                        }
                        .padding(.horizontal, 24)

                        // Carte style "trading card"
                        SheepTradingCard(name: sheepName.isEmpty ? "Nour" : sheepName, verse: verse)
                            .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }

                Button {
                    let name = sheepName.isEmpty ? "Nour" : sheepName
                    UserDefaults.standard.set(name, forKey: "sheepName")
                    sheepName = name
                    onNext()
                } label: {
                    Text("let's go →")
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// Carte trading card du mouton
struct SheepTradingCard: View {
    let name: String
    let verse: String

    // Niveau FAITH calculé (commence à 2 dans l'onboarding)
    private let faithLevel = 2
    private let faithPercent = 0.15   // 15% de progression

    var body: some View {
        VStack(spacing: 0) {
            // En-tête de la carte : nom + niveau
            HStack {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("lv \(faithLevel)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.amenaPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Emoji mouton au centre
            Text("🐑")
                .font(.system(size: 64))
                .padding(.vertical, 16)

            // Barre FAITH
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("FAITH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(faithPercent * 100))%")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                // Barre de progression FAITH
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.amenaPrimary)
                            .frame(width: geo.size.width * faithPercent, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)

            // Verset biblique en bas
            Text(verse)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#1a1a4e"), Color(hex: "#2d2d7e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        // Bordure orange subtile
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.amenaPrimary.opacity(0.5), lineWidth: 1.5)
        )
    }
}

#Preview {
    MascotView(sheepName: .constant("Nour"), onNext: {})
}
