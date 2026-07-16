// Écran 3 : temps quotidien sur le téléphone
// Slider de 1h à 10h avec valeur affichée en grand

import SwiftUI

struct ScreenTimeView: View {
    @Binding var screenTime: Double
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 3, totalSteps: 9)
                    .padding(.top, 60)

                VStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text(t("how long are you on your phone each day?", "combien de temps passez-vous sur votre téléphone chaque jour ?"))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color.amenaText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 40)

                        Text(t("be honest", "sois honnête"))
                            .font(.system(size: 15))
                            .foregroundColor(Color.amenaTextSecondary)
                    }

                    // Valeur affichée en grand au centre
                    VStack(spacing: 4) {
                        // String(format:) formate le Double avec 1 décimale
                        Text(String(format: "%.1f", screenTime))
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(Color.amenaPrimary)

                        Text(t("hours/day", "heures/jour"))
                            .font(.system(size: 17))
                            .foregroundColor(Color.amenaTextSecondary)
                    }

                    // Slider de 1 à 10 heures
                    VStack(spacing: 12) {
                        Slider(value: $screenTime, in: 1...10, step: 0.5)
                            .tint(Color.amenaPrimary) // Couleur de la barre remplie
                            .padding(.horizontal, 24)

                        // Labels min/max sous le slider
                        HStack {
                            Text("1h")
                                .font(.system(size: 13))
                                .foregroundColor(Color.amenaTextSecondary)
                            Spacer()
                            Text("10h")
                                .font(.system(size: 13))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }

                Button {
                    UserDefaults.standard.set(screenTime, forKey: "dailyScreenTime")
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
    ScreenTimeView(screenTime: .constant(3.5), onNext: {})
}
