// Écran 13 : verset du jour
// Fond dégradé bleu nuit → bleu ciel, carte blanche avec verset

import SwiftUI

struct VerseOfDayView: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var todayVerse: (text: String, reference: String) {
        DailyVerse.today
    }

    var body: some View {
        ZStack {
            // Fond dégradé bleu nuit → bleu ciel
            LinearGradient(
                colors: [Color.amenaNightBlue, Color.amenaSkyBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Label "VERSE OF THE DAY" en small caps
                Text(t("VERSE OF THE DAY", "VERSET DU JOUR"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(2) // Espacement entre les lettres

                // Carte blanche avec le verset
                VStack(spacing: 16) {
                    Text(todayVerse.text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    Text(todayVerse.reference)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.amenaPrimary)

                    // Bouton partage centré sous la référence
                    Button {
                        shareVerse()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                            Text(t("share", "partager"))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color.amenaTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.amenaSecondaryBackground)
                        .cornerRadius(20)
                    }
                }
                .padding(28)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)

                Spacer()

                // Bouton blanc avec texte orange
                Button {
                    onNext()
                } label: {
                    Text(t("continue", "continuer"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.amenaPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func shareVerse() {
        let text = "\(todayVerse.text)\n— \(todayVerse.reference)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    VerseOfDayView(onNext: {})
}
