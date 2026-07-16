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

            // Supprime toutes les notifications existantes avant d'en planifier de nouvelles
            center.removeAllPendingNotificationRequests()

            // Charge les heures de prière depuis UserDefaults
            guard let data = UserDefaults.standard.data(forKey: "prayerTimes"),
                  let times = try? JSONDecoder().decode([Date].self, from: data) else {
                // Si pas d'horaires configurés, planifie une notification par défaut (matin)
                self.scheduleDefaultNotification()
                return
            }

            // Planifie une notification pour chaque heure configurée
            for (index, prayerTime) in times.enumerated() {
                self.scheduleDailyNotification(at: prayerTime, identifier: "prayer_\(index)")
            }
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
