# Amena — Christian Prayer App

> "Les réseaux sociaux t'éloignent de Dieu. Bloque ton téléphone jusqu'à ce que tu pries."

Application iOS de prière chrétienne inspirée de PrayerLock.

## Stack

- **Swift 6 / SwiftUI** — iOS 16+
- **Gemini API** (Google AI) — génération de prières personnalisées
- **StoreKit 2** — abonnements In-App Purchase
- **Firebase Analytics** — suivi du comportement utilisateur
- **AVKit** — animations mouton en boucle (MP4 silencieux)
- Stockage local uniquement (UserDefaults) — pas de compte utilisateur

## Setup

### 1. Cloner le repo
```bash
git clone https://github.com/LouisBlankaert/amena.git
cd amena
```

### 2. Créer Secrets.swift (JAMAIS commité)
```swift
// Secrets.swift
enum Secrets {
    static let geminiAPIKey = "VOTRE_CLE_GEMINI"
}
```

### 3. Ajouter GoogleService-Info.plist (Firebase)
Télécharger depuis console.firebase.google.com → projet Amena → ajouter à la racine du projet.

### 4. Générer le projet Xcode
```bash
xcodegen generate
```

### 5. Build
```bash
xcodebuild -scheme Amena -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Produits IAP (App Store Connect)

| ID | Type | Prix | Essai |
|----|------|------|-------|
| com.louis.Amena.yearly | Auto-renewable | 89,99 €/an | 3 jours |
| com.louis.Amena.weekly | Auto-renewable | 9,99 €/sem | Aucun |

## Pages légales

- Privacy Policy : https://louisblankaert.github.io/amena/privacy.html
- Terms of Use : https://louisblankaert.github.io/amena/terms.html

## Firebase Events trackés

| Event | Déclencheur |
|-------|-------------|
| `onboarding_started` | Lancement app première fois |
| `onboarding_completed` | Fin de l'onboarding |
| `prayer_started` | Ouverture PrayerView |
| `prayer_completed` | Bouton "i've prayed today" |
| `paywall_shown` | Affichage PaywallView |
| `trial_started` | Début essai gratuit |
| `subscription_purchased` | Achat abonnement |

## Architecture

```
Amena/
├── AmenaApp.swift
├── ContentView.swift
├── Secrets.swift              ← .gitignore
├── Onboarding/                ← 15 écrans
├── Main/                      ← Home, Prayer, Journal, Settings
├── Models/                    ← StreakManager, PrayerSession
├── Services/                  ← Gemini, StoreKit, Notifications, LoopingVideo
├── Extensions/                ← Color+Theme
├── Resources/                 ← Vidéos mouton (MP4)
├── Assets.xcassets/           ← Illustrations Midjourney
└── docs/                      ← Privacy Policy + Terms (GitHub Pages)
```
