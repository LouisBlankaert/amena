import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName")           private var userName = "Friend"
    @AppStorage("sheepName")          private var sheepName = "Nour"
    @AppStorage("isPremium")          private var isPremium = false
    @AppStorage("onboardingCompleted") private var onboardingCompleted = true

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
                    Section("profile") {
                        HStack {
                            Label("Your name", systemImage: "person.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            TextField("Name", text: $userName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        HStack {
                            Label("Companion's name", systemImage: "hare.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            TextField("Sheep name", text: $sheepName)
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
                                        Text("every day")
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
                            Label("Add prayer time", systemImage: "plus.circle.fill")
                                .foregroundColor(Color.amenaPrimary)
                        }
                    } header: {
                        Text("prayer times")
                    }

                    // ── NOTIFICATIONS ─────────────────────────────────
                    Section("notifications") {
                        HStack {
                            Label("Status", systemImage: "bell.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text(notifStatus)
                                .font(.system(size: 13))
                                .foregroundColor(notifStatus == "enabled" ? .green : Color.amenaTextSecondary)
                        }
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open notification settings", systemImage: "arrow.up.right.square")
                                .foregroundColor(Color.amenaPrimary)
                        }
                    }

                    // ── ABONNEMENT ────────────────────────────────────
                    Section("subscription") {
                        HStack {
                            Label("Status", systemImage: "crown.fill")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text(isPremium ? "Premium" : "Free")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isPremium ? Color.amenaPrimary : Color.amenaTextSecondary)
                        }

                        Button {
                            Task { await restorePurchases() }
                        } label: {
                            HStack {
                                Label(isRestoring ? "Restoring..." : "Restore purchases", systemImage: "arrow.clockwise")
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

                    // ── À PROPOS ──────────────────────────────────────
                    Section("about") {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        Link(destination: URL(string: "https://blankaertlouis.github.io/amena/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundColor(Color.amenaPrimary)
                        }
                        Link(destination: URL(string: "https://blankaertlouis.github.io/amena/terms.html")!) {
                            Label("Terms of Use", systemImage: "doc.text.fill")
                                .foregroundColor(Color.amenaPrimary)
                        }
                    }

                    // ── DANGER ────────────────────────────────────────
                    Section {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label("Reset onboarding", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.semibold)
                }
            }
            .alert("Reset onboarding?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    onboardingCompleted = false
                    dismiss()
                }
            } message: {
                Text("This will restart the app from the beginning. Your prayers won't be deleted.")
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
            restoreMessage = isPremium ? "Premium restored successfully." : "No active subscription found."
        } catch {
            restoreMessage = "Restore failed. Try again later."
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
