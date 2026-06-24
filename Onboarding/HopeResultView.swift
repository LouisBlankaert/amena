// Écran 6 : message d'espoir — "nous t'aidons à rendre X années à Dieu"
// Fond dégradé blanc → orange pâle, illustration colombe

import SwiftUI

struct HopeResultView: View {
    let dailyScreenTime: Double
    let onNext: () -> Void

    // Même calcul que ShockResultView
    private var yearsToGiveBack: Int {
        let hoursOnPhone = dailyScreenTime * 365.0 * 50.0
        let totalHoursIn50Years = 24.0 * 365.0 * 50.0
        return max(1, Int(hoursOnPhone / totalHoursIn50Years * 50.0))
    }

    var body: some View {
        ZStack {
            AmenaGradientBackground()

            VStack(spacing: 32) {
                Spacer()

                // Illustration colombe
                Image("hope_dove")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)

                // Texte principal
                VStack(spacing: 16) {
                    Text("with amena, you could reclaim")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Nombre d'années en très grand, bleu
                    (Text("\(yearsToGiveBack) years")
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold)
                     + Text(" for God.")
                        .foregroundColor(Color.amenaText))
                    .font(.system(size: 42, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                }

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
    HopeResultView(dailyScreenTime: 4.0, onNext: {})
}
