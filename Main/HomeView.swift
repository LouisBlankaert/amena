// Écran principal après l'onboarding
// Affiche le statut de prière du jour, le streak, et la mascotte mouton

import SwiftUI
import AVKit

struct HomeView: View {
    // Lecture des données stockées dans UserDefaults
    @AppStorage("userName") private var userName = "Friend"
    @AppStorage("sheepName") private var sheepName = "Nour"
    @AppStorage("onboardingCompleted") private var onboardingCompleted = true

    @State private var hasPrayedToday = false
    @State private var showPrayerView = false
    @State private var currentStreak  = 0
    // totalPrayers est la source unique de vérité pour le niveau de Nour
    @AppStorage("totalPrayers") private var totalPrayers: Int = 0

    @State private var streakManager = StreakManager()
    @State private var showSettings  = false
    @AppStorage("completedCycles") private var completedCycles: Int = 0
    @AppStorage("prayerLanguage")  private var prayerLanguage = "English"
    @State private var showCycleBanner = false
    @State private var prefetchedPrayer = ""  // pré-généré en arrière-plan
    @State private var prayers: [PrayerEntry] = []

    // Niveau et % FAITH calculés dynamiquement depuis totalPrayers
    private var levelData: (level: Int, faithPercent: Double) {
        StreakManager.computeLevel(totalPrayers: totalPrayers)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // En-tête : bonjour + nom
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t("good \(timeOfDay), \(userName)", "\(greetingFr), \(userName)"))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.amenaText)
                                Text(hasPrayedToday ? t("You've prayed today ✓", "Vous avez prié aujourd'hui ✓") : t("Don't forget to pray today", "N'oubliez pas de prier aujourd'hui"))
                                    .font(.system(size: 14))
                                    .foregroundColor(hasPrayedToday ? Color.amenaPrimary : Color.amenaTextSecondary)
                            }
                            Spacer()
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.amenaTextSecondary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // Carte principale : statut prière
                        PrayerStatusCard(
                            hasPrayed: hasPrayedToday,
                            streak: currentStreak,
                            onPrayNow: { showPrayerView = true }
                        )
                        .padding(.horizontal, 24)

                        // Bannière cycle complet (30 jours)
                        if showCycleBanner {
                            CycleCompletedBanner(
                                cycleNumber: completedCycles,
                                onDismiss: { showCycleBanner = false }
                            )
                            .padding(.horizontal, 24)
                        }

                        // Carte mascotte mouton
                        SheepStatusCard(
                            sheepName: sheepName,
                            level: levelData.level,
                            faithPercent: levelData.faithPercent
                        )
                        .padding(.horizontal, 24)

                        // Historique de prière façon GitHub
                        PrayerContributionGrid(prayers: prayers)
                            .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showPrayerView) {
                PrayerView(prefetchedPrayer: prefetchedPrayer) {
                    currentStreak  = streakManager.markPrayedToday()
                    hasPrayedToday = true
                    totalPrayers   = UserDefaults.standard.integer(forKey: StreakManager.totalPrayersKey)
                    if UserDefaults.standard.bool(forKey: StreakManager.cycleCompletedTodayKey) {
                        showCycleBanner = true
                    }
                    loadPrayers()
                    // Pré-génère la prochaine prière immédiatement après
                    prefetchedPrayer = ""
                    prefetchNextPrayer()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            loadState()
        }
    }

    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    private var greetingFr: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "bonjour"
        case 12..<17: return "bon après-midi"
        default: return "bonsoir"
        }
    }

    private func loadState() {
        hasPrayedToday = streakManager.hasPrayedToday
        currentStreak  = streakManager.currentStreak

        if totalPrayers == 0 && currentStreak > 0 {
            totalPrayers = currentStreak
            UserDefaults.standard.set(currentStreak, forKey: StreakManager.totalPrayersKey)
        }

        NotificationService.shared.schedulePrayerNotifications()
        prefetchNextPrayer()
        loadPrayers()
    }

    private func loadPrayers() {
        if let data = UserDefaults.standard.data(forKey: "prayerJournal"),
           let decoded = try? JSONDecoder().decode([PrayerEntry].self, from: data) {
            prayers = decoded
        }
    }

    private func prefetchNextPrayer() {
        guard prefetchedPrayer.isEmpty else { return }
        Task {
            let theme = dailyPrayerTheme()
            if let generated = try? await GeminiService.shared.generatePrayer(theme: theme, language: prayerLanguage) {
                await MainActor.run { prefetchedPrayer = generated }
            } else {
                await MainActor.run { prefetchedPrayer = GeminiService.fallbackPrayerForLanguage(prayerLanguage) }
            }
        }
    }

    private func dailyPrayerTheme() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let themes: [String]
        if hour < 12 {
            themes = ["gratitude for a new day", "morning surrender and trust in God", "seeking God's guidance at the start of the day"]
        } else if hour < 18 {
            themes = ["strength and focus in the middle of the day", "peace amid daily pressures", "renewing faith in the afternoon"]
        } else {
            themes = ["reflection and gratitude at the end of the day", "rest and trust in God's hands tonight", "evening thankfulness"]
        }
        return themes.randomElement()!
    }
}

