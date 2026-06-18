// Écran principal après l'onboarding
// Affiche le statut de prière du jour, le streak, et la mascotte mouton

import SwiftUI

struct HomeView: View {
    // Lecture des données stockées dans UserDefaults
    @AppStorage("userName") private var userName = "Friend"
    @AppStorage("sheepName") private var sheepName = "Nour"
    @AppStorage("onboardingCompleted") private var onboardingCompleted = true

    // Données SwiftData pour les prières (seront chargées depuis le contexte SwiftData)
    @State private var hasPrayedToday = false
    @State private var showPrayerView = false
    @State private var currentStreak = 0
    @State private var faithLevel = 1
    @State private var faithPercent = 0.0

    // StreakManager est un struct avec méthodes mutantes → @State pour le modifier
    @State private var streakManager = StreakManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // En-tête : bonjour + nom
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("good \(timeOfDay), \(userName) 👋")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.amenaText)
                                Text(hasPrayedToday ? "You've prayed today ✓" : "Don't forget to pray today")
                                    .font(.system(size: 14))
                                    .foregroundColor(hasPrayedToday ? Color.amenaPrimary : Color.amenaTextSecondary)
                            }
                            Spacer()
                            // Bouton paramètres (future feature)
                            Button {
                                // Settings
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

                        // Carte mascotte mouton
                        SheepStatusCard(
                            sheepName: sheepName,
                            level: faithLevel,
                            faithPercent: faithPercent
                        )
                        .padding(.horizontal, 24)

                        // Grille 90 jours (aperçu compact)
                        MiniNinetyDayGrid()
                            .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showPrayerView) {
                PrayerView {
                    // Callback quand la prière est terminée
                    hasPrayedToday = true
                    currentStreak = streakManager.markPrayedToday()
                    faithPercent = min(1.0, faithPercent + 0.05)
                    if faithPercent >= 1.0 {
                        faithLevel += 1
                        faithPercent = 0.0
                    }
                }
            }
        }
        .onAppear {
            loadState()
        }
    }

    // Détermine si c'est matin/après-midi/soir pour le message de bonjour
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }

    // Charge l'état depuis UserDefaults et StreakManager
    private func loadState() {
        hasPrayedToday = streakManager.hasPrayedToday
        currentStreak = streakManager.currentStreak
        faithLevel = UserDefaults.standard.integer(forKey: "faithLevel").clamped(to: 1...100)
        faithPercent = UserDefaults.standard.double(forKey: "faithPercent")
    }
}

// Carte de statut de prière du jour
struct PrayerStatusCard: View {
    let hasPrayed: Bool
    let streak: Int
    let onPrayNow: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Statut visuel
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Prayer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    HStack(spacing: 6) {
                        Image(systemName: hasPrayed ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(hasPrayed ? .green : Color.amenaPrimary)
                        Text(hasPrayed ? "Completed 🙏" : "Pending")
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
                    Text("day streak 🔥")
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                }
            }

            // Bouton "pray now" (visible seulement si pas encore prié)
            if !hasPrayed {
                Button(action: onPrayNow) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.sparkles.fill")
                        Text("pray now")
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

// Carte statut de la mascotte mouton
struct SheepStatusCard: View {
    let sheepName: String
    let level: Int
    let faithPercent: Double

    var body: some View {
        HStack(spacing: 16) {
            // Emoji mouton
            Text("🐑")
                .font(.system(size: 48))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(sheepName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.amenaText)
                    Spacer()
                    Text("lv \(level)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.amenaPrimary)
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("FAITH")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.amenaTextSecondary)
                        Spacer()
                        Text("\(Int(faithPercent * 100))%")
                            .font(.system(size: 10))
                            .foregroundColor(Color.amenaTextSecondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.amenaUnselectedBackground)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.amenaPrimary)
                                .frame(width: geo.size.width * faithPercent, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
    }
}

// Aperçu compact de la grille 90 jours sur l'écran d'accueil
struct MiniNinetyDayGrid: View {
    @AppStorage("prayedDays") private var prayedDaysData: Data = Data()

    // Jours priés stockés en JSON dans UserDefaults
    private var prayedDays: Set<Int> {
        (try? JSONDecoder().decode(Set<Int>.self, from: prayedDaysData)) ?? []
    }

    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 9)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("90-Day Journey")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.amenaText)
                Spacer()
                Text("\(prayedDays.count)/90 days")
                    .font(.system(size: 13))
                    .foregroundColor(Color.amenaTextSecondary)
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<90, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(prayedDays.contains(day) ? Color.amenaPrimary : Color.amenaUnselectedBackground)
                        .frame(height: 16)
                }
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
    }
}

// Extension pour clamp (limiter une valeur entre min et max)
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    HomeView()
}
