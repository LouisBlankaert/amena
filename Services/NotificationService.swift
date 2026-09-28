// NotificationService : planifie les notifications de rappel de prière
// Utilise UNUserNotificationCenter (framework Apple)

import UserNotifications
import Foundation

final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()
    private init() {}

    // Planifie les notifications pour chaque heure de prière configurée
    func schedulePrayerNotifications() {
        let center = UNUserNotificationCenter.current()

        // Vérifie d'abord que l'utilisateur a accordé la permission
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            // Supprime les notifications déjà planifiées avant d'en planifier de nouvelles,
            // SAUF le rappel de fin d'essai : il n'est planifié qu'une fois (au paywall),
            // l'effacer ici l'empêcherait de partir.
            center.getPendingNotificationRequests { requests in
                let idsToRemove = requests
                    .map(\.identifier)
                    .filter { $0 != "trial_ending" }
                center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
                self.scheduleAll()
            }
        }
    }

    private func scheduleAll() {
        // Verset du jour à 10h
        scheduleDailyVerseNotifications()

        // Charge les heures de prière depuis UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "prayerTimes"),
              let times = try? JSONDecoder().decode([Date].self, from: data) else {
            // Si pas d'horaires configurés, planifie une notification par défaut (matin)
            scheduleDefaultNotification()
            return
        }

        // Planifie une notification pour chaque heure configurée
        for (index, prayerTime) in times.enumerated() {
            scheduleDailyNotification(at: prayerTime, identifier: "prayer_\(index)")
        }
    }

    // Planifie une notification quotidienne à une heure précise
    private func scheduleDailyNotification(at time: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = t("Time to Pray", "C'est l'heure de prier")
        content.body = t("Take a moment to pray with Amena before opening your apps.", "Prenez un moment pour prier avec Amena avant d'ouvrir vos apps.")
        content.sound = .default
        content.badge = 1

        // Extrait heure et minute de la Date
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)

        // UNCalendarNotificationTrigger = se déclenche chaque jour à cette heure
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Verset du jour à 10h, un verset différent chaque jour.
    // Une notif "repeats: true" montrerait toujours le même texte, donc on planifie
    // chaque jour à l'avance. iOS limite à 64 notifs en attente : 30 jours laisse de
    // la place pour les rappels de prière, et la fenêtre est relancée à chaque ouverture
    // de l'app (HomeView → schedulePrayerNotifications).
    private func scheduleDailyVerseNotifications() {
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let fireDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day),
                  fireDate > now else { continue }

            let verse = DailyVerse.verse(for: day)
            let content = UNMutableNotificationContent()
            content.title = t("Verse of the day", "Verset du jour")
            content.subtitle = verse.reference
            content.body = verse.text
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "verse_\(dayOffset)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // Notification par défaut : 7h du matin
    private func scheduleDefaultNotification() {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let time = Calendar.current.date(from: components) ?? Date()
        scheduleDailyNotification(at: time, identifier: "prayer_default")
    }

    // Planifie une notification de rappel de fin d'essai (J+2)
    func scheduleTrialEndingReminder() {
        let content = UNMutableNotificationContent()
        content.title = t("Your free trial ends tomorrow 🔔", "Votre essai gratuit se termine demain 🔔")
        content.body = t("Don't forget — your Amena trial ends in 1 day. Keep praying daily!", "N'oubliez pas — votre essai Amena se termine dans 1 jour. Continuez à prier chaque jour !")
        content.sound = .default

        // Se déclenche dans exactement 2 jours (48h)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2 * 24 * 60 * 60,  // 2 jours en secondes
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "trial_ending",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Supprime toutes les notifications en attente
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
