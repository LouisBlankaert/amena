// Écran 15 : demande de permission pour les notifications
// Montre un aperçu de notification mockup avant de demander la permission

import SwiftUI
import UserNotifications  // Framework Apple pour les notifications locales

struct NotificationsView: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // En-tête
                VStack(spacing: 12) {
                    // Icône notification
                    ZStack {
                        Circle()
                            .fill(Color.amenaOrangePale)
                            .frame(width: 80, height: 80)
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.amenaPrimary)
                    }

                    Text(t("allow amena to send you notifications", "autoriser amena à vous envoyer des notifications"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(t("we use this to remind you to pray at your chosen times each day", "nous utilisons ceci pour vous rappeler de prier à vos horaires choisis chaque jour"))
                        .font(.system(size: 15))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Aperçu d'une notification (mockup)
                NotificationMockup()
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                Spacer()

                // Bouton "allow" → déclenche la vraie demande de permission iOS
                Button {
                    requestNotificationPermission()
                } label: {
                    Text(t("allow", "autoriser"))
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 16)

                // Option pour passer sans autoriser
                Button(t("maybe later", "peut-être plus tard")) {
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                    onNext()
                }
                .font(.system(size: 15))
                .foregroundColor(Color.amenaTextSecondary)
                .padding(.bottom, 48)
            }
        }
    }

    // Demande la permission iOS pour les notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                if granted {
                    NotificationService.shared.schedulePrayerNotifications()
                }
                onNext()
            }
        }
    }
}

// Mockup d'une notification iOS
struct NotificationMockup: View {
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        HStack(spacing: 12) {
            // Icône de l'app
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.amenaPrimary)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("amena")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    Spacer()
                    Text(t("now", "maintenant"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                }
                Text(t("time to pray! open amena for your daily prayer", "il est temps de prier ! ouvrez amena pour votre prière"))
                    .font(.system(size: 13))
                    .foregroundColor(Color.amenaText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
        // Légère ombre pour donner l'effet d'une vraie notification
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    NotificationsView(onNext: {})
}
