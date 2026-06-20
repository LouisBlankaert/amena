// Écran 11 : première prière dans l'onboarding
// Le texte apparaît lettre par lettre (effet machine à écrire)
// Le bouton s'active automatiquement quand la dernière lettre s'affiche

import SwiftUI
import FirebaseAnalytics

struct FirstPrayerView: View {
    @Binding var prayer: String
    let onNext: () -> Void

    @State private var isLoading = true
    @State private var isPrayButtonEnabled = false
    @State private var displayedText = ""
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("let's pray")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .padding(.top, 60)

                    Text("read the prayer, then tap the button below")
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
                                Text("Generating your prayer...")
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
                        Text("i've prayed today")
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
                                Text("share this prayer")
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
        Task {
            do {
                let generated = try await GeminiService.shared.generatePrayer()
                await MainActor.run {
                    prayer = generated
                    isLoading = false
                    startTypewriter()
                }
            } catch {
                print("⚠️ Gemini fallback: \(error)")
                await MainActor.run {
                    prayer = GeminiService.fallbackPrayer
                    isLoading = false
                    startTypewriter()
                }
            }
        }
    }

    // Effet machine à écrire : ajoute une lettre toutes les 30ms
    // Quand toutes les lettres sont affichées → active le bouton
    private func startTypewriter() {
        displayedText = ""
        animationTask = Task { @MainActor in
            for character in prayer {
                if Task.isCancelled { return }
                displayedText.append(character)
                // 30ms par caractère — ajuster ici pour accélérer/ralentir
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
            // Animation terminée → bouton actif
            withAnimation(.easeInOut(duration: 0.4)) {
                isPrayButtonEnabled = true
            }
        }
    }

}

#Preview {
    FirstPrayerView(prayer: .constant("Heavenly Father, thank you for this new day..."), onNext: {})
}
