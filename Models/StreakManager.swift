// StreakManager : streak quotidien + grille 30 jours + système de niveaux de Nour
import Foundation

struct StreakManager {
    private let lastPrayedDateKey    = "lastPrayedDate"
    private let currentStreakKey     = "currentStreak"
    private let journeyStartKey      = "journeyStartDate"
    private let prayedDaysKey        = "prayedDays"
    private let graceDayUsedAtKey    = "graceDayUsedAt"
    static  let totalPrayersKey      = "totalPrayers"
    static  let completedCyclesKey   = "completedCycles"
    static  let cycleCompletedTodayKey = "cycleCompletedToday"

    // ─── Seuils cumulatifs de prières pour chaque niveau ──────────────────
    // Index 0 = Lv1, index 1 = Lv2, etc.
    // Plus on monte, plus il faut de prières (exponentiel)
    static let levelThresholds = [0, 3, 7, 13, 22, 35, 53, 78, 112, 160]
    //  Lv1→2 : 3 prières   (facile pour accrocher)
    //  Lv2→3 : 4 prières
    //  Lv3→4 : 6 prières
    //  Lv4→5 : 9 prières
    //  Lv5→6 : 13 prières
    //  Lv6→7 : 18 prières
    //  Lv7→8 : 25 prières
    //  Lv8→9 : 34 prières
    //  Lv9→10: 48 prières  (dur à atteindre)

    // Calcule niveau + % FAITH à partir du total de prières accumulées
    static func computeLevel(totalPrayers: Int) -> (level: Int, faithPercent: Double) {
        var level = 1
        for i in (0..<levelThresholds.count).reversed() {
            if totalPrayers >= levelThresholds[i] {
                level = i + 1
                break
            }
        }
        level = min(level, 10)
        guard level < 10 else { return (10, 1.0) }

        let lo  = levelThresholds[level - 1]
        let hi  = levelThresholds[level]
        let pct = Double(totalPrayers - lo) / Double(hi - lo)
        return (level, max(0, min(1, pct)))
    }

    // ─── Streak ────────────────────────────────────────────────────────────

    var hasPrayedToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastPrayedDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    var currentStreak: Int {
        let saved = UserDefaults.standard.integer(forKey: currentStreakKey)
        guard let last = UserDefaults.standard.object(forKey: lastPrayedDateKey) as? Date else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        // 1 jour d'écart max, ou 2 jours si le jour de grâce est encore disponible : le streak tient.
        if days <= 1 { return saved }
        if days == 2 && isGraceDayAvailable { return saved }
        return 0
    }

    // Le jour de grâce se "recharge" 7 jours après avoir été utilisé la dernière fois.
    private var isGraceDayAvailable: Bool {
        guard let usedAt = UserDefaults.standard.object(forKey: graceDayUsedAtKey) as? Date else { return true }
        let days = Calendar.current.dateComponents([.day], from: usedAt, to: Date()).day ?? 0
        return days >= 7
    }

    // ─── Action principale : prier aujourd'hui ─────────────────────────────

    // Retourne le nouveau streak, et si l'utilisateur revient après une vraie rupture
    // (pour afficher un message d'accueil bienveillant plutôt qu'une simple continuité).
    @discardableResult
    mutating func markPrayedToday() -> (streak: Int, isReturningAfterBreak: Bool) {
        guard !hasPrayedToday else { return (currentStreak, false) }

        let today    = Date()
        let defaults = UserDefaults.standard
        let previousStreak = defaults.integer(forKey: currentStreakKey)
        let hadPreviousPrayer = defaults.object(forKey: lastPrayedDateKey) != nil

        // Streak
        var newStreak: Int
        var isReturningAfterBreak = false
        if let last = defaults.object(forKey: lastPrayedDateKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
            if days == 1 {
                newStreak = previousStreak + 1
            } else if days == 2 && isGraceDayAvailable {
                // Un jour manqué, mais le jour de grâce protège le streak.
                newStreak = previousStreak + 1
                defaults.set(today, forKey: graceDayUsedAtKey)
            } else {
                newStreak = 1
                isReturningAfterBreak = hadPreviousPrayer && previousStreak > 0
            }
        } else {
            newStreak = 1
        }
        defaults.set(today,     forKey: lastPrayedDateKey)
        defaults.set(newStreak, forKey: currentStreakKey)

        // Grille 30 jours
        let startDate: Date
        if let saved = defaults.object(forKey: journeyStartKey) as? Date {
            startDate = saved
        } else {
            startDate = today
            defaults.set(startDate, forKey: journeyStartKey)
        }
        let dayOffset = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        var prayedDays = loadPrayedDays()
        prayedDays.insert(min(dayOffset, 29)) // max jour 29 (index 0-29)
        savePrayedDays(prayedDays)

        // Détection cycle complet (30 jours)
        if prayedDays.count >= 30 {
            let cycles = defaults.integer(forKey: StreakManager.completedCyclesKey) + 1
            defaults.set(cycles, forKey: StreakManager.completedCyclesKey)
            defaults.set(true, forKey: StreakManager.cycleCompletedTodayKey)
            // Reset grille + nouveau départ
            savePrayedDays([])
            defaults.set(today, forKey: journeyStartKey)
        } else {
            defaults.set(false, forKey: StreakManager.cycleCompletedTodayKey)
        }

        // Total de prières cumulatif (utilisé pour les niveaux de Nour)
        let total = defaults.integer(forKey: StreakManager.totalPrayersKey) + 1
        defaults.set(total, forKey: StreakManager.totalPrayersKey)

        return (newStreak, isReturningAfterBreak)
    }

    // Nombre de cycles complétés
    var completedCycles: Int {
        UserDefaults.standard.integer(forKey: StreakManager.completedCyclesKey)
    }

    // ─── Helpers grille ────────────────────────────────────────────────────

    func loadPrayedDays() -> Set<Int> {
        guard let data = UserDefaults.standard.data(forKey: prayedDaysKey),
              let set  = try? JSONDecoder().decode(Set<Int>.self, from: data) else { return [] }
        return set
    }

    private func savePrayedDays(_ set: Set<Int>) {
        if let data = try? JSONEncoder().encode(set) {
            UserDefaults.standard.set(data, forKey: prayedDaysKey)
        }
    }

    var prayedDaysCount: Int { loadPrayedDays().count }
}
