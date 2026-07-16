// Écran 8 : relation avec Dieu aujourd'hui
// Fond orange vif plein écran, texte blanc, slider avec emojis

import SwiftUI

struct RelationshipView: View {
    @Binding var value: Double
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var moodIcon: String {
        switch value {
        case 0.0..<0.33: return "cloud.rain.fill"
        case 0.33..<0.66: return "sun.max.fill"
        default: return "sparkles"
        }
    }

    private var moodColor: Color {
        switch value {
        case 0.0..<0.33: return Color(hex: "#7EB8F7")
        case 0.33..<0.66: return Color(hex: "#FFD60A")
        default: return Color(hex: "#FFE566")
        }
    }

    private var label: String {
        switch value {
        case 0.0..<0.25: return t("poor", "mauvaise")
        case 0.25..<0.50: return t("okay", "correcte")
        case 0.50..<0.75: return t("good", "bonne")
        default: return t("amazing", "excellente")
        }
    }

    var body: some View {
        ZStack {
            // Fond orange vif plein écran (différent des autres écrans)
            Color.amenaPrimary.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Titre en blanc
                Text(t("how's your relationship with God today?", "comment est votre relation avec Dieu aujourd'hui ?"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Icône humeur au centre
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: moodIcon)
                        .font(.system(size: 52))
                        .foregroundColor(moodColor)
                }
                .animation(.spring(response: 0.3), value: moodIcon)

                // Slider + label
                VStack(spacing: 12) {
                    // Slider avec couleur blanche (sur fond orange)
                    Slider(value: $value, in: 0...1)
                        .tint(.white)
                        .padding(.horizontal, 32)

                    Text(label)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .animation(.easeInOut, value: label)
                }

                Spacer()

                // Bouton blanc avec texte orange (inverse des autres écrans)
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
}

#Preview {
    RelationshipView(value: .constant(0.7), onNext: {})
}
