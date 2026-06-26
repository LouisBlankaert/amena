// Écran de prière : affiche une prière générée par Gemini
// Présenté en sheet depuis HomeView
// Même logique que FirstPrayerView mais accessible depuis l'accueil

import SwiftUI
import FirebaseAnalytics

struct PrayerView: View {
    var prefetchedPrayer: String = ""
    let onPrayerCompleted: () -> Void
    @AppStorage("prayerLanguage") private var prayerLanguage = "English"

    @State private var prayer = ""
    @State private var isLoading = true
    @State private var isPrayButtonEnabled = false
    @State private var displayedText = ""
    @State private var animationTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss  // Pour fermer la sheet

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // En-tête dans la NavigationStack
                    VStack(spacing: 8) {
                        Text(t("let's pray", "prions"))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.amenaText)
                        Text(t("read the prayer, then tap the button below", "lisez la prière, puis appuyez sur le bouton ci-dessous"))
                            .font(.system(size: 14))
                            .foregroundColor(Color.amenaTextSecondary)
                            .multilineTextAlignment(.center)

                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                    ScrollView {
                        VStack(spacing: 24) {
                            if isLoading {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .tint(Color.amenaPrimary)
                                        .scaleEffect(1.5)
                                    Text(t("Generating your prayer...", "Génération de votre prière..."))
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.amenaTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                VStack(alignment: .leading, spacing: 0) {
                                    (Text(displayedText)
                                        .foregroundColor(Color.amenaText)
                                     + Text(isPrayButtonEnabled ? "" : "▌")
                                        .foregroundColor(Color.amenaPrimary))
                                    .font(.system(size: 18, design: .serif))
                                    .lineSpacing(10)
                                    .multilineTextAlignment(.leading)
                                    // Désactive l'animation SwiftUI sur le texte pour éviter le tremblement
                                    .animation(nil, value: displayedText)
                                }
                                .padding(.horizontal, 28)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 120)
                    }

                    VStack(spacing: 12) {
                        Button {
                            // Prière terminée → event "prayer_completed"
                            AnalyticsService.shared.log(.prayerCompleted)
                            savePrayer()
                            onPrayerCompleted()
                            dismiss()
                        } label: {
                            Text(t("i've prayed today", "j'ai prié aujourd'hui"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isPrayButtonEnabled ? Color.amenaPrimary : Color.amenaTextSecondary.opacity(0.4))
                                .cornerRadius(16)
                                .padding(.horizontal, 24)
                        }
                        .disabled(!isPrayButtonEnabled)
                        .animation(.easeInOut(duration: 0.3), value: isPrayButtonEnabled)

                        if isPrayButtonEnabled {
                            ShareLink(item: prayer) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(t("share this prayer", "partager cette prière"))
                                }
                                .font(.system(size: 15))
                                .foregroundColor(Color.amenaPrimary)
                            }
                        }
                    }
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.amenaTextSecondary)
                    }
                }
            }
        }
        .onAppear {
            // Écran de prière ouvert → event "prayer_started"
            AnalyticsService.shared.log(.prayerStarted)
            loadPrayer()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private var prayerTheme: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let themes: [String]
        if hour < 12 {
            themes = ["gratitude for a new day", "seeking God's guidance at the start of the day", "morning surrender and trust in God"]
        } else if hour < 18 {
            themes = ["strength and focus in the middle of the day", "peace amid daily pressures", "renewing faith in the afternoon"]
        } else {
            themes = ["reflection and gratitude at the end of the day", "rest and trust in God's hands tonight", "evening thankfulness and releasing the day to God"]
        }
        return themes.randomElement()!
    }

    private func loadPrayer() {
        // Si une prière pré-générée est disponible, on l'utilise immédiatement
        if !prefetchedPrayer.isEmpty {
            prayer = prefetchedPrayer
            isLoading = false
            startTypewriter()
            return
        }
        Task {
            do {
                let generated = try await GeminiService.shared.generatePrayer(theme: prayerTheme, language: prayerLanguage)
                await MainActor.run {
                    prayer = generated
                    isLoading = false
                    startTypewriter()
                }
            } catch {
                await MainActor.run {
                    prayer = GeminiService.fallbackPrayerForLanguage(prayerLanguage)
                    isLoading = false
                    startTypewriter()
                }
            }
        }
    }

    private func startTypewriter() {
        displayedText = ""
        let chars = Array(prayer)
        animationTask = Task { @MainActor in
            var i = 0
            while i < chars.count {
                if Task.isCancelled { return }
                let end = min(i + 3, chars.count)
                displayedText = String(chars[0..<end])
                i = end
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                isPrayButtonEnabled = true
            }
        }
    }

    private func skipTypewriter() {
        guard !isLoading else { return }  // ne rien faire si la prière n'est pas encore chargée
        animationTask?.cancel()
        displayedText = prayer
        withAnimation(.easeInOut(duration: 0.2)) { isPrayButtonEnabled = true }
    }

    // Sauvegarde directement dans UserDefaults (plus fiable que NotificationCenter seul)
    private func savePrayer() {
        var entries: [PrayerEntry] = []
        if let data = UserDefaults.standard.data(forKey: "prayerJournal"),
           let decoded = try? JSONDecoder().decode([PrayerEntry].self, from: data) {
            entries = decoded
        }
        let entry = PrayerEntry(id: UUID(), text: prayer, date: Date())
        entries.insert(entry, at: 0)
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "prayerJournal")
        }
        // Notification pour mise à jour en temps réel si JournalView est visible
        NotificationCenter.default.post(
            name: .prayerCompleted,
            object: nil,
            userInfo: ["prayerText": prayer, "date": Date()]
        )
    }

}

// Notification custom pour communiquer entre PrayerView et JournalView
extension Notification.Name {
    static let prayerCompleted = Notification.Name("prayerCompleted")
}

#Preview {
    PrayerView(onPrayerCompleted: {})
}
