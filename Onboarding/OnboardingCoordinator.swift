// OnboardingCoordinator : gère la navigation entre toutes les étapes de l'onboarding
// Utilise un @State "step" pour avancer d'un écran à l'autre
// Chaque appel à next() avance au step suivant

import SwiftUI
import FirebaseAnalytics

// Enum qui liste toutes les étapes dans l'ordre exact
enum OnboardingStep: Int, CaseIterable {
    case language         // Choix de langue
    case introSlides      // 3 slides swipeables
    case userName         // Prénom
    case age              // Âge
    case screenTime       // Temps sur le téléphone
    case prayerFrequency  // Fréquence de prière
    case shockResult      // Résultat choc (X années)
    case hopeResult       // Espoir (X années rendues à Dieu)
    case bibleStat        // Statistique Bible
    case relationship     // Relation avec Dieu (fond orange)
    case mood             // Humeur du jour (fond bleu)
    case mascot           // Mascotte mouton
    case firstPrayer      // Première prière
    case congratulations  // Félicitations
    case verseOfDay       // Verset du jour
    case prayerTimes      // Heures de prière
    case notifications    // Permission notifications
    case paywall          // Abonnement
}

struct OnboardingCoordinator: View {
    @State private var step: OnboardingStep = .language

    // Données collectées pendant l'onboarding, passées entre les écrans
    @State private var userName: String = ""
    @State private var userAge: String = ""
    @State private var dailyScreenTime: Double = 3.0
    @State private var prayerFrequency: Double = 2.0
    @State private var godRelationship: Double = 0.5
    @State private var todayMood: Double = 0.5
    @State private var sheepName: String = "Nour"
    @State private var generatedPrayer: String = ""

    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("prayerLanguage") private var prayerLanguage: String = "English"

    // Thèmes variés selon l'heure et la relation avec Dieu
    private var prayerTheme: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let morningThemes = ["gratitude for a new day", "seeking God's guidance at the start of the day", "morning surrender and trust in God"]
        let afternoonThemes = ["strength and focus in the middle of the day", "peace amid daily pressures", "renewing faith in the afternoon"]
        let eveningThemes = ["reflection and gratitude at the end of the day", "rest and trust in God's hands tonight", "evening thankfulness and releasing the day to God"]
        let lowRelationshipThemes = ["returning to God and seeking restoration", "breaking free from distraction and reconnecting with God"]
        let highRelationshipThemes = ["deepening intimacy with God", "rejoicing in God's faithfulness and love"]

        if godRelationship < 0.35 {
            return lowRelationshipThemes.randomElement()!
        } else if godRelationship > 0.7 {
            return highRelationshipThemes.randomElement()!
        } else if hour < 12 {
            return morningThemes.randomElement()!
        } else if hour < 18 {
            return afternoonThemes.randomElement()!
        } else {
            return eveningThemes.randomElement()!
        }
    }

    var body: some View {
        // Transition en glissement horizontal entre les écrans
        ZStack {
            switch step {
            case .language:
                LanguageView(onNext: {
                    generatedPrayer = ""  // reset si la langue change
                    next()
                })

            case .introSlides:
                IntroSlidesView(onNext: next)

            case .userName:
                UserNameView(userName: $userName, onNext: next)

            case .age:
                AgeView(selectedAge: $userAge, onNext: next)

            case .screenTime:
                ScreenTimeView(screenTime: $dailyScreenTime, onNext: next)

            case .prayerFrequency:
                PrayerFrequencyView(frequency: $prayerFrequency, onNext: next)

            case .shockResult:
                ShockResultView(
                    userName: userName,
                    dailyScreenTime: dailyScreenTime,
                    onNext: next
                )

            case .hopeResult:
                HopeResultView(dailyScreenTime: dailyScreenTime, onNext: next)

            case .bibleStat:
                BibleStatView(dailyScreenTime: dailyScreenTime, onNext: next)

            case .relationship:
                RelationshipView(value: $godRelationship, onNext: next)

            case .mood:
                MoodView(value: $todayMood, onNext: next)

            case .mascot:
                MascotView(sheepName: $sheepName, onNext: next)
                    .onAppear { prefetchPrayer() }

            case .firstPrayer:
                FirstPrayerView(prayer: $generatedPrayer, onNext: next)

            case .congratulations:
                CongratulationsView(prayer: generatedPrayer, onNext: next)

            case .verseOfDay:
                VerseOfDayView(onNext: next)

            case .prayerTimes:
                PrayerTimesView(onNext: next)

            case .notifications:
                NotificationsView(onNext: next)

            case .paywall:
                PaywallView(onNext: finishOnboarding)
            }
        }
        // Animation glissement gauche → droite à chaque changement d'étape
        .animation(.easeInOut(duration: 0.3), value: step)
        .onAppear {
            // Premier écran de l'onboarding → event "onboarding_started"
            AnalyticsService.shared.log(.onboardingStarted)
        }
    }

    // Lance la génération Gemini en arrière-plan pendant que l'utilisateur est sur MascotView
    private func prefetchPrayer() {
        guard generatedPrayer.isEmpty else { return }
        Task {
            do {
                let prayer = try await GeminiService.shared.generatePrayer(theme: prayerTheme, language: prayerLanguage)
                await MainActor.run { generatedPrayer = prayer }
            } catch {
                await MainActor.run { generatedPrayer = GeminiService.fallbackPrayerForLanguage(prayerLanguage) }
            }
        }
    }

    // Passe à l'étape suivante
    private func next() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: step),
              currentIndex + 1 < OnboardingStep.allCases.count else {
            finishOnboarding()
            return
        }
        // withAnimation déclenche la transition visuelle
        withAnimation {
            step = OnboardingStep.allCases[currentIndex + 1]
        }
    }

    // Termine l'onboarding → ContentView affichera HomeView
    private func finishOnboarding() {
        // Sauvegarde des données dans UserDefaults
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(userAge, forKey: "userAge")
        UserDefaults.standard.set(dailyScreenTime, forKey: "dailyScreenTime")
        UserDefaults.standard.set(prayerFrequency, forKey: "prayerFrequency")
        UserDefaults.standard.set(sheepName, forKey: "sheepName")
        // L'utilisateur a prié pendant l'onboarding → on marque aujourd'hui comme prié
        var sm = StreakManager()
        sm.markPrayedToday()
        // Onboarding terminé → event "onboarding_completed"
        AnalyticsService.shared.log(.onboardingCompleted)
        withAnimation {
            onboardingCompleted = true
        }
    }
}

// Barre de progression orange en haut (utilisée dans la Partie 2)
struct OnboardingProgressBar: View {
    let currentStep: Int    // Étape actuelle (ex: 1)
    let totalSteps: Int     // Total d'étapes (ex: 9)

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fond gris
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.amenaUnselectedBackground)
                    .frame(height: 4)
                // Barre orange avançante
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.amenaPrimary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
    }
}
