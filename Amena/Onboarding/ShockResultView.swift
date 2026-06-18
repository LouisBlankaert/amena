// Écran 5 : résultat choc — "X années de ta vie passées sur le téléphone"
// Fond dégradé blanc → orange pâle, emoji 🤯, calcul personnalisé

import SwiftUI

struct ShockResultView: View {
    let userName: String
    let dailyScreenTime: Double   // heures/jour
    let onNext: () -> Void

    // Calcul : heures par jour × 365 jours × 50 ans de vie restante / (24h × 365)
    // = proportion de la vie restante passée sur le téléphone
    private var yearsOnPhone: Int {
        let totalHoursIn50Years = 24.0 * 365.0 * 50.0
        let hoursOnPhone = dailyScreenTime * 365.0 * 50.0
        return max(1, Int(hoursOnPhone / totalHoursIn50Years * 50.0))
    }

    var body: some View {
        ZStack {
            // Gradient de fond caractéristique de ces écrans
            AmenaGradientBackground()

            VStack(spacing: 32) {
                Spacer()

                // Emoji choc en grand
                Text("🤯")
                    .font(.system(size: 80))

                // Texte principal avec les années en orange
                VStack(spacing: 8) {
                    Text("\(userName.isEmpty ? "Hey" : userName), at this rate you're going to spend")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)

                    // Années en orange très grand
                    (Text("\(yearsOnPhone) years")
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold)
                        .font(.system(size: 48, weight: .bold))
                     + Text("\nof your life on your phone.")
                        .foregroundColor(Color.amenaText)
                        .font(.system(size: 22, weight: .medium)))
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    onNext()
                } label: {
                    Text("continue")
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    ShockResultView(
        userName: "Louis",
        dailyScreenTime: 4.0,
        onNext: {}
    )
}
