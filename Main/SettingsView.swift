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
    @State private var notifStatus:   String = "checking..."
    @State private var isRestoring    = false
    @State private var restoreMessage: String? = nil
    @State private var showResetAlert = false
    @State private var versionTapCount = 0
    @State private var showFounderUnlockAlert = false
    @State private var showFounderCodePrompt = false
    @State private var showFounderDisablePrompt = false
    @State private var founderCodeInput = ""
    @State private var founderCodeError = false
    @State private var intentions: Set<PrayerIntention> = []

    // Code secret connu de toi seul, rangé dans Secrets.swift (jamais commité) —
    // change-le là-bas si tu penses qu'il a fuité.
    private let founderSecretCode = Secrets.founderCode

    // Lit la vraie version depuis Info.plist plutôt que de la coder en dur
    // (source de vérité unique : MARKETING_VERSION dans project.yml)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    SkyMoment.current.colors.first!.frame(height: 260)
                    Color.amenaBackground
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // En-tête sous le ciel
                        HStack(alignment: .firstTextBaseline) {
                            Text(t("Settings", "Réglages"))
                                .font(.system(size: 34, weight: .regular, design: .serif))
                                .foregroundColor(.white)
                            Spacer()
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(t("Close", "Fermer"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 64)
                        .background(SkyBackground(moment: SkyMoment.current).ignoresSafeArea(edges: .top))

                        VStack(alignment: .leading, spacing: 32) {
                            // ── VOUS ─────────────────────────────────
                            SettingsSection(t("You", "Vous")) {
                                SettingsRow(t("First name", "Prénom")) {
                                    TextField(t("Name", "Prénom"), text: $userName)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Color.amenaTextSecondary)
                                }
                                Divider()
                                SettingsRow(t("Your sheep", "Votre mouton")) {
                                    TextField(t("Sheep name", "Nom du mouton"), text: $sheepName)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Color.amenaTextSecondary)
                                }
                                Divider()
                                SettingsRow(t("Language", "Langue")) {
                                    HStack(spacing: 0) {
                                        languageChip("FR", value: "French")
                                        languageChip("EN", value: "English")
                                    }
                                    .padding(3)
                                    .background(Color.amenaUnselectedBackground)
                                    .clipShape(Capsule())
                                }
                            }

                            // ── CE QUI PÈSE SUR LE CŒUR ──────────────
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsTitle(t("On your heart", "Sur votre cœur"))
                                Text(t("Your daily prayer speaks about what you choose here.",
                                       "Votre prière du jour parle de ce que vous choisissez ici."))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.amenaTextSecondary)
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                                    ForEach(PrayerIntention.allCases) { intention in
                                        let isOn = intentions.contains(intention)
                                        Button {
                                            if isOn { intentions.remove(intention) } else { intentions.insert(intention) }
                                            PrayerIntention.save(PrayerIntention.allCases.filter(intentions.contains))
                                        } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: intention.icon).font(.system(size: 13)).frame(width: 16)
                                                Text(intention.label).font(.system(size: 14, weight: .medium))
                                                    .multilineTextAlignment(.leading)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Spacer(minLength: 0)
                                            }
                                            .foregroundColor(isOn ? .white : Color.amenaText)
                                            .padding(.horizontal, 12)
                                            .frame(minHeight: 46)
                                            .background(isOn ? Color.amenaNightBlue : Color.amenaSecondaryBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        }
                                        .accessibilityAddTraits(isOn ? .isSelected : [])
                                    }
                                }
                            }

                            // ── RAPPELS ──────────────────────────────
                            SettingsSection(t("Reminders", "Rappels")) {
                                SettingsRow(t("Verse of the day", "Verset du jour")) {
                                    Text("10:00").foregroundColor(Color.amenaTextSecondary)
                                }
                                ForEach($prayerTimes) { $item in
                                    Divider()
                                    SettingsRow(item.name) {
                                        DatePicker("", selection: $item.time, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .onChange(of: item.time) { _ in
                                                item.name = PrayerTimeItem.name(for: item.time)
                                                savePrayerTimes()
                                            }
                                        Toggle("", isOn: $item.isEnabled)
                                            .labelsHidden()
                                            .tint(Color.amenaNightBlue)
                                            .onChange(of: item.isEnabled) { _ in savePrayerTimes() }
                                    }
                                }
                                Divider()
                                Button {
                                    let time = makeSettingsTime(hour: 8, minute: 0)
                                    prayerTimes.append(PrayerTimeItem(name: PrayerTimeItem.name(for: time), time: time, isEnabled: true))
                                    savePrayerTimes()
                                } label: {
                                    Label(t("Add a reminder", "Ajouter un rappel"), systemImage: "plus")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.amenaNightBlue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 14)
                                }
                                if notifStatus != "enabled" {
                                    Divider()
                                    Button {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(t("Notifications are off", "Les notifications sont coupées"))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(Color.amenaText)
                                            Text(t("Turn them on in the iPhone settings", "Activez-les dans les réglages de l'iPhone"))
                                                .font(.system(size: 13))
                                                .foregroundColor(Color.amenaNightBlue)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 12)
                                    }
                                }
                            }

                            // ── ABONNEMENT ───────────────────────────
                            SettingsSection(t("Subscription", "Abonnement")) {
                                SettingsRow(t("Status", "Statut")) {
                                    Text(isPremium ? "Premium" : t("Free", "Gratuit"))
                                        .foregroundColor(isPremium ? Color.amenaGold : Color.amenaTextSecondary)
                                        .fontWeight(.semibold)
                                }
                                Divider()
                                Button {
                                    Task { await restorePurchases() }
                                } label: {
                                    HStack {
                                        Text(isRestoring ? t("Restoring…", "Restauration…") : t("Restore purchases", "Restaurer les achats"))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color.amenaNightBlue)
                                        Spacer()
                                        if isRestoring { ProgressView() }
                                    }
                                    .padding(.vertical, 14)
                                }
                                .disabled(isRestoring)
                                if let msg = restoreMessage {
                                    Text(msg)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.amenaTextSecondary)
                                        .padding(.bottom, 12)
                                }
                            }

                            // ── À PROPOS ─────────────────────────────
                            SettingsSection(t("About", "À propos")) {
                                SettingsRow(t("Version", "Version")) {
                                    Text(appVersion).foregroundColor(Color.amenaTextSecondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    versionTapCount += 1
                                    if versionTapCount >= 7 {
                                        versionTapCount = 0
                                        if RevenueCatService.shared.hasFounderAccess {
                                            showFounderDisablePrompt = true
                                        } else {
                                            founderCodeInput = ""
                                            founderCodeError = false
                                            showFounderCodePrompt = true
                                        }
                                    }
                                }
                                Divider()
                                SettingsLink(t("Privacy policy", "Confidentialité"), url: "https://louisblankaert.github.io/amena/privacy.html")
                                Divider()
                                SettingsLink(t("Terms of use", "Conditions d'utilisation"), url: "https://louisblankaert.github.io/amena/terms.html")
                            }

                            Button(t("Restart the welcome screens", "Revoir les écrans d'accueil")) {
                                showResetAlert = true
                            }
                            .font(.system(size: 14))
                            .foregroundColor(Color.amenaTextSecondary)
                            .frame(maxWidth: .infinity)

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .background(Color.amenaBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .padding(.top, -32)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert(t("Reset onboarding?", "Réinitialiser l'accueil ?"), isPresented: $showResetAlert) {
                Button(t("Cancel", "Annuler"), role: .cancel) {}
                Button(t("Reset", "Réinitialiser"), role: .destructive) {
                    onboardingCompleted = false
                    dismiss()
                }
            } message: {
                Text(t("This will restart the app from the beginning. Your prayers won't be deleted.", "Ceci relancera l'app depuis le début. Vos prières ne seront pas supprimées."))
            }
            .alert(t("Disable founder access?", "Désactiver l'accès créateur ?"), isPresented: $showFounderDisablePrompt) {
                Button(t("Cancel", "Annuler"), role: .cancel) {}
                Button(t("Disable", "Désactiver"), role: .destructive) {
                    Task {
                        await RevenueCatService.shared.disableFounderAccess()
                        await MainActor.run { isPremium = RevenueCatService.shared.isPremium }
                    }
                }
            } message: {
                Text(t("You'll see the app like a regular user, paywall included. Re-enter the code to get it back.",
                       "Vous verrez l'app comme un utilisateur normal, paywall compris. Retapez le code pour le récupérer."))
            }
            .alert(t("Enter code", "Entrer le code"), isPresented: $showFounderCodePrompt) {
                TextField(t("Secret code", "Code secret"), text: $founderCodeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button(t("Cancel", "Annuler"), role: .cancel) {}
                Button(t("Unlock", "Débloquer")) {
                    if founderCodeInput == founderSecretCode {
                        RevenueCatService.shared.enableFounderAccess()
                        isPremium = true
                        showFounderUnlockAlert = true
                    } else {
                        founderCodeError = true
                    }
                }
            }
            .alert(t("Founder access enabled", "Accès créateur activé"), isPresented: $showFounderUnlockAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(t("Premium unlocked permanently on this device.", "Premium débloqué définitivement sur cet appareil."))
            }
            .alert(t("Wrong code", "Code incorrect"), isPresented: $founderCodeError) {
                Button("OK", role: .cancel) {}
            }
        }
        .onAppear {
            intentions = Set(PrayerIntention.saved)
            loadPrayerTimes()
            checkNotificationStatus()
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────

    private func languageChip(_ label: String, value: String) -> some View {
        Button {
            prayerLanguage = value
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(prayerLanguage == value ? .white : Color.amenaText)
                .frame(width: 40, height: 28)
                .background(prayerLanguage == value ? Color.amenaNightBlue : Color.clear)
                .clipShape(Capsule())
        }
        .accessibilityLabel(value == "French" ? "Français" : "English")
        .accessibilityAddTraits(prayerLanguage == value ? .isSelected : [])
    }

    private func loadPrayerTimes() {
        guard let data = UserDefaults.standard.data(forKey: "prayerTimes"),
              let times = try? JSONDecoder().decode([Date].self, from: data) else {
            let time = makeSettingsTime(hour: 20, minute: 0)
            prayerTimes = [PrayerTimeItem(name: PrayerTimeItem.name(for: time), time: time, isEnabled: true)]
            return
        }
        prayerTimes = times.map { date in
            PrayerTimeItem(name: PrayerTimeItem.name(for: date), time: date, isEnabled: true)
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
            try await RevenueCatService.shared.restorePurchases()
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

// Modèle d'une heure de rappel de prière (nom déduit de l'heure, traduit)
struct PrayerTimeItem: Identifiable {
    let id = UUID()
    var name: String
    var time: Date
    var isEnabled: Bool

    static func name(for time: Date) -> String {
        switch Calendar.current.component(.hour, from: time) {
        case 4..<12:  return t("Morning prayer", "Prière du matin")
        case 12..<18: return t("Afternoon prayer", "Prière de l'après-midi")
        default:      return t("Evening prayer", "Prière du soir")
        }
    }
}

// ── Éléments de mise en page des Réglages ─────────────────────────────

private struct SettingsTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .regular, design: .serif))
            .foregroundColor(Color.amenaText)
    }
}

// Un groupe de lignes sur fond gris clair, avec son titre serif
private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsTitle(title)
            VStack(spacing: 0) { content }
                .padding(.horizontal, 16)
                .background(Color.amenaSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let label: String
    @ViewBuilder let trailing: Trailing
    init(_ label: String, @ViewBuilder trailing: () -> Trailing) {
        self.label = label
        self.trailing = trailing()
    }
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color.amenaText)
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: 50)
    }
}

private struct SettingsLink: View {
    let label: String
    let url: String
    init(_ label: String, url: String) {
        self.label = label
        self.url = url
    }
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(label).font(.system(size: 16)).foregroundColor(Color.amenaText)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.amenaTextSecondary)
            }
            .frame(minHeight: 50)
        }
    }
}
