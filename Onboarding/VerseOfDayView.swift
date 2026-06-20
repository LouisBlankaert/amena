// Écran 13 : verset du jour
// Fond dégradé bleu nuit → bleu ciel, carte blanche avec verset

import SwiftUI

struct VerseOfDayView: View {
    let onNext: () -> Void

    // Versets bibliques (rotation quotidienne basée sur le jour de l'année)
    private let verses: [(text: String, reference: String)] = [
        ("For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", "Jeremiah 29:11"),
        ("Trust in the Lord with all your heart and lean not on your own understanding.", "Proverbs 3:5"),
        ("I can do all this through him who gives me strength.", "Philippians 4:13"),
        ("The Lord is my shepherd, I lack nothing.", "Psalm 23:1"),
        ("Be still, and know that I am God.", "Psalm 46:10"),
        ("Come to me, all you who are weary and burdened, and I will give you rest.", "Matthew 11:28"),
        ("For God so loved the world that he gave his one and only Son.", "John 3:16")
    ]

    // Sélectionne le verset selon le jour de l'année
    private var todayVerse: (text: String, reference: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return verses[dayOfYear % verses.count]
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
                Text("VERSE OF THE DAY")
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
                            Text("share")
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
                    Text("continue")
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
