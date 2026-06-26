import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName")           private var userName = "Friend"
    @AppStorage("sheepName")          private var sheepName = "Nour"
    @AppStorage("isPremium")          private var isPremium = false
    @AppStorage("onboardingCompleted") private var onboardingCompleted = true
    @AppStorage("prayerLanguage")      private var prayerLanguage = "English"

    @State private var prayerTimes:   [PrayerTimeItem] = []
    @State private var editingIndex:  Int? = nil
    @State private var notifStatus:   String = "checking..."
    @State private var isRestoring    = false
    @State private var restoreMessage: String? = nil
    @State private var showResetAlert = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                List {

                    // ── PROFIL ───────────────────────────────────────
                    Section(t("prayers language", "langue des prières")) {
                        HStack {
                            Label(t("Prayer language", "Langue de prière"), systemImage: "globe")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Picker("", selection: $prayerLanguage) {
                                Text("English").tag("English")
                                Text("Français").tag("French")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                    }

                    Section(t("profile", "profil")) {
                        HStack {
                            Label(t("Your name", "Votre prénom"), systemImage: "person.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            TextField(t("Name", "Prénom"), text: $userName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        HStack {
                            Label(t("Companion's name", "Nom du compagnon"), systemImage: "hare.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            TextField(t("Sheep name", "Nom du mouton"), text: $sheepName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                    }

                    // ── HEURES DE PRIÈRE ──────────────────────────────
                    Section {
                        ForEach(Array(prayerTimes.enumerated()), id: \.element.id) { index, _ in
                            VStack(spacing: 0) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(prayerTimes[index].name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color.amenaText)
                                        Text(t("every day", "chaque jour"))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.amenaTextSecondary)
                                    }
                                    Spacer()
                                    Text(timeFormatter.string(from: prayerTimes[index].time))
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(prayerTimes[index].isEnabled ? Color.amenaPrimary : Color.amenaTextSecondary)
                                    Toggle("", isOn: $prayerTimes[index].isEnabled)
                                        .tint(Color.amenaPrimary)
                                        .labelsHidden()
                                        .onChange(of: prayerTimes[index].isEnabled) { _ in savePrayerTimes() }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation { editingIndex = editingIndex == index ? nil : index }
                                }

                                if editingIndex == index {
                                    DatePicker("", selection: $prayerTimes[index].time, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .onChange(of: prayerTimes[index].time) { _ in savePrayerTimes() }
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                        }
                        .onDelete { indexSet in
                            prayerTimes.remove(atOffsets: indexSet)
                            savePrayerTimes()
                        }

                        Button {
                            prayerTimes.append(PrayerTimeItem(
                                name: "Prayer \(prayerTimes.count + 1)",
                                time: makeSettingsTime(hour: 8, minute: 0),
                                isEnabled: true
                            ))
                            savePrayerTimes()
                        } label: {
                            Label(t("Add prayer time", "Ajouter une heure de prière"), systemImage: "plus.circle.fill")
                                .foregroundColor(Color.amenaPrimary)
                        }
                    } header: {
                        Text(t("prayer times", "heures de prière"))
                    }

                    Section(t("notifications", "notifications")) {
                        HStack {
                            Label(t("Status", "Statut"), systemImage: "bell.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text(notifStatus == "enabled" ? t("enabled", "activé") : notifStatus == "disabled" ? t("disabled", "désactivé") : t("not set", "non défini"))
                                .font(.system(size: 13))
                                .foregroundColor(notifStatus == "enabled" ? .green : Color.amenaTextSecondary)
                        }
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label(t("Open notification settings", "Ouvrir les paramètres"), systemImage: "arrow.up.right.square")
                                .foregroundColor(Color.amenaPrimary)
                        }
                    }

                    Section(t("subscription", "abonnement")) {
                        HStack {
                            Label(t("Status", "Statut"), systemImage: "crown.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text(isPremium ? t("Premium", "Premium") : t("Free", "Gratuit"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isPremium ? Color.amenaPrimary : Color.amenaTextSecondary)
                        }

                        Button {
                            Task { await restorePurchases() }
                        } label: {
                            HStack {
                                Label(isRestoring ? t("Restoring...", "Restauration...") : t("Restore purchases", "Restaurer les achats"), systemImage: "arrow.clockwise")
                                    .foregroundColor(Color.amenaPrimary)
                                if isRestoring { Spacer(); ProgressView().tint(Color.amenaPrimary) }
                            }
                        }
                        .disabled(isRestoring)

                        if let msg = restoreMessage {
                            Text(msg)
                                .font(.system(size: 13))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                    }

                    Section(t("about", "à propos")) {
                        HStack {
                            Label(t("Version", "Version"), systemImage: "info.circle")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        Link(destination: URL(string: "https://louisblankaert.github.io/amena/privacy.html")!) {
                            Label(t("Privacy Policy", "Politique de confidentialité"), systemImage: "hand.raised.fill")
                                .foregroundColor(Color.amenaPrimary)
                        }
                        Link(destination: URL(string: "https://louisblankaert.github.io/amena/terms.html")!) {
                            Label(t("Terms of Use", "Conditions d'utilisation"), systemImage: "doc.text.fill")
                                .foregroundColor(Color.amenaPrimary)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label(t("Reset onboarding", "Réinitialiser l'accueil"), systemImage: "arrow.counterclockwise")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(t("settings", "paramètres"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t("Done", "Fermer")) { dismiss() }
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.semibold)
                }
            }
            .alert(t("Reset onboarding?", "Réinitialiser l'accueil ?"), isPresented: $showResetAlert) {
                Button(t("Cancel", "Annuler"), role: .cancel) {}
                Button(t("Reset", "Réinitialiser"), role: .destructive) {
                    onboardingCompleted = false
                    dismiss()
                }
            } message: {
                Text(t("This will restart the app from the beginning. Your prayers won't be deleted.", "Ceci relancera l'app depuis le début. Vos prières ne seront pas supprimées."))
            }
        }
        .onAppear {
            loadPrayerTimes()
            checkNotificationStatus()
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────

    private func loadPrayerTimes() {
        guard let data = UserDefaults.standard.data(forKey: "prayerTimes"),
              let times = try? JSONDecoder().decode([Date].self, from: data) else {
            prayerTimes = [
                PrayerTimeItem(name: "Morning Prayer",   time: makeSettingsTime(hour: 7,  minute: 0), isEnabled: true),
                PrayerTimeItem(name: "Afternoon Prayer", time: makeSettingsTime(hour: 12, minute: 0), isEnabled: true),
                PrayerTimeItem(name: "Evening Prayer",   time: makeSettingsTime(hour: 21, minute: 0), isEnabled: true)
            ]
            return
        }
        let names = ["Morning Prayer", "Afternoon Prayer", "Evening Prayer"]
        prayerTimes = times.enumerated().map { i, date in
            PrayerTimeItem(name: names[safe: i] ?? "Prayer \(i + 1)", time: date, isEnabled: true)
        }
    }

    private func savePrayerTimes() {
        let enabled = prayerTimes.filter(\.isEnabled).map(\.time)
        if let data = try? JSONEncoder().encode(enabled) {
            UserDefaults.standard.set(data, forKey: "prayerTimes")
        }
        NotificationService.shared.schedulePrayerNotifications()
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { @Sendable settings in
            let status: String
            switch settings.authorizationStatus {
            case .authorized, .provisional: status = "enabled"
            case .denied:                   status = "disabled"
            default:                        status = "not set"
            }
            DispatchQueue.main.async { notifStatus = status }
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        restoreMessage = nil
        do {
            try await StoreKitService.shared.restorePurchases()
            restoreMessage = isPremium ? t("Premium restored successfully.", "Abonnement restauré avec succès.") : t("No active subscription found.", "Aucun abonnement actif trouvé.")
        } catch {
            restoreMessage = t("Restore failed. Try again later.", "Échec de la restauration. Réessayez plus tard.")
        }
        isRestoring = false
    }
}

private func makeSettingsTime(hour: Int, minute: Int) -> Date {
    var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    c.hour = hour; c.minute = minute
    return Calendar.current.date(from: c) ?? Date()
}

// Safe subscript pour éviter les out-of-bounds
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
