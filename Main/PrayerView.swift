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
    @State private var timeRemaining = 30
    @State private var timerTask: Task<Void, Never>?

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
                        Text("tap 'i've prayed today 🙏' once the prayer is complete")
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
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(prayer)
                                        .font(.system(size: 17))
                                        .foregroundColor(Color.amenaText)
                                        .lineSpacing(6)
                                }
                                .padding(20)
                                .background(Color.amenaSecondaryBackground)
                                .cornerRadius(16)
                                .padding(.horizontal, 24)

                                if !isPrayButtonEnabled {
                                    Text("Button activates in \(timeRemaining)s...")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.amenaTextSecondary)
                                }
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
                            Text("i've prayed today 🙏")
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

                        Button {
                            sharePrayer()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("share this prayer")
                            }
                            .font(.system(size: 15))
                            .foregroundColor(Color.amenaPrimary)
                        }
                        .opacity(isLoading ? 0 : 1)
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
            timerTask?.cancel()
        }
    }

    private func loadPrayer() {
        Task {
            do {
                let generated = try await GeminiService.shared.generatePrayer()
                await MainActor.run {
                    prayer = generated
                    isLoading = false
                    startTimer()
                }
            } catch {
                await MainActor.run {
                    prayer = GeminiService.fallbackPrayer
                    isLoading = false
                    startTimer()
                }
            }
        }
    }

    private func startTimer() {
        let wordCount = prayer.split(separator: " ").count
        timeRemaining = max(15, wordCount / 3)
        timerTask = Task { @MainActor in
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                timeRemaining -= 1
            }
            withAnimation { isPrayButtonEnabled = true }
        }
    }

    // Sauvegarde la prière dans SwiftData via NotificationCenter
    private func savePrayer() {
        NotificationCenter.default.post(
            name: .prayerCompleted,
            object: nil,
            userInfo: ["prayerText": prayer, "date": Date()]
        )
    }

    private func sharePrayer() {
        guard !prayer.isEmpty else { return }
        let activityVC = UIActivityViewController(activityItems: [prayer], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// Notification custom pour communiquer entre PrayerView et JournalView
extension Notification.Name {
    static let prayerCompleted = Notification.Name("prayerCompleted")
}

#Preview {
    PrayerView(onPrayerCompleted: {})
}
