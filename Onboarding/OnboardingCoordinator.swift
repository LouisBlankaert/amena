// OnboardingCoordinator : le parcours de bienvenue, 8 écrans sous le ciel du moment
// (même univers que l'accueil et la prière, voir SkyMoment dans HomeView.swift).
// Chaque écran demande une seule chose ; rien n'est demandé qui ne serve pas ensuite :
// le prénom (salutation), le temps d'écran (le chiffre choc), les intentions (les
// prières parlent de la vie de la personne), l'heure de rappel (notifications).

import SwiftUI
import UserNotifications
import FirebaseAnalytics

enum OnboardingStep: Int, CaseIterable {
    case welcome        // Nom de l'app + choix de langue
    case name           // Prénom
    case screenTime     // Temps sur le téléphone
    case reveal         // "X ans devant un écran" + l'espoir
    case intentions     // Ce qui pèse sur le cœur → personnalise les prières
    case firstPrayer    // Première prière (écran "Amen")
    case notifications  // Verset de 10h + heure du rappel
    case paywall        // Abonnement
}

struct OnboardingCoordinator: View {
    @State private var step: OnboardingStep = .welcome

    // Données collectées pendant l'onboarding
    @State private var userName: String = ""
    @State private var dailyScreenTime: Double = 3.0
    @State private var intentions: Set<PrayerIntention> = []
    @State private var generatedPrayer: String = ""

    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage("prayerLanguage") private var prayerLanguage: String = "English"

    // Le ciel reste le même pendant tout le parcours (pas de saut de couleur entre écrans)
    private let moment = SkyMoment.current

    var body: some View {
        ZStack {
            SkyBackground(moment: moment).ignoresSafeArea()
            // Voile léger pour que le texte blanc reste lisible sur les ciels clairs
            Color.black.opacity(0.12).ignoresSafeArea()

            Group {
                switch step {
                case .welcome:
                    WelcomeStep(onNext: next)
                case .name:
                    NameStep(userName: $userName, onNext: next)
                case .screenTime:
                    ScreenTimeStep(hours: $dailyScreenTime, onNext: next)
                case .reveal:
                    RevealStep(userName: userName, dailyScreenTime: dailyScreenTime, onNext: next)
                case .intentions:
                    IntentionsStep(selection: $intentions) {
                        PrayerIntention.save(PrayerIntention.allCases.filter(intentions.contains))
                        prefetchPrayer()
                        next()
                    }
                case .firstPrayer:
                    PrayerView(prefetchedPrayer: generatedPrayer, showsCloseButton: false, onPrayerCompleted: next)
                case .notifications:
                    NotificationsStep(onNext: next)
                case .paywall:
                    PaywallView(onNext: finishOnboarding)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(step)

            // Progression discrète (pas sur l'accueil, la prière ni le paywall qui ont leur propre haut)
            if [.name, .screenTime, .reveal, .intentions, .notifications].contains(step) {
                VStack {
                    OnboardingProgress(step: step)
                        .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.log(.onboardingStarted)
            #if DEBUG
            // Raccourci de test : -debugOnboardingStep 3 ouvre directement l'étape 3
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-debugOnboardingStep"), i + 1 < args.count,
               let raw = Int(args[i + 1]), let debugStep = OnboardingStep(rawValue: raw) {
                userName = "Louis"
                step = debugStep
            }
            #endif
        }
    }

    // Lance la génération de la première prière pendant que la personne lit l'écran suivant
    private func prefetchPrayer() {
        generatedPrayer = ""
        Task {
            let prayer = (try? await GeminiService.shared.generatePrayer(theme: DailyPrayerTheme.current, language: prayerLanguage))
                ?? GeminiService.fallbackPrayerForLanguage(prayerLanguage)
            await MainActor.run { generatedPrayer = prayer }
        }
    }

    private func next() {
        guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else {
            finishOnboarding()
            return
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            step = nextStep
        }
    }

    // Termine l'onboarding → ContentView affichera l'accueil
    private func finishOnboarding() {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(name.isEmpty ? t("Friend", "l'ami") : name, forKey: "userName")
        UserDefaults.standard.set(dailyScreenTime, forKey: "dailyScreenTime")
        // La première prière a été faite pendant l'onboarding → aujourd'hui compte
        var sm = StreakManager()
        sm.markPrayedToday()
        AnalyticsService.shared.log(.onboardingCompleted)
        withAnimation {
            onboardingCompleted = true
        }
    }
}

// MARK: - Éléments communs

// Petits traits blancs en haut : où on en est dans le parcours
private struct OnboardingProgress: View {
    let step: OnboardingStep
    private let counted: [OnboardingStep] = [.name, .screenTime, .reveal, .intentions, .firstPrayer, .notifications]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(counted, id: \.self) { s in
                Capsule()
                    .fill(Color.white.opacity(s.rawValue <= step.rawValue ? 0.95 : 0.3))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 24)
        .accessibilityHidden(true)
    }
}

// Mise en page partagée : titre serif en haut à gauche, contenu, bouton blanc en bas
private struct StepLayout<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let buttonTitle: String
    var buttonEnabled: Bool = true
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 64)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            OnboardingButton(title: buttonTitle, enabled: buttonEnabled, action: action)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(enabled ? Color.amenaNightBlue : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(enabled ? Color.white : Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

// MARK: - 1. Bienvenue

private struct WelcomeStep: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var prayerLanguage: String = "English"
    @AppStorage("languageAutoDetected") private var languageAutoDetected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Choix de langue : un simple interrupteur, pas un écran entier
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    languageChip("FR", value: "French")
                    languageChip("EN", value: "English")
                }
                .padding(3)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()

            Text("amena")
                .font(.system(size: 64, weight: .regular, design: .serif))
                .foregroundColor(.white)
            Text(t("Pray first.\nEverything else can wait.", "Priez d'abord.\nLe reste peut attendre."))
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .padding(.top, 8)
            Text(t("A prayer written for your life, a verse every morning. Five minutes a day.",
                   "Une prière écrite pour votre vie, un verset chaque matin. Cinq minutes par jour."))
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            Spacer().frame(height: 48)

            OnboardingButton(title: t("Begin", "Commencer"), action: onNext)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Première ouverture : on suit la langue du téléphone
            guard !languageAutoDetected else { return }
            languageAutoDetected = true
            prayerLanguage = Locale.preferredLanguages.first?.hasPrefix("fr") == true ? "French" : "English"
        }
    }

