// Écran de prière : affiche une prière générée par Gemini
// Présenté en plein écran depuis HomeView, sous le ciel du moment (voir SkyMoment)
// Même logique que FirstPrayerView mais accessible depuis l'accueil

import SwiftUI
import FirebaseAnalytics

struct PrayerView: View {
    var prefetchedPrayer: String = ""
    // Faux pendant l'onboarding : la première prière ne se ferme pas, on la termine par « Amen »
    var showsCloseButton: Bool = true
    let onPrayerCompleted: () -> Void
    @AppStorage("prayerLanguage") private var prayerLanguage = "English"

    @State private var prayer = ""
    @State private var isLoading = true
    @State private var isPrayButtonEnabled = false
    @State private var displayedText = ""
    @State private var animationTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss  // Pour fermer l'écran
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Même ciel que l'accueil : on prie "sous" le ciel du moment
    private let moment = SkyMoment.current

    var body: some View {
        ZStack {
            SkyBackground(moment: moment).ignoresSafeArea()
            // Voile sombre pour que le long texte blanc reste lisible sur tous les ciels
            LinearGradient(
                colors: [.black.opacity(0.25), .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text(t("Let's pray", "Prions"))
                        .font(.system(size: 30, weight: .regular, design: .serif))
                        .foregroundColor(.white)
                    Spacer()
                    if showsCloseButton {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(t("Close", "Fermer"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ScrollView {
                    Group {
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.3)
                                Text(t("Your prayer is being written…", "Votre prière s'écrit…"))
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        } else {
                            Text(displayedText)
                                .font(.system(size: 19, design: .serif))
                                .foregroundColor(.white)
                                .lineSpacing(9)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                // Désactive l'animation SwiftUI sur le texte pour éviter le tremblement
                                .animation(nil, value: displayedText)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    // Un tap affiche toute la prière d'un coup (pour ceux qui lisent vite)
                    .contentShape(Rectangle())
                    .onTapGesture { skipTypewriter() }
                }

                VStack(spacing: 14) {
                    Button {
                        // Prière terminée → event "prayer_completed"
                        AnalyticsService.shared.log(.prayerCompleted)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        savePrayer()
                        onPrayerCompleted()
                        dismiss()
                    } label: {
                        Text("Amen")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundColor(isPrayButtonEnabled ? Color.amenaNightBlue : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(isPrayButtonEnabled ? Color.white : Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .disabled(!isPrayButtonEnabled)
                    .animation(.easeInOut(duration: 0.3), value: isPrayButtonEnabled)
                    .accessibilityHint(t("Marks today's prayer as done", "Marque la prière du jour comme faite"))

                    if isPrayButtonEnabled {
                        ShareLink(item: prayer) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text(t("Share this prayer", "Partager cette prière"))
                            }
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.85))
                        }
                    } else if !isLoading {
                        Text(t("Tap the text to show it all", "Touchez le texte pour tout afficher"))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)
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
        // Si une prière pré-générée est disponible, on l'utilise immédiatement
        if !prefetchedPrayer.isEmpty {
            prayer = prefetchedPrayer
            isLoading = false
            startTypewriter()
            return
        }
        Task {
            do {
                let generated = try await GeminiService.shared.generatePrayer(theme: DailyPrayerTheme.current, language: prayerLanguage)
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
        // Mouvement réduit (réglage d'accessibilité) : pas d'effet machine à écrire
        if reduceMotion {
            displayedText = prayer
            isPrayButtonEnabled = true
            return
        }
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
