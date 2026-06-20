// PrayerSession : modèle de données pour une session de prière
// Préparé pour SwiftData (étape 9), pour l'instant simple struct Codable

import Foundation
import SwiftUI

// @Model sera ajouté en étape 9 quand SwiftData sera configuré
// Pour l'instant, PrayerEntry dans JournalView fait le travail

// Thème d'une prière pour l'affichage
enum PrayerTheme: String, CaseIterable, Codable {
    case morning = "Morning Prayer"
    case evening = "Evening Prayer"
    case gratitude = "Gratitude"
    case guidance = "Seeking Guidance"
    case healing = "Healing & Strength"
    case peace = "Peace & Rest"

    // Emoji associé à chaque thème
    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .evening: return "🌙"
        case .gratitude: return "🙏"
        case .guidance: return "🕊️"
        case .healing: return "💚"
        case .peace: return "✨"
        }
    }

    // Couleur associée à chaque thème
    var color: Color {
        switch self {
        case .morning: return Color.amenaPrimary
        case .evening: return Color.amenaNightBlue
        case .gratitude: return .green
        case .guidance: return .blue
        case .healing: return .mint
        case .peace: return .purple
        }
    }
}
