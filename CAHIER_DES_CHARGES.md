# Cahier des charges — Amena
**App de prière chrétienne avec blocage de téléphone**
Inspirée de PrayerLock · Bundle ID : `com.louis.Amena`
Dernière mise à jour : 20 juin 2026 — 02:51

---

## Stack technique
| Élément | Choix |
|---|---|
| Langage | Swift 6 / SwiftUI |
| Cible | iOS 16+ |
| Paiements | StoreKit 2 |
| IA prières | Gemini API (`gemini-flash-latest`) |
| Analytics | Firebase Analytics |
| Stockage | UserDefaults (SwiftData prévu v2) |
| Compte utilisateur | Aucun (tout local) |

---

## Produits In-App Purchase
| Identifiant | Durée | Prix | Essai |
|---|---|---|---|
| `com.louis.Amena.yearly` | 1 an | 89,99 € | 3 jours gratuits |
| `com.louis.Amena.weekly` | 1 semaine | 9,99 € | Aucun |

---

## ÉTAT D'AVANCEMENT

### ✅ FAIT

#### Infrastructure
- [x] Projet Xcode créé (`com.louis.Amena`)
- [x] Swift 6, iOS 16+, SwiftUI
- [x] `Color+Theme.swift` — palette bleue complète (`amenaPrimary`, `amenaBackground`, etc.)
- [x] `Secrets.swift` dans `.gitignore` (clé Gemini jamais commitée)
- [x] Firebase Analytics intégré (`GoogleService-Info.plist`)
- [x] `AnalyticsService.swift` — events : `onboarding_started/completed`, `prayer_started/completed`, `paywall_shown`, `trial_started`, `subscription_purchased`
- [x] `AmenaApp.swift` — transaction listener StoreKit lancé au démarrage + vérification abonnement actif

#### Onboarding (15 écrans dans l'ordre)
- [x] **Slide 1/2/3** — intro swipeable, bouton flottant circulaire, indicateur de progression
- [x] **UserNameView** — prénom + aperçu grille 30 jours → `UserDefaults "userName"`
- [x] **AgeView** — 5 boutons de sélection → `UserDefaults "userAge"`
- [x] **ScreenTimeView** — slider 1h→10h → `UserDefaults "dailyScreenTime"`
- [x] **PrayerFrequencyView** — slider 0→7 jours → `UserDefaults "prayerFrequency"`
- [x] **ShockResultView** — calcul années écran (gradient blanc→bleu pâle)
- [x] **HopeResultView** — même calcul "années récupérées pour Dieu"
- [x] **BibleStatView** — calcul jours pour lire la Bible selon screen time
- [x] **RelationshipView** — slider emoji relation avec Dieu (fond bleu vif)
- [x] **MoodView** — slider emoji humeur du jour (fond bleu ciel)
- [x] **MascotView** — mouton cartoon, nom personnalisé, carte trading card → `UserDefaults "sheepName"`
- [x] **FirstPrayerView** — prière Gemini avec effet typewriter, bouton activé en fin d'animation
- [x] **CongratulationsView** — carte récap de la première prière
- [x] **VerseOfDayView** — verset du jour sur fond dégradé bleu profond
- [x] **PrayerTimesView** — 3 horaires par défaut, toggle ON/OFF, `+ add prayer time` → `UserDefaults "prayerTimes"`
- [x] **NotificationsView** — demande permission + appel `schedulePrayerNotifications()`
- [x] **PaywallView** — UI plan-aware (weekly ≠ yearly), timeline 3 jours, "No Payment Due Now", Restore button

#### Services
- [x] **GeminiService** — modèle `gemini-flash-latest`, 150-200 mots, paragraphes, ton poétique, 5 fallbacks aléatoires
- [x] **StoreKitService** — transaction listener, `checkCurrentSubscription()`, `restorePurchases()`, `simulatePurchase()` en fallback
- [x] **NotificationService** — notifications quotidiennes par heure de prière, rappel fin d'essai J+2
- [x] **amena.storekit** — fichier créé via Xcode UI (format correct), 2 produits configurés, scheme configuré

#### App principale (post-onboarding)
- [x] **Tab bar** Home + Journal
- [x] **HomeView** — streak, bouton "pray now", mouton avec niveau et barre FAITH, `@AppStorage("totalPrayers")`
- [x] **PrayerView** — prière Gemini typewriter, bouton "i've prayed today", sauvegarde directe UserDefaults + NotificationCenter
- [x] **JournalView** — grille 30 jours (% calculé sur `prayedDays` réels), historique prières, état vide illustré
- [x] **StreakManager** — calcul streak, total prières, jour prié aujourd'hui

#### UX/UI
- [x] Typewriter sans tremblement (`.animation(nil, value: displayedText)`)
- [x] Paywall weekly : pas de timeline, pas de "No Payment Due Now", texte légal adapté
- [x] PostPaywallView adapté selon plan (yearly = cloche + reminder, weekly = checkmark)
- [x] Emojis remplacés par SF Symbols (iOS 26 compatible)

---

### ❌ RESTE À FAIRE

