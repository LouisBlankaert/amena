# Amena — Christian Prayer App

> "Les réseaux sociaux t'éloignent de Dieu. Bloque ton téléphone jusqu'à ce que tu pries."

Application iOS de prière chrétienne inspirée de PrayerLock.

## Stack

- **Swift 6 / SwiftUI** — iOS 16+
- **Groq API** (`llama-3.3-70b-versatile`) — génération de prières personnalisées, appelée directement depuis l'app
- **StoreKit 2** — abonnements In-App Purchase
- **Firebase Analytics** — suivi du comportement utilisateur
- **AVKit** — animations mouton en boucle (MP4 silencieux)
- Français / Anglais — toute l'UI, les prières et les notifications sont bilingues
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
    static let groqAPIKey = "VOTRE_CLE_GROQ"
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
| com.louis.Amena.yearly | Auto-renewable | 29,99 €/an | 3 jours |
| com.louis.Amena.weekly | Auto-renewable | 4,99 €/sem | Aucun |

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
amena/
├── AmenaApp.swift
├── ContentView.swift
├── Secrets.swift               ← .gitignore
├── Onboarding/                 ← 18 écrans (langue, intro, questions, mouton, paywall...)
├── Main/                       ← Home, Prayer, Journal, Settings
├── Models/                     ← StreakManager
├── Services/                   ← Groq, StoreKit, Notifications, Analytics, LoopingVideo
├── Extensions/                 ← Color+Theme, Localization (t())
├── Resources/                  ← Vidéos mouton (MP4)
├── Assets.xcassets/            ← Illustrations Midjourney
└── docs/                       ← Privacy Policy + Terms (GitHub Pages)
```
