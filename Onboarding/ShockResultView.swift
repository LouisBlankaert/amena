// Écran 5 : résultat choc — "X années de ta vie passées sur le téléphone"
// Fond dégradé blanc → orange pâle, emoji 🤯, calcul personnalisé

import SwiftUI

struct ShockResultView: View {
    let userName: String
    let dailyScreenTime: Double
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

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

                // Illustration : téléphone + horloge
                ZStack {
                    Circle()
                        .fill(Color.amenaPrimary.opacity(0.1))
                        .frame(width: 130, height: 130)
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 55))
                        .foregroundColor(Color.amenaPrimary)
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 36, height: 36)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .offset(x: 32, y: -32)
                }

                // Texte principal avec les années en orange
                VStack(spacing: 8) {
                    Text(t("\(userName.isEmpty ? "hey" : userName.lowercased()), you're on track to spend", "\(userName.isEmpty ? "hey" : userName.lowercased()), vous êtes en route pour passer"))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)

                    (Text(t("\(yearsOnPhone) years", "\(yearsOnPhone) ans"))
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold)
                        .font(.system(size: 48, weight: .bold))
                     + Text(t("\nstaring at a screen.", "\nà fixer un écran."))
                        .foregroundColor(Color.amenaText)
                        .font(.system(size: 22, weight: .medium)))
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    onNext()
                } label: {
                    Text(t("continue", "continuer"))
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
