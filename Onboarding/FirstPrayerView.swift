// Écran 11 : première prière dans l'onboarding
// Le texte apparaît lettre par lettre (effet machine à écrire)
// Le bouton s'active automatiquement quand la dernière lettre s'affiche

import SwiftUI
import FirebaseAnalytics

struct FirstPrayerView: View {
    @Binding var prayer: String
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    @State private var isLoading = true
    @State private var isPrayButtonEnabled = false
    @State private var displayedText = ""
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(t("let's pray", "prions"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .padding(.top, 60)

                    Text(t("read the prayer, then tap the button below", "lisez la prière, puis appuyez sur le bouton ci-dessous"))
                        .font(.system(size: 14))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                }

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
                        AnalyticsService.shared.log(.prayerCompleted)
                        savePrayerToJournal()
                        onNext()
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
                    .animation(.easeInOut(duration: 0.4), value: isPrayButtonEnabled)

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
        .onAppear {
            AnalyticsService.shared.log(.prayerStarted)
            loadPrayer()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private func savePrayerToJournal() {
        guard !prayer.isEmpty else { return }
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
    }

    private func loadPrayer() {
        // Si la prière a été pré-générée par OnboardingCoordinator, on l'affiche directement
        if !prayer.isEmpty {
            isLoading = false
            startTypewriter()
            return
        }
        // Sinon on la génère maintenant (cas rare si l'utilisateur va trop vite)
        Task {
            do {
                let generated = try await GeminiService.shared.generatePrayer(language: lang)
                await MainActor.run {
                    prayer = generated
                    isLoading = false
                    startTypewriter()
                }
            } catch {
                await MainActor.run {
                    prayer = GeminiService.fallbackPrayerForLanguage(lang)
                    isLoading = false
                    startTypewriter()
                }
            }
        }
    }

    // Effet machine à écrire : ajoute 3 lettres toutes les 20ms (≈ 15s pour 200 mots)
    private func startTypewriter() {
        displayedText = ""
        let chars = Array(prayer)
        animationTask = Task { @MainActor in
            var i = 0
            while i < chars.count {
                if Task.isCancelled { return }
                // 3 caractères par tick pour aller plus vite
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

    // Skip : affiche tout le texte immédiatement
    private func skipTypewriter() {
        animationTask?.cancel()
        displayedText = prayer
        withAnimation(.easeInOut(duration: 0.2)) {
            isPrayButtonEnabled = true
        }
    }

}

#Preview {
    FirstPrayerView(prayer: .constant("Heavenly Father, thank you for this new day..."), onNext: {})
}
