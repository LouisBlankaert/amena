# Amena — Christian Prayer App

> "Les réseaux sociaux t'éloignent de Dieu. Bloque ton téléphone jusqu'à ce que tu pries."

Application iOS de prière chrétienne inspirée de PrayerLock.

## Stack

- **Swift 6 / SwiftUI** — iOS 16+
- **Groq API** (`llama-3.3-70b-versatile`) — génération de prières personnalisées, appelée directement depuis l'app
- **RevenueCat** — abonnements In-App Purchase (au-dessus de StoreKit 2)
- Code de parrainage manuel (champ texte sur le paywall) — attribution du revenu créateur via RevenueCat
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

    // dashboard.revenuecat.com → Project Settings → API Keys → Apple App Store
    // (clé test_ acceptée pour développer sans App Store Connect connecté)
    static let revenueCatAPIKey = "VOTRE_CLE_REVENUECAT"

    // Code de l'accès créateur (7 taps sur la version dans Réglages)
    static let founderCode = "VOTRE_CODE_SECRET"
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
xcodebuild -scheme Amena -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Produits IAP (App Store Connect)

| ID | Type | Prix | Essai |
|----|------|------|-------|
| com.louis.Amena.yearly | Auto-renewable | 29,99 €/an | 3 jours |
| com.louis.Amena.weekly | Auto-renewable | 4,99 €/sem | Aucun |

⚠️ **RevenueCat a besoin de 2 clés API distinctes** (App Store Connect → Users and Access → Integrations) :
- **In-App Purchase key** (section "In-App Purchase") → vérification transactions/entitlements. Sans elle, statut produit RevenueCat bloqué sur "Could not check".
- **App Store Connect API key** (section "App Store Connect API") → import produits / sync prix.

Les deux sont uploadées séparément dans RevenueCat → Apps → (ton app) → deux sections distinctes du même nom.

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
├── Services/                   ← Groq, RevenueCat, Affiliate (parrainage), Keychain (accès créateur), Notifications, Analytics, LoopingVideo
├── Extensions/                 ← Color+Theme, Localization (t())
├── Resources/                  ← Vidéos mouton (MP4)
├── Assets.xcassets/            ← Illustrations Midjourney
└── docs/                       ← Privacy Policy + Terms (GitHub Pages)
```
