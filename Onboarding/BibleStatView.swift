// Écran 7 : statistique inspirante — "tu pourrais lire toute la Bible en X jours"
// Fond dégradé blanc → orange pâle, illustration livre/Bible

import SwiftUI

struct BibleStatView: View {
    let dailyScreenTime: Double
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    // Calcul : Bible ≈ 777 000 mots, vitesse lecture ≈ 200 mots/min
    // Heures de lecture disponibles = temps screen time converti en prière
    private var daysToReadBible: Int {
        let bibleWords = 777_000.0
        let wordsPerMinute = 200.0
        let minutesToReadBible = bibleWords / wordsPerMinute     // ≈ 3885 minutes
        let hoursToReadBible = minutesToReadBible / 60.0         // ≈ 64.75 heures

        // On utilise la moitié du screen time quotidien comme temps de prière/lecture
        let prayerHoursPerDay = dailyScreenTime / 2.0
        let days = hoursToReadBible / prayerHoursPerDay
        return max(1, Int(days))
    }

    var body: some View {
        ZStack {
            AmenaGradientBackground()

            VStack(spacing: 32) {
                Spacer()

                // Illustration Bible
                Image("bible_book")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)

                // Texte principal avec "Bible" et nombre de jours en orange
                VStack(spacing: 16) {
                    (Text(t("you could read the entire ", "tu pourrais lire toute la "))
                        .foregroundColor(Color.amenaText)
                     + Text("Bible")
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold)
                     + Text(t(" in ", " en "))
                        .foregroundColor(Color.amenaText)
                     + Text(t("\(daysToReadBible) days.", "\(daysToReadBible) jours."))
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold))
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                    Text(t("if you swapped half your screen time for prayer.", "si tu échangeais la moitié de ton temps d'écran contre la prière."))
                        .font(.system(size: 16))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
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
    BibleStatView(dailyScreenTime: 3.0, onNext: {})
}
