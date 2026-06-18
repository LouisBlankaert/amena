// Écran 8 : relation avec Dieu aujourd'hui
// Fond orange vif plein écran, texte blanc, slider avec emojis

import SwiftUI

struct RelationshipView: View {
    @Binding var value: Double   // 0.0 à 1.0
    let onNext: () -> Void

    // Retourne l'emoji selon la valeur du slider
    private var emoji: String {
        switch value {
        case 0.0..<0.33: return "😔"
        case 0.33..<0.66: return "😊"
        default: return "😇"
        }
    }

    // Label textuel sous le slider
    private var label: String {
        switch value {
        case 0.0..<0.25: return "poor"
        case 0.25..<0.50: return "okay"
        case 0.50..<0.75: return "good"
        default: return "amazing"
        }
    }

    var body: some View {
        ZStack {
            // Fond orange vif plein écran (différent des autres écrans)
            Color.amenaPrimary.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Titre en blanc
                Text("how's your relationship with God today?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Emoji grand au centre
                Text(emoji)
                    .font(.system(size: 80))
                    .animation(.spring(response: 0.3), value: emoji)

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
}

#Preview {
    RelationshipView(value: .constant(0.7), onNext: {})
}