// Carte de statut de prière du jour
struct PrayerStatusCard: View {
    let hasPrayed: Bool
    let streak: Int
    let onPrayNow: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        VStack(spacing: 16) {
            // Statut visuel
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("Today's Prayer", "Prière du jour"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    HStack(spacing: 6) {
                        Image(systemName: hasPrayed ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(hasPrayed ? .green : Color.amenaPrimary)
                        Text(hasPrayed ? t("Completed", "Terminée") : t("Pending", "En attente"))
                            .font(.system(size: 14))
                            .foregroundColor(hasPrayed ? .green : Color.amenaTextSecondary)
                    }
                }
                Spacer()
                // Streak
                VStack(spacing: 2) {
                    Text("\(streak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.amenaPrimary)
                    HStack(spacing: 2) {
                        Text(t("day streak", "jours d'affilée"))
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color.amenaTextSecondary)
                }
            }

            // Bouton "pray now" (visible seulement si pas encore prié)
            if !hasPrayed {
                Button(action: onPrayNow) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.sparkles.fill")
                        Text(t("pray now", "prier maintenant"))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.amenaPrimary)
                    .cornerRadius(14)
                }
            }
        }
        .padding(20)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(20)
    }
}

// Carte statut de la mascotte — vidéo en boucle plein fond + gradient bas
struct SheepStatusCard: View {
    let sheepName: String
    let level: Int
    let faithPercent: Double

    private var sheepVideoName: String {
        switch level {
        case 1, 2:  return "sheep_lv1"
        case 3, 4:  return "sheep_lv3"
        case 5, 6:  return "sheep_lv5"
        case 7, 8:  return "sheep_lv7"
        default:    return "sheep_lv9"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Vidéo mouton en boucle silencieuse
            if let url = Bundle.main.url(forResource: sheepVideoName, withExtension: "mp4") {
                LoopingVideoView(url: url)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            } else {
                // Fallback image si vidéo non trouvée
                Image(sheepVideoName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            }

            // Gradient sombre en bas
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 220)

            // Infos en bas
            VStack(spacing: 8) {
                HStack {
                    Text(sheepName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("lv \(level)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.amenaPrimary)
                        .cornerRadius(6)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: geo.size.width * faithPercent, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// Bannière de félicitations après 30 jours complétés
struct CycleCompletedBanner: View {
    let cycleNumber: Int
    let onDismiss: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("30-day journey complete!", "Parcours 30 jours terminé !"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(t("Cycle #\(cycleNumber) done. A new journey begins.", "Cycle #\(cycleNumber) terminé. Un nouveau parcours commence."))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "#4B8BF5"), Color(hex: "#7B5EF5")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
}

// LoopingVideoView et PlayerContainerView définis dans Services/LoopingVideoView.swift


// Extension pour clamp (limiter une valeur entre min et max)
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    HomeView()
}
