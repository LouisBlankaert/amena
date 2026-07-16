// Écran 6 : message d'espoir — "nous t'aidons à rendre X années à Dieu"
// Fond dégradé blanc → orange pâle, illustration colombe

import SwiftUI

struct HopeResultView: View {
    let dailyScreenTime: Double
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

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
                    Text(t("with amena, you could reclaim", "avec amena, vous pourriez récupérer"))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    (Text(t("\(yearsToGiveBack) years", "\(yearsToGiveBack) ans"))
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold)
                     + Text(t(" for God.", " pour Dieu."))
                        .foregroundColor(Color.amenaText))
                    .font(.system(size: 42, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                }

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
    HopeResultView(dailyScreenTime: 4.0, onNext: {})
}