#### Visuels / Assets (en cours — Midjourney)
- [ ] **Icône app** — mains en prière, fond bleu gradient, 1024×1024 PNG
- [ ] **Mouton lv 1-2** — bébé agneau triste (image fixe + vidéo animée)
- [ ] **Mouton lv 3-4** — mouton souriant
- [ ] **Mouton lv 5-6** — mouton avec auréole naissante
- [ ] **Mouton lv 7-8** — mouton avec auréole + ailes
- [ ] **Mouton lv 9-10** — mouton divin rayonnant
- [ ] **Slide 1** — cartoon personne accro au téléphone
- [ ] **Slide 2** — cartoon personne avec Amena, sourire
- [ ] **Slide 3** — cartoon personne en prière, lumière dorée
- [ ] **Screenshots** — 6 captures iPhone 6.9" pour l'App Store

#### Intégration assets (après réception Midjourney)
- [ ] Intégrer icône dans Assets.xcassets → AppIcon
- [ ] Intégrer 5 moutons dans HomeView/MascotView selon niveau
- [ ] Intégrer vidéo mouton bébé (VideoPlayer en boucle) dans HomeView
- [ ] Intégrer 3 illustrations dans IntroSlidesView

#### App Store Connect (obligatoire avant soumission)
- [ ] Créer la fiche app `com.louis.Amena` dans App Store Connect
- [ ] Créer les 2 produits IAP (`com.louis.Amena.yearly` + `com.louis.Amena.weekly`)
- [ ] Configurer l'essai gratuit 3 jours sur le plan yearly
- [ ] Remplir les métadonnées (nom, sous-titre, description FR + EN, mots-clés)
- [ ] Définir la catégorie : Lifestyle ou Health & Fitness
- [ ] Privacy Policy URL (obligatoire Apple si IAP)

#### Tests & Validation
- [ ] Tester le flow StoreKit complet sur appareil réel (sandbox Apple ID)
- [ ] Tester les notifications (heure de prière + rappel fin d'essai)
- [ ] Tester restore purchases sur appareil réel
- [ ] Tester Gemini sur iPhone réel (simulateur iOS 26 bloque le réseau)

#### Fonctionnalités manquantes
- [ ] **SettingsView** — réinitialiser l'onboarding, modifier les horaires, nom du mouton
- [ ] **Verset du jour dynamique** — actuellement statique
- [ ] **Langue** — choix FR/EN pour les prières générées

#### Technique / Polish
- [ ] Supprimer l'ancien `Amena.storekit` (remplacé par `amena.storekit`)
- [ ] Dark mode review

#### V2 (après soumission MVP)
- [ ] **Screen Time API / FamilyControls** — vrai blocage des apps (entitlement spécial Apple)
- [ ] **SwiftData** — remplacer UserDefaults pour le journal
- [ ] **iCloud sync** — synchroniser la progression entre appareils
- [ ] **Superwall SDK** — A/B testing des paywalls

---

## Architecture des fichiers (état actuel)
```
amena/
├── AmenaApp.swift                   ✅ transaction listener + checkCurrentSubscription
├── ContentView.swift                ✅ MainTabView (Home + Journal)
├── amena.storekit                   ✅ 2 produits configurés via Xcode UI
├── Secrets.swift                    ✅ clé Gemini (jamais commitée)
├── Extensions/
│   └── Color+Theme.swift            ✅ palette bleue complète
├── Onboarding/
│   ├── OnboardingCoordinator.swift  ✅ navigation 15 écrans
│   ├── IntroSlidesView.swift        ✅
│   ├── UserNameView.swift           ✅
│   ├── AgeView.swift                ✅
│   ├── ScreenTimeView.swift         ✅
│   ├── PrayerFrequencyView.swift    ✅
│   ├── ShockResultView.swift        ✅
│   ├── HopeResultView.swift         ✅
│   ├── BibleStatView.swift          ✅
│   ├── RelationshipView.swift       ✅
│   ├── MoodView.swift               ✅
│   ├── MascotView.swift             ✅
│   ├── FirstPrayerView.swift        ✅
│   ├── CongratulationsView.swift    ✅
│   ├── VerseOfDayView.swift         ✅
│   ├── PrayerTimesView.swift        ✅
│   ├── NotificationsView.swift      ✅
│   └── PaywallView.swift            ✅ plan-aware UI
├── Main/
│   ├── HomeView.swift               ✅
│   ├── PrayerView.swift             ✅ sauvegarde directe UserDefaults
│   ├── JournalView.swift            ✅ % basé sur prayedDays réels
│   └── SettingsView.swift           ⚠️ créé mais non intégré
├── Models/
│   ├── PrayerSession.swift          ✅
│   └── StreakManager.swift          ✅
└── Services/
    ├── GeminiService.swift          ✅ gemini-flash-latest, 150-200 mots
    ├── StoreKitService.swift        ✅ listener + restore + simulation fallback
    ├── NotificationService.swift    ✅ notifications quotidiennes + rappel essai
    └── AnalyticsService.swift       ✅ Firebase events
```

---

## Priorités pour la soumission App Store

| Priorité | Tâche |
|---|---|
| 🔴 Bloquant | Icône app 1024×1024 |
| 🔴 Bloquant | Créer app + IAP dans App Store Connect |
| 🔴 Bloquant | Privacy Policy URL |
| 🟡 Important | Screenshots 6.9" |
| 🟡 Important | Tester StoreKit sur appareil réel |
| 🟡 Important | Description FR + EN |
| 🟢 Nice-to-have | Illustrations intro slides |
| 🟢 Nice-to-have | Dark mode polish |
