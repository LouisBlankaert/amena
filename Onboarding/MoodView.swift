// Écran 9 : humeur du jour
// Fond bleu ciel vif, même structure que RelationshipView

import SwiftUI

struct MoodView: View {
    @Binding var value: Double
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var moodIcon: String {
        switch value {
        case 0.0..<0.33: return "cloud.drizzle.fill"
        case 0.33..<0.66: return "cloud.sun.fill"
        default: return "sun.max.fill"
        }
    }

    private var moodColor: Color {
        switch value {
        case 0.0..<0.33: return Color(hex: "#a8d8f0")
        case 0.33..<0.66: return Color(hex: "#FFE566")
        default: return Color(hex: "#FFD60A")
        }
    }

    private var label: String {
        switch value {
        case 0.0..<0.25: return t("not great", "pas terrible")
        case 0.25..<0.50: return t("okay", "ça va")
        case 0.50..<0.75: return t("good", "bien")
        default: return t("great!", "super !")
        }
    }

    var body: some View {
        ZStack {
            // Fond bleu ciel (#00BFFF)
            Color.amenaSkyBlue.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                Text(t("how are you feeling today?", "comment te sens-tu aujourd'hui ?"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: moodIcon)
                        .font(.system(size: 52))
                        .foregroundColor(moodColor)
                }
                .animation(.spring(response: 0.3), value: moodIcon)

                VStack(spacing: 12) {
                    Slider(value: $value, in: 0...1)
                        .tint(.white)
                        .padding(.horizontal, 32)

                    Text(label)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .animation(.easeInOut, value: label)
                }

                Spacer()

                // Bouton blanc avec texte bleu
                Button {
                    onNext()
                } label: {
                    Text(t("continue", "continuer"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.amenaSkyBlue)
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
    MoodView(value: .constant(0.8), onNext: {})
}
