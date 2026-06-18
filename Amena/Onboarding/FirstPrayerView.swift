// Écran 11 : première prière dans l'onboarding
// Le texte de prière est généré par Gemini API
// Le bouton de confirmation devient orange après un délai (temps de lecture)

import SwiftUI

struct FirstPrayerView: View {
    @Binding var prayer: String
    let onNext: () -> Void

    // @State pour l'état local de cet écran
    @State private var isLoading = true           // Chargement en cours
    @State private var isPrayButtonEnabled = false // Bouton actif après délai
    @State private var timeRemaining = 30         // Secondes avant activation
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // En-tête
                VStack(spacing: 8) {
                    Text("let's pray")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .padding(.top, 60)

                    Text("tap 'i've prayed today 🙏' once the prayer is complete")
                        .font(.system(size: 14))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Texte de la prière ou indicateur de chargement
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
                            // Texte de la prière dans une carte
                            VStack(alignment: .leading, spacing: 16) {
                                Text(prayer)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color.amenaText)
                                    .lineSpacing(6)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(20)
                            .background(Color.amenaSecondaryBackground)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)

                            // Compteur si le bouton n'est pas encore actif
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

                // Boutons en bas
                VStack(spacing: 12) {
                    // Bouton principal (grisé puis orange)
                    Button {
                        onNext()
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

                    // Lien partage
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
        // onAppear est appelé quand l'écran devient visible
        .onAppear {
            loadPrayer()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // Charge la prière depuis Gemini API
    private func loadPrayer() {
        Task {
            // MainActor.run = met à jour l'UI sur le thread principal (obligatoire en SwiftUI)
            do {
                let generatedPrayer = try await GeminiService.shared.generatePrayer()
                await MainActor.run {
                    prayer = generatedPrayer
                    isLoading = false
                    startReadingTimer()
                }
            } catch {
                await MainActor.run {
                    prayer = GeminiService.fallbackPrayer
                    isLoading = false
                    startReadingTimer()
                }
            }
        }
    }

    // Démarre un countdown async qui active le bouton après X secondes
    private func startReadingTimer() {
        let wordCount = prayer.split(separator: " ").count
        timeRemaining = max(15, wordCount / 3)

        // Task @MainActor : la boucle s'exécute sur le thread principal (UI-safe)
        timerTask = Task { @MainActor in
            while timeRemaining > 0 {
                // try? pour ignorer l'annulation silencieusement
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 seconde
                if Task.isCancelled { return }
                timeRemaining -= 1
            }
            withAnimation {
                isPrayButtonEnabled = true
            }
        }
    }

    // Ouvre le partage natif iOS (UIActivityViewController)
    private func sharePrayer() {
        guard !prayer.isEmpty else { return }
        let activityVC = UIActivityViewController(
            activityItems: [prayer],
            applicationActivities: nil
        )
        // Récupère la scène active pour présenter le partage
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    FirstPrayerView(prayer: .constant("Heavenly Father, thank you for this new day..."), onNext: {})
}
