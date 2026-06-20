// Écran 4 : fréquence de prière hebdomadaire
// Slider de 0 à 7 jours/semaine

import SwiftUI

struct PrayerFrequencyView: View {
    @Binding var frequency: Double   // Valeur en jours par semaine
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 4, totalSteps: 9)
                    .padding(.top, 60)

                VStack(spacing: 40) {
                    Text("be honest, how often do you pray per week?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)

                    // Valeur en grand
                    VStack(spacing: 4) {
                        // Int() arrondit le Double à l'entier le plus proche
                        Text("\(Int(frequency))")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(Color.amenaPrimary)

                        Text("days/week")
                            .font(.system(size: 17))
                            .foregroundColor(Color.amenaTextSecondary)
                    }

                    // Slider de 0 à 7 (entiers)
                    VStack(spacing: 12) {
                        Slider(value: $frequency, in: 0...7, step: 1)
                            .tint(Color.amenaPrimary)
                            .padding(.horizontal, 24)

                        HStack {
                            Text("0")
                                .font(.system(size: 13))
                                .foregroundColor(Color.amenaTextSecondary)
                            Spacer()
                            Text("7")
                                .font(.system(size: 13))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }

                Button {
                    UserDefaults.standard.set(frequency, forKey: "prayerFrequency")
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
    PrayerFrequencyView(frequency: .constant(2.0), onNext: {})
}
