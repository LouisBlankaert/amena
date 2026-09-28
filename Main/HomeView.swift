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
    @State private var showWelcomeBackBanner = false
    @State private var prefetchedPrayer = ""  // pré-généré en arrière-plan
    @State private var prayers: [PrayerEntry] = []
    @State private var moment = SkyMoment.current

    // Niveau et % FAITH calculés dynamiquement depuis totalPrayers
    private var levelData: (level: Int, faithPercent: Double) {
        StreakManager.computeLevel(totalPrayers: totalPrayers)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond derrière le scroll : couleur du haut du ciel en haut (pour le
                // rebond du scroll), blanc en bas (continuité avec le panneau)
                VStack(spacing: 0) {
                    moment.colors.first!.frame(height: 400)
                    Color.amenaBackground
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        VerseHero(
                            moment: moment,
                            greeting: t("good \(timeOfDay), \(userName)", "\(greetingFr), \(userName)"),
                            onSettings: { showSettings = true }
                        )

                        // Panneau blanc qui remonte par-dessus le ciel
                        VStack(spacing: 20) {
                            PrayerActionSection(
                                hasPrayed: hasPrayedToday,
                                userName: userName,
                                streak: currentStreak,
                                totalPrayers: totalPrayers,
                                onPrayNow: { showPrayerView = true }
                            )

                            // Bannière de retour bienveillante après une pause (jamais punitive)
                            if showWelcomeBackBanner {
                                WelcomeBackBanner(onDismiss: { showWelcomeBackBanner = false })
                            }

                            // Bannière cycle complet (30 jours)
                            if showCycleBanner {
                                CycleCompletedBanner(
                                    cycleNumber: completedCycles,
                                    onDismiss: { showCycleBanner = false }
                                )
                            }

                            SheepRow(
                                sheepName: sheepName,
                                level: levelData.level,
                                faithPercent: levelData.faithPercent
                            )

                            // Historique de prière façon GitHub
                            PrayerContributionGrid(prayers: prayers)

                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .background(Color.amenaBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .padding(.top, -32)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showPrayerView) {
                PrayerView(prefetchedPrayer: prefetchedPrayer) {
                    let result = streakManager.markPrayedToday()
                    currentStreak  = result.streak
                    showWelcomeBackBanner = result.isReturningAfterBreak
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
            moment = SkyMoment.current
            loadState()
            #if DEBUG
            // Raccourci de test : lancer avec l'argument -debugOpenPrayer ouvre la prière
            if ProcessInfo.processInfo.arguments.contains("-debugOpenPrayer") {
                showPrayerView = true
            }
            #endif
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
            let theme = DailyPrayerTheme.current
            if let generated = try? await GeminiService.shared.generatePrayer(theme: theme, language: prayerLanguage) {
                await MainActor.run { prefetchedPrayer = generated }
            } else {
                await MainActor.run { prefetchedPrayer = GeminiService.fallbackPrayerForLanguage(prayerLanguage) }
            }
        }
    }
}

// Moment de la journée : pilote le ciel en fond de l'accueil.
// Les chrétiens prient depuis toujours à des heures précises (laudes à l'aube,
// vêpres au couchant...) : le ciel rappelle à quel moment de la journée on prie.
enum SkyMoment {
    case dawn, day, dusk, night

    static var current: SkyMoment {
        #if DEBUG
        // Pour tester les 4 ciels sans attendre l'heure : réglage "debugSkyMoment"
        // (dawn / day / dusk / night) dans UserDefaults, ignoré en version App Store
        switch UserDefaults.standard.string(forKey: "debugSkyMoment") {
        case "dawn":  return .dawn
        case "day":   return .day
        case "dusk":  return .dusk
        case "night": return .night
        default:      break
        }
        #endif
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11:  return .dawn
        case 11..<17: return .day
        case 17..<21: return .dusk
        default:      return .night
        }
    }

    // Dégradé du haut du ciel vers l'horizon
    var colors: [Color] {
        switch self {
        case .dawn:  return [Color(hex: "#4A6FB8"), Color(hex: "#B69BC9"), Color(hex: "#F4BE9C")]
        case .day:   return [Color(hex: "#2C68CF"), Color(hex: "#5C98E6"), Color(hex: "#A9CDF6")]
        case .dusk:  return [Color(hex: "#262659"), Color(hex: "#7E4887"), Color(hex: "#E8905A")]
        case .night: return [Color(hex: "#060A22"), Color(hex: "#141C49"), Color(hex: "#27336F")]
        }
    }

    // Soleil ou lune : couleur, position et taille du halo
    var glowColor: Color {
        switch self {
        case .dawn:  return Color(hex: "#FFE2B5")
        case .day:   return .white
        case .dusk:  return Color(hex: "#FFB36B")
        case .night: return Color(hex: "#F3EFDC")
        }
    }

    var glowPosition: UnitPoint {
        switch self {
        case .dawn:  return UnitPoint(x: 0.85, y: 0.95)
        case .day:   return UnitPoint(x: 0.88, y: 0.12)
        case .dusk:  return UnitPoint(x: 0.12, y: 0.95)
        case .night: return UnitPoint(x: 0.72, y: 0.2)   // décalée pour ne pas passer sous les boutons ronds
        }
    }

    var showsStars: Bool { self == .night }
}

// Le ciel : dégradé + halo du soleil/de la lune + étoiles la nuit
struct SkyBackground: View {
    let moment: SkyMoment

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: moment.colors, startPoint: .top, endPoint: .bottom)

                // Halo large et doux, puis le disque lui-même
                Circle()
                    .fill(moment.glowColor.opacity(0.55))
                    .frame(width: 260, height: 260)
                    .blur(radius: 70)
                    .position(x: geo.size.width * moment.glowPosition.x,
                              y: geo.size.height * moment.glowPosition.y)
                Circle()
                    .fill(moment.glowColor.opacity(moment == .day ? 0.5 : 0.9))
                    .frame(width: moment == .night ? 34 : 56, height: moment == .night ? 34 : 56)
                    .blur(radius: moment == .night ? 0.5 : 8)
                    .position(x: geo.size.width * moment.glowPosition.x,
                              y: geo.size.height * moment.glowPosition.y)

                if moment.showsStars {
                    StarField()
                }
            }
        }
    }
}