    private func languageChip(_ label: String, value: String) -> some View {
        Button {
            prayerLanguage = value
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(prayerLanguage == value ? Color.amenaNightBlue : .white)
                .frame(width: 44, height: 30)
                .background(prayerLanguage == value ? Color.white : Color.clear)
                .clipShape(Capsule())
        }
        .accessibilityLabel(value == "French" ? "Français" : "English")
        .accessibilityAddTraits(prayerLanguage == value ? .isSelected : [])
    }
}

// MARK: - 2. Prénom

private struct NameStep: View {
    @Binding var userName: String
    let onNext: () -> Void
    @FocusState private var focused: Bool

    private var isValid: Bool { !userName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        StepLayout(
            title: t("What should we call you?", "Comment doit-on vous appeler ?"),
            subtitle: t("Your prayers will be written for you.", "Vos prières seront écrites pour vous."),
            buttonTitle: t("Continue", "Continuer"),
            buttonEnabled: isValid,
            action: submit
        ) {
            VStack {
                TextField("", text: $userName, prompt: Text(t("Your first name", "Votre prénom")).foregroundColor(.white.opacity(0.5)))
                    .font(.system(size: 24, design: .serif))
                    .foregroundColor(.white)
                    .tint(.white)
                    .textContentType(.givenName)
                    .submitLabel(.continue)
                    .focused($focused)
                    .onSubmit(submit)
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
                    }
                    .padding(.top, 40)
                Spacer()
            }
        }
        .onAppear { focused = true }
    }

    private func submit() {
        guard isValid else { return }
        focused = false
        onNext()
    }
}

// MARK: - 3. Temps d'écran

private struct ScreenTimeStep: View {
    @Binding var hours: Double
    let onNext: () -> Void

    var body: some View {
        StepLayout(
            title: t("How long are you on your phone each day?", "Combien de temps passez-vous sur votre téléphone chaque jour ?"),
            subtitle: t("Be honest, nobody else will see it.", "Soyez honnête, personne d'autre ne le verra."),
            buttonTitle: t("Continue", "Continuer"),
            action: onNext
        ) {
            VStack(spacing: 28) {
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(hours))")
                        .font(.system(size: 96, weight: .regular, design: .serif))
                        .contentTransition(.numericText())
                    Text(t("h / day", "h / jour"))
                        .font(.system(size: 22, design: .serif))
                        .opacity(0.8)
                }
                .foregroundColor(.white)
                .animation(.easeOut(duration: 0.2), value: hours)

                Slider(value: $hours, in: 1...10, step: 1)
                    .tint(.white)
                    .accessibilityValue(t("\(Int(hours)) hours a day", "\(Int(hours)) heures par jour"))
                Spacer()
            }
        }
    }
}

