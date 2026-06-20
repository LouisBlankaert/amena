// Couleurs et thème global de l'app Amena
// Bleu doux principal (#4B8BF5), fond blanc/gris très clair, texte noir

import SwiftUI

extension Color {
    // Couleur principale bleu doux (boutons, accents, textes mis en valeur)
    static let amenaPrimary = Color(hex: "#4B8BF5")

    // Fond principal blanc
    static let amenaBackground = Color(hex: "#FFFFFF")

    // Fond secondaire gris très clair (pour les cartes, sections)
    static let amenaSecondaryBackground = Color(hex: "#F9F9F9")

    // Texte principal noir
    static let amenaText = Color(hex: "#111111")

    // Texte secondaire gris (sous-titres, hints)
    static let amenaTextSecondary = Color(hex: "#888888")

    // Bleu très pâle pour les dégradés de fond
    static let amenaOrangePale = Color(hex: "#EEF4FF")

    // Bleu ciel pour l'écran humeur
    static let amenaSkyBlue = Color(hex: "#00BFFF")

    // Bleu nuit pour le dégradé verset du jour
    static let amenaNightBlue = Color(hex: "#1a1a6e")

    // Bordure sélectionnée (cards abonnement, boutons)
    static let amenaSelectedBorder = Color(hex: "#4B8BF5")

    // Fond des options non sélectionnées
    static let amenaUnselectedBackground = Color(hex: "#F2F2F2")
}

// Extension pour initialiser une Color depuis un code hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Modificateurs de style réutilisables
extension View {
    // Bouton principal orange pleine largeur (utilisé partout dans l'onboarding)
    func amenaPrimaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.amenaPrimary)
            .cornerRadius(16)
            .padding(.horizontal, 24)
    }

    // Bouton secondaire (fond blanc, bordure ou texte coloré)
    func amenaSecondaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.amenaPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.amenaPrimary, lineWidth: 1.5)
            )
            .padding(.horizontal, 24)
    }
}

// Gradient de fond blanc → bleu très pâle (utilisé sur plusieurs écrans)
struct AmenaGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.amenaBackground, .amenaOrangePale],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
