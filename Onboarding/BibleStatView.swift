// Écran 7 : statistique inspirante — "tu pourrais lire toute la Bible en X jours"
// Fond dégradé blanc → orange pâle, illustration livre/Bible

import SwiftUI

struct BibleStatView: View {
    let dailyScreenTime: Double
    let onNext: () -> Void

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

                // Illustration livre/Bible (SF Symbol)
                ZStack {
                    Circle()
                        .fill(Color.amenaOrangePale)
                        .frame(width: 160, height: 160)
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 65))
                        .foregroundColor(Color.amenaPrimary)
                }

                // Texte principal avec "Bible" et nombre de jours en orange
                VStack(spacing: 16) {
                    (Text("you could read the entire ")
                        .foregroundColor(Color.amenaText)
                     + Text("Bible")
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold)
                     + Text(" in ")
                        .foregroundColor(Color.amenaText)
                     + Text("\(daysToReadBible) days.")
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.bold))
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                    Text("if you swapped half your screen time for prayer.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
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
    BibleStatView(dailyScreenTime: 3.0, onNext: {})
}
