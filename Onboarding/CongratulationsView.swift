// Écran 12 : félicitations après la première prière
// Carte récap de la prière avec date et thème

import SwiftUI

struct CongratulationsView: View {
    let prayer: String
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Titre "congratulations!" en orange
                VStack(spacing: 8) {
                    Text(t("congratulations!", "félicitations !"))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color.amenaPrimary)

                    Text(t("you've completed your first prayer", "vous avez complété votre première prière"))
                        .font(.system(size: 18))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Carte récap de la prière
                PrayerRecapCard(prayer: prayer)
                    .padding(.horizontal, 24)

                // Texte explicatif en bas
                Text(t("your prayers will be saved in your journal to help you build a stronger relationship with God.", "vos prières seront sauvegardées dans votre journal pour vous aider à construire une relation plus forte avec Dieu."))
                    .font(.system(size: 14))
                    .foregroundColor(Color.amenaTextSecondary)
                    .multilineTextAlignment(.center)
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

// Carte récap de la prière
struct PrayerRecapCard: View {
    let prayer: String
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var prayerPreview: String {
        let words = prayer.split(separator: " ").prefix(20)
        return words.joined(separator: " ") + (prayer.split(separator: " ").count > 20 ? "..." : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête avec thème et date
            HStack {
                // Badge "Prayer" orange
                Text(t("Daily Prayer", "Prière du jour"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.amenaPrimary)
                    .cornerRadius(8)

                Spacer()

                // Date du jour
                Text(Date(), style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(Color.amenaTextSecondary)
            }

            // Début du texte de la prière
            Text(prayerPreview)
                .font(.system(size: 15))
                .foregroundColor(Color.amenaText)
                .lineSpacing(4)

            // Référence biblique (fixe pour la première prière)
            Text("— Matthew 6:9-13")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.amenaPrimary)
        }
        .padding(20)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.amenaPrimary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    CongratulationsView(
        prayer: "Heavenly Father, thank you for this beautiful day. Help me to seek You first in all that I do...",
        onNext: {}
    )
}