// MARK: - 4. Le chiffre, puis l'espoir

private struct RevealStep: View {
    let userName: String
    let dailyScreenTime: Double
    let onNext: () -> Void
    @State private var showsHope = false

    // Heures par jour sur les 50 prochaines années, converties en années pleines
    private var years: Int {
        Int((dailyScreenTime * 365 * 50 / (24 * 365)).rounded())
    }

    private var name: String { userName.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text(t("\(name), over the next 50 years, that's", "\(name), sur les 50 prochaines années, cela fait"))
                .font(.system(size: 22, design: .serif))
                .foregroundColor(.white.opacity(0.85))
            Text(t("\(years) years", "\(years) ans"))
                .font(.system(size: 104, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(t("in front of a screen.", "devant un écran."))
                .font(.system(size: 22, design: .serif))
                .foregroundColor(.white.opacity(0.85))

            // L'espoir arrive un instant après le choc : on ne laisse pas la personne sur la culpabilité
            Text(t("No need to change everything. Five minutes of prayer a day, and that time starts to count differently.",
                   "Pas besoin de tout changer. Cinq minutes de prière par jour, et ce temps commence à compter autrement."))
                .font(.system(size: 17))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 32)
                .opacity(showsHope ? 1 : 0)
                .offset(y: showsHope ? 0 : 8)

            Spacer()
            OnboardingButton(title: t("Continue", "Continuer"), action: onNext)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(1.2)) { showsHope = true }
        }
    }
}

// MARK: - 5. Ce qui pèse sur le cœur

private struct IntentionsStep: View {
    @Binding var selection: Set<PrayerIntention>
    let onNext: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        StepLayout(
            title: t("What weighs on your heart right now?", "Qu'est-ce qui pèse sur votre cœur en ce moment ?"),
            subtitle: t("Your prayers will speak about what you're living. Pick as many as you like.",
                        "Vos prières parleront de ce que vous vivez. Choisissez-en autant que vous voulez."),
            buttonTitle: selection.isEmpty ? t("Skip", "Passer") : t("Write my prayer", "Écrire ma prière"),
            action: onNext
        ) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(PrayerIntention.allCases) { intention in
                        let isOn = selection.contains(intention)
                        Button {
                            if isOn { selection.remove(intention) } else { selection.insert(intention) }
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: intention.icon)
                                    .font(.system(size: 15))
                                    .frame(width: 20)
                                Text(intention.label)
                                    .font(.system(size: 15, weight: .medium))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .foregroundColor(isOn ? Color.amenaNightBlue : .white)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 56)
                            .background(isOn ? Color.white : Color.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - 7. Notifications

private struct NotificationsStep: View {
    let onNext: () -> Void
    @State private var reminderTime: Date = {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    private var verse: (text: String, reference: String) { DailyVerse.today }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(t("A verse every morning", "Un verset chaque matin"))
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .padding(.top, 64)
            Text(t("At 10 a.m., the verse of the day. And a gentle reminder to pray, at the time that suits you.",
                   "À 10 h, le verset du jour. Et un petit rappel pour prier, à l'heure qui vous va."))
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            // Aperçu de la vraie notification de demain
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.amenaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(t("Verse of the day", "Verset du jour"))
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("10:00")
                            .font(.system(size: 12))
                            .opacity(0.6)
                    }
                    Text(verse.text)
                        .font(.system(size: 14))
                        .lineLimit(3)
                }
                .foregroundColor(Color.amenaText)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.top, 32)

            HStack {
                Text(t("Remind me to pray at", "Me rappeler de prier à"))
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                Spacer()
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
            .padding(.top, 28)

            Spacer()

            OnboardingButton(title: t("Allow notifications", "Autoriser les notifications"), action: requestPermission)
            Button(t("Not now", "Pas maintenant")) {
                saveReminder()
                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                onNext()
            }
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.75))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 24)
    }

    // Une seule heure de rappel (modifiable ensuite dans Réglages)
    private func saveReminder() {
        if let data = try? JSONEncoder().encode([reminderTime]) {
            UserDefaults.standard.set(data, forKey: "prayerTimes")
        }
    }

    private func requestPermission() {
        saveReminder()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                if granted {
                    NotificationService.shared.schedulePrayerNotifications()
                }
                onNext()
            }
        }
    }
}

#Preview {
    OnboardingCoordinator()
}
