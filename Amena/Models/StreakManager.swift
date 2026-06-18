// StreakManager : gère le calcul du streak quotidien de prières
// Utilise UserDefaults pour stocker la dernière date de prière et le streak actuel

import Foundation

struct StreakManager {
    // Clés UserDefaults
    private let lastPrayedDateKey = "lastPrayedDate"
    private let currentStreakKey = "currentStreak"
    private let todayPrayedKey = "todayPrayed"

    // Vérifie si l'utilisateur a prié aujourd'hui
    var hasPrayedToday: Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: lastPrayedDateKey) as? Date else {
            return false
        }
        // Vérifie si lastDate est dans le même jour calendaire qu'aujourd'hui
        return Calendar.current.isDateInToday(lastDate)
    }

    // Renvoie le streak actuel
    var currentStreak: Int {
        // Si on n'a pas prié aujourd'hui, vérifie si on a prié hier
        // (le streak n'est cassé que si on a raté plus d'un jour)
        let streak = UserDefaults.standard.integer(forKey: currentStreakKey)
        if let lastDate = UserDefaults.standard.object(forKey: lastPrayedDateKey) as? Date {
            let daysSinceLastPrayer = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            // Si plus de 1 jour sans prier → streak cassé
            if daysSinceLastPrayer > 1 && !Calendar.current.isDateInToday(lastDate) {
                return 0
            }
        }
        return streak
    }

    // Marque aujourd'hui comme jour de prière et retourne le nouveau streak
    @discardableResult
    mutating func markPrayedToday() -> Int {
        let today = Date()
        let defaults = UserDefaults.standard

        // Évite de compter deux fois si déjà prié aujourd'hui
        if hasPrayedToday {
            return currentStreak
        }

        var newStreak: Int
        if let lastDate = defaults.object(forKey: lastPrayedDateKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if daysSince == 1 {
                // Hier → streak continue
                newStreak = currentStreak + 1
            } else {
                // Raté des jours → on recommence à 1
                newStreak = 1
            }
        } else {
            // Première prière de l'app
            newStreak = 1
        }

        defaults.set(today, forKey: lastPrayedDateKey)
        defaults.set(newStreak, forKey: currentStreakKey)
        defaults.set(true, forKey: todayPrayedKey)

        return newStreak
    }
}