// Étoiles placées de façon fixe (même ciel à chaque ouverture, pas de scintillement aléatoire)
struct StarField: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 7
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 33) / Double(UInt32.max >> 1)
            }
            for _ in 0..<70 {
                let x = next() * size.width
                let y = next() * size.height * 0.8
                let r = 0.5 + next() * 1.2
                let rect = CGRect(x: x, y: y, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.35 + next() * 0.5)))
            }
        }
    }
}

// Le haut de l'accueil : le ciel du moment et, au centre, le verset du jour en grand
struct VerseHero: View {
    let moment: SkyMoment
    let greeting: String
    let onSettings: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var verse: (text: String, reference: String) { DailyVerse.today }

    // Le verset doit tenir dans le ciel : plus il est long, plus la police est petite
    private var verseSize: CGFloat {
        switch verse.text.count {
        case ..<70:   return 32
        case ..<130:  return 27
        default:      return 23
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(greeting)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel(t("Settings", "Réglages"))
            }
            .padding(.top, 8)

            Spacer(minLength: 64)

            // Le verset, en serif comme dans une Bible imprimée
            Text(t("“\(verse.text)”", "« \(verse.text) »"))
                .font(.system(size: verseSize, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .lineSpacing(verseSize * 0.18)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 2)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verse.reference)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                    Text(DailyVerse.translationName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button(action: shareVerse) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel(t("Share this verse", "Partager ce verset"))
            }
            .padding(.top, 20)

            Spacer(minLength: 88) // place pour le panneau blanc qui remonte par-dessus
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 560)
        .background(SkyBackground(moment: moment).ignoresSafeArea(edges: .top))
    }

    private func shareVerse() {
        let text = "\(verse.text)\n— \(verse.reference) (\(DailyVerse.translationName))"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// Bouton de prière du jour + série de jours
struct PrayerActionSection: View {
    let hasPrayed: Bool
    let userName: String
    let streak: Int
    let totalPrayers: Int
    let onPrayNow: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if hasPrayed {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.amenaPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("You've prayed today", "Vous avez prié aujourd'hui"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.amenaText)
                        Text(t("See you tomorrow, \(userName).", "À demain, \(userName)."))
                            .font(.system(size: 14))
                            .foregroundColor(Color.amenaTextSecondary)
                    }
                }
            } else {
                Button(action: onPrayNow) {
                    HStack(spacing: 10) {
                        Image(systemName: "hands.sparkles.fill")
                        Text(t("Pray now", "Prier maintenant"))
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.amenaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                Text(t("A prayer written for you today, about 2 minutes.", "Une prière écrite pour vous aujourd'hui, environ 2 minutes."))
                    .font(.system(size: 14))
                    .foregroundColor(Color.amenaTextSecondary)
                    .frame(maxWidth: .infinity)
            }

            // Pas de "0 jour" au premier lancement : on n'affiche la série qu'une fois commencée
            if totalPrayers > 0 {
                HStack(spacing: 18) {
                    Label(t("\(streak)-day streak", "\(streak) jours d'affilée"), systemImage: "flame.fill")
                    Label(t("\(totalPrayers) prayers", "\(totalPrayers) prières"), systemImage: "hands.and.sparkles.fill")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.amenaText)
                .labelStyle(StatLabelStyle())
                .padding(.top, 4)
            }
        }
    }
}

private struct StatLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundColor(.orange)
            configuration.title
        }
    }
}

// Mascotte en format compact : la vidéo en vignette, le nom, le niveau et la barre FAITH
struct SheepRow: View {
    let sheepName: String
    let level: Int
    let faithPercent: Double
    @AppStorage("prayerLanguage") private var lang: String = "English"

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
        HStack(spacing: 14) {
            Group {
                if let url = Bundle.main.url(forResource: sheepVideoName, withExtension: "mp4") {
                    LoopingVideoView(url: url)
                } else {
                    Image(sheepVideoName).resizable().scaledToFill()
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(sheepName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    Spacer()
                    Text(t("level \(level)", "niveau \(level)"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.amenaTextSecondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.amenaUnselectedBackground)
                        Capsule().fill(Color.amenaPrimary)
                            .frame(width: max(6, geo.size.width * faithPercent))
                    }
                }
                .frame(height: 6)
                Text(t("Grows with each prayer", "Grandit à chaque prière"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.amenaTextSecondary)
            }
        }
        .padding(14)
        .background(Color.amenaSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// Bannière affichée au retour après une pause : jamais punitive, jamais "streak cassé".
// L'app pardonne comme elle prêche que Dieu pardonne (Lamentations 3.23).
struct WelcomeBackBanner: View {
    let onDismiss: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(t("Good to see you again 🤍", "Content de te revoir 🤍"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.amenaText)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.amenaTextSecondary.opacity(0.6))
                }
            }
            Text(t(
                "\"His mercies are new every morning.\" — Lamentations 3:23",
                "« Ses compassions se renouvellent chaque matin. » — Lamentations 3.23"
            ))
                .font(.system(size: 13))
                .italic()
                .foregroundColor(Color.amenaTextSecondary)
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
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
