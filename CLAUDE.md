# Amena — Clone de PrayerLock (app de prière chrétienne avec blocage de téléphone)

## Concept
"Les réseaux sociaux t'éloignent de Dieu. Bloque ton téléphone jusqu'à ce que tu pries."
L'app bloque les apps du téléphone jusqu'à ce que l'utilisateur ait accompli sa prière du jour.
Inspirée de https://prayerlock.com/ — adapté pour la communauté chrétienne.

Nom de l'app : **Amena**
Bundle identifier : com.louis.Amena

## Stack
- Swift 6 / SwiftUI
- **StoreKit 2** pour les abonnements In-App Purchase
- **Superwall SDK** pour la gestion des paywalls
- **Gemini API** (Google AI) pour générer des prières en IA
- **Firebase Analytics** pour les analytics
- Pas de compte utilisateur — tout stocké localement (UserDefaults / SwiftData)
- Target : iOS 16+
- Xcode, Swift 6

## Couleurs et design (copie fidèle de PrayerLock)
- Couleur principale : orange (#F97316 ou similaire)
- Fond : blanc (#FFFFFF) et gris très clair (#F9F9F9)
- Texte : noir (#111111)
- Bouton principal : rectangle orange arrondi, texte blanc, pleine largeur en bas
- Bouton flottant : cercle orange avec flèche → (utilisé dans les slides d'intro)
- Style typographie : bold, lowercase pour les titres, sans-serif
- Gradient fond : blanc → orange très pâle (#FFF5EE) pour certains écrans

## Flow complet de l'onboarding (reproduire EXACTEMENT dans cet ordre)

### PARTIE 1 — Intro slides (swipeable, 3 slides, pas de bouton continue classique)
- Bouton flottant circulaire orange avec → en bas à droite pour avancer
- "signed in via web? sign in" en bas à gauche (lien texte orange)
- Indicateur de slide en haut (3 points, le actif = pill orange)

**Slide 1 :**
- Titre : "social media addiction is taking you away from **God.**" (God en orange)
- Illustration : Jésus/figure spirituelle + mouton qui s'éloigne (adapter pour Islam : silhouette en prière ou mosquée)

**Slide 2 :**
- Titre : "**amena** can help you choose God first daily." (amena en orange)
- Illustration : figure spirituelle tenant quelque chose (adapter)

**Slide 3 :**
- Titre : "it's **simple.** once a day, we block your apps" (simple en orange)
- 4 icônes apps verrouillées : Instagram, TikTok, Snapchat, X
- Slide suivante automatique : "once you **pray**, your apps unlock" (pray en orange)
- Mêmes 4 icônes mais déverrouillées (couleurs normales)

### PARTIE 2 — Questions personnalisation (chaque question = écran séparé, bouton "continue" orange en bas)
- Barre de progression en haut (orange, s'incrémente à chaque écran)

**Écran 1 — Prénom**
- "ready to step out of the old and into the **new?**" (new en orange)
- Aperçu visuel : grille 90 cases "90 day prayer journey - 0% Complete" avec date et "Your name"
- "what should we call you?" + TextField "enter your name"
- Stocker dans UserDefaults clé "userName"

**Écran 2 — Âge**
- "how old are you?"
- 5 boutons sélectionnables : 14-24 / 25-34 / 35-44 / 45-54 / 55+
- Stocker dans UserDefaults clé "userAge"

**Écran 3 — Temps sur le téléphone**
- "how long are you on your phone each day?" + sous-titre gris "be honest"
- Slider 1h → 10h, valeur en grand au centre + "hours/day"
- Stocker dans UserDefaults clé "dailyScreenTime"

**Écran 4 — Fréquence de prière**
- "be honest, how often do you pray per week?"
- Slider 0 → 7 jours, valeur en grand + "days/week"
- Stocker dans UserDefaults clé "prayerFrequency"

**Écran 5 — Résultat choc (calculé)**
- Fond : blanc → orange pâle gradient
- Emoji 🤯 en haut
- "[userName], at this rate you're going to spend **X years** of your life on your phone."
- Calcul : (dailyScreenTime heures × 365 jours × 50 ans de vie restante) / (24 × 365) = années
- "X years" en orange, bold, grand
- Pas de question, juste "continue"

**Écran 6 — Espoir (suite du résultat)**
- Fond : blanc → orange pâle gradient
- Illustration colombe blanche
- "...but the good news is, we'll help you give"
- "**X years back to God.**" (X = même chiffre, en orange, très grand)

**Écran 7 — Statistique inspirante**
- Fond : blanc → orange pâle gradient
- Illustration livre (Bible)
- "you could read the entire **Bible** in X days." (Bible en orange)
- Sous-titre gris : "if you traded your screen time for prayer time."
- Calcul : Bible = ~77 000 mots, lecture ~200 mots/min → adapter selon screen time

**Écran 8 — Relation avec God**
- Fond : orange vif (plein écran)
- Texte blanc : "how's your relationship with God today?"
- Slider avec emoji qui change selon valeur (😔 → 😊 → 😇)
- Label sous slider : "poor" / "okay" / "good" / "amazing"
- Bouton "continue" blanc avec texte orange

**Écran 9 — Humeur du jour**
- Fond : bleu ciel vif (#00BFFF)
- Texte blanc : "how are you feeling today?"
- Même slider avec emoji + label
- Bouton "continue" blanc avec texte bleu

### PARTIE 3 — Setup mascotte et première prière

**Écran 10 — Mascotte (mouton cartoon)**
- Illustration : mouton cartoon dans un paysage sombre (enchaîné → symbolise addiction)
- "your sheep's name" + TextField avec nom suggéré (ex: "Nour")
- Carte style trading card : nom du mouton + niveau "lv 2" + barre FAITH X%
- Verset biblique en bas de la carte
- Bouton : "let's go"
- Stocker nom mouton dans UserDefaults "sheepName"

**Écran 11 — Première prière (dans l'onboarding)**
- Titre : "let's pray" (bold)
- Sous-titre gris : "tap 'i've prayed today 🙏' once the prayer is complete"
- Texte de la dua générée par Gemini API (appel API ici)
- Bouton grisé au départ : "i've prayed today 🙏"
- Le bouton devient orange après X secondes (temps de lecture estimé)
- Lien : "share this prayer" (orange, avec icône partage)

**Écran 12 — Félicitations**
- Titre orange : "congratulations!"
- Sous-titre : "you've completed your first prayer"
- Carte récap de la prière (thème, date, début du texte, référence biblique)
- Texte bas : "your prayers will be saved in your journal to help you build a stronger relationship with God."
- Bouton : "continue"

**Écran 13 — Verset du jour**
- Fond : dégradé bleu (#1a1a6e → #00BFFF)
- "VERSE OF THE DAY" en petit caps
- Carte blanche avec verset biblique centré + référence en orange
- Bouton partage (icône) en haut à droite
- Bouton "continue" blanc avec texte orange

**Écran 14 — Heures de prière**
- Titre : "set your prayer times"
- Sous-titre gris : "your apps will lock at these times until you pray."
- Lien orange : "👆 tap any time to edit it"
- Liste de 3 horaires par défaut (horaires de prière chrétiennes : matin, midi, soir ou personnalisé)
  chacun avec heure + "every day" + toggle ON
- Bouton : "+ add prayer time"
- Bouton bas : "continue →"
- Stocker dans UserDefaults "prayerTimes" (array de Date)

**Écran 15 — Permission notifications**
- Titre : "allow amena to send you notifications"
- Sous-titre gris : "we use this to allow you to unblock your apps when you need to pray"
- Aperçu notification mockup : icône app + "your apps are blocked! time to pray" + "now"
- Bouton : "allow" → déclenche requestAuthorization UNUserNotificationCenter
- Stocker résultat dans UserDefaults "notificationsEnabled"

### PARTIE 4 — Paywall (après les notifications)

**Écran Paywall**
- En-tête : logo laurier "the #1 prayer habit app" + ⭐⭐⭐⭐⭐
- Titre : "start your 3-day FREE trial to continue"
- Timeline verticale avec 3 étapes :
  1. 🔓 **today** — "unlock all the app's features..."
  2. 🔔 **in 2 Days** — "we'll send you a reminder that your trial is ending soon."
  3. 👑 **in 3 Days** — "you'll be charged on [date J+3] unless you cancel anytime before."
- 2 options d'abonnement :
  - weekly : 9,99€/week (pas mis en avant, fond gris)
  - yearly : 1,73€/week (mis en avant, badge "3-day free trial", fond blanc avec bordure orange + checkmark orange)
- ✓ "No Payment Due Now" avec emoji main pointant 👇
- Bouton principal orange : "start my free trial"
- Texte bas petit : "3 days free, then 89,99 €/year (1,73 €/week)"
- Liens : Privacy • Terms

**Écran post-paywall**
- Titre : "we'll send you a reminder before your free trial ends"
- Illustration cloche avec badge rouge "1"
- ✓ "No Payment Due Now"
- Bouton : "continue for FREE"
- Texte bas : "just 89,99 € per year (1,73 €/week)"

## Produits StoreKit à configurer dans App Store Connect
| Identifiant                    | Type           | Prix      | Essai gratuit |
|-------------------------------|----------------|-----------|---------------|
| com.louis.Amena.yearly        | Auto-renewable | 89,99€/an | 3 jours       |
| com.louis.Amena.weekly        | Auto-renewable | 9,99€/sem | Aucun         |

- **Yearly mis en avant visuellement** (badge "3-day free trial", checkmark, bordure orange)
- Weekly existe pour l'ancrage psychologique de prix uniquement

## Écran principal (après onboarding)

### Vue Timer/Prière
- Affiche si la prière du jour est faite ou non
- Bouton "pray now" → ouvre l'écran de prière avec dua Gemini
- Streak du jour visible
- Mascotte mouton avec niveau et barre FAITH

### Vue Journal
- Historique des prières (SwiftData)
- Grille 90 jours avec cases remplies
- Carte de chaque prière avec date, thème, référence

## Services et APIs

### Gemini API
- Endpoint : `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- Prompt : "Generate a short, heartfelt Christian prayer in [French/English]. Include a Biblical reference. Maximum 100 words. Warm and personal tone."
- Clé API dans Secrets.swift (JAMAIS commité — dans .gitignore)

### Firebase Analytics — events à tracker
- `onboarding_started`
- `onboarding_completed`
- `prayer_started`
- `prayer_completed`
- `paywall_shown`
- `trial_started`
- `subscription_purchased`

### Superwall
- SDK via Swift Package Manager : https://github.com/superwall/Superwall-iOS
- Init dans AmenaApp.swift
- Utiliser pour afficher le paywall au bon moment

## Architecture des fichiers
```
Amena/
├── AmenaApp.swift
├── ContentView.swift
├── Secrets.swift                    ← clés API (dans .gitignore)
├── Onboarding/
│   ├── OnboardingCoordinator.swift  ← gère la navigation entre étapes
│   ├── IntroSlidesView.swift        ← 3 slides swipeables
│   ├── UserNameView.swift
│   ├── AgeView.swift
│   ├── ScreenTimeView.swift
│   ├── PrayerFrequencyView.swift
│   ├── ShockResultView.swift
│   ├── HopeResultView.swift
│   ├── BibleStatView.swift
│   ├── RelationshipView.swift
│   ├── MoodView.swift
│   ├── MascotView.swift
│   ├── FirstPrayerView.swift
│   ├── CongratulationsView.swift
│   ├── VerseOfDayView.swift
│   ├── PrayerTimesView.swift
│   ├── NotificationsView.swift
│   └── PaywallView.swift
├── Main/
│   ├── HomeView.swift
│   ├── PrayerView.swift
│   └── JournalView.swift
├── Models/
│   ├── PrayerSession.swift          ← SwiftData
│   └── StreakManager.swift
├── Services/
│   ├── GeminiService.swift
│   ├── StoreKitService.swift
│   └── NotificationService.swift
└── Extensions/
    └── Color+Theme.swift
```

## SDKs à installer via Swift Package Manager
- Superwall : https://github.com/superwall/Superwall-iOS
- Firebase : https://github.com/firebase/firebase-ios-sdk (FirebaseAnalytics + FirebaseCore)

## Ordre de développement
1. Setup projet + couleurs/thème (Color+Theme.swift)
2. Intro slides (3 écrans swipeables)
3. Questions onboarding (prénom → âge → sliders → résultats calculés)
4. Gemini API service + première prière dans l'onboarding
5. Mascotte mouton (illustration + système de niveau)
6. Paywall + StoreKit 2
7. Notifications (UNUserNotificationCenter)
8. Écran principal (Home + timer prière)
9. Journal (SwiftData + grille 90 jours)
10. Firebase Analytics (events)

## Style de travail
- Développeur iOS débutant, premier projet Swift/SwiftUI
- Explique les nouveaux concepts Swift dans les commentaires
- Une feature à la fois, build après chaque modification
- ```xcodebuild -scheme Amena -destination 'platform=iOS Simulator,name=iPhone 15' build```
- Un commit Git par feature qui compile
- Ne jamais commiter Secrets.swift (.gitignore dès le début)
- Pas de compte utilisateur = pas de suppression de compte (évite refus Apple 5.1.1(v))

## Notes Screen Time API (v2 uniquement)
Le blocage réel des apps (FamilyControls) est reporté en v2.
Pour le MVP : simuler visuellement le "blocage" (écran qui dit "tes apps sont bloquées")
sans vrai blocage technique. Fonctionnel et soumettable à l'App Store sans entitlement spécial.
