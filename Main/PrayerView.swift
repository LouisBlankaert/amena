// Écran de prière : affiche une prière générée par Gemini
// Présenté en sheet depuis HomeView
// Même logique que FirstPrayerView mais accessible depuis l'accueil

import SwiftUI
import FirebaseAnalytics

struct PrayerView: View {
    let onPrayerCompleted: () -> Void

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
                        Text("let's pray")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.amenaText)
                        Text("read the prayer, then tap the button below")
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
                        .animation(.easeInOut(duration: 0.3), value: isPrayButtonEnabled)

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

    private func startTypewriter() {
        displayedText = ""
        animationTask = Task { @MainActor in
            for character in prayer {
                if Task.isCancelled { return }
                displayedText.append(character)
                try? await Task.sleep(nanoseconds: 30_000_000) // 30ms par lettre
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                isPrayButtonEnabled = true
            }
        }
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
