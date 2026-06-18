// Écran 15 : demande de permission pour les notifications
// Montre un aperçu de notification mockup avant de demander la permission

import SwiftUI
import UserNotifications  // Framework Apple pour les notifications locales

struct NotificationsView: View {
    let onNext: () -> Void

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

                    Text("allow amena to send you notifications")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("we use this to allow you to unblock your apps when you need to pray")
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
                    Text("allow")
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 16)

                // Option pour passer sans autoriser
                Button("maybe later") {
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
            // Retour sur le thread principal pour mettre à jour UserDefaults
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                onNext()
            }
        }
    }
}

// Mockup d'une notification iOS
struct NotificationMockup: View {
    var body: some View {
        HStack(spacing: 12) {
            // Icône de l'app (placeholder)
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.amenaPrimary)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("🕊️")
                        .font(.system(size: 22))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("amena")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    Spacer()
                    Text("now")
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                }
                Text("your apps are blocked! time to pray 🙏")
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
