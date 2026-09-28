// PrayerRequest : une intention de prière écrite par l'utilisateur ("Pour l'examen de Sarah").
// Les intentions en cours sont glissées dans la prière du jour (voir DailyPrayerTheme),
// et l'utilisateur les marque "exaucées" le jour venu : la liste des prières exaucées
// est ce qui donne envie de revenir — voir que prier compte.

import Foundation

struct PrayerRequest: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    let createdAt: Date
    var answeredAt: Date?

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.answeredAt = nil
    }

    var isAnswered: Bool { answeredAt != nil }

    // Nombre de jours pendant lesquels on a prié pour cette intention (au moins 1)
    var daysPrayed: Int {
        let end = answeredAt ?? Date()
        let days = Calendar.current.dateComponents([.day],
                                                   from: Calendar.current.startOfDay(for: createdAt),
                                                   to: Calendar.current.startOfDay(for: end)).day ?? 0
        return max(days + 1, 1)
    }
}

// Lecture / écriture dans UserDefaults (tout reste local, pas de compte)
enum PrayerRequestStore {
    private static let key = "prayerRequests"

    static func load() -> [PrayerRequest] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let requests = try? JSONDecoder().decode([PrayerRequest].self, from: data) else {
            return []
        }
        return requests
    }

    static func save(_ requests: [PrayerRequest]) {
        if let data = try? JSONEncoder().encode(requests) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static var active: [PrayerRequest] { load().filter { !$0.isAnswered } }
}
