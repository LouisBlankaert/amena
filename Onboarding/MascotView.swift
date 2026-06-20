// Écran 10 : mascotte mouton
// Carte "trading card" avec nom, niveau, barre FAITH, verset

import SwiftUI

struct MascotView: View {
    @Binding var sheepName: String
    let onNext: () -> Void

    // Verset biblique affiché sur la carte de la mascotte
    private let verse = "\"I am the good shepherd; I know my sheep and my sheep know me.\" — John 10:14"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 9, totalSteps: 9)
                    .padding(.top, 60)

                ScrollView {
                    VStack(spacing: 28) {
                        // Illustration mouton (SF Symbol)
                        ZStack {
                            // Fond sombre représentant l'obscurité/addiction
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#1a1a2e"))
                                .frame(height: 200)
                            VStack(spacing: 8) {
                                CuteSheepView()
                                Text("your companion is chained to the phone...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Champ de nom
                        VStack(alignment: .leading, spacing: 10) {
                            Text("your sheep's name")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.amenaText)

                            TextField("Nour", text: $sheepName)
                                .font(.system(size: 17))
                                .padding(16)
                                .background(Color.amenaSecondaryBackground)
                                .cornerRadius(12)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                        }
                        .padding(.horizontal, 24)

                        // Carte style "trading card"
                        SheepTradingCard(name: sheepName.isEmpty ? "Nour" : sheepName, verse: verse)
                            .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }

                Button {
                    let name = sheepName.isEmpty ? "Nour" : sheepName
                    UserDefaults.standard.set(name, forKey: "sheepName")
                    sheepName = name
                    onNext()
                } label: {
                    Text("let's go →")
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// Carte trading card du mouton
struct SheepTradingCard: View {
    let name: String
    let verse: String

    // Niveau FAITH calculé (commence à 2 dans l'onboarding)
    private let faithLevel = 2
    private let faithPercent = 0.15   // 15% de progression

    var body: some View {
        VStack(spacing: 0) {
            // En-tête de la carte : nom + niveau
            HStack {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("lv \(faithLevel)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.amenaPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Illustration mouton au centre (niveau 2 sur la trading card)
            CuteSheepView(level: 2)
                .padding(.vertical, 8)

            // Barre FAITH
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("FAITH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(faithPercent * 100))%")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                // Barre de progression FAITH
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.amenaPrimary)
                            .frame(width: geo.size.width * faithPercent, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)

            // Verset biblique en bas
            Text(verse)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#1a1a4e"), Color(hex: "#2d2d7e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        // Bordure orange subtile
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.amenaPrimary.opacity(0.5), lineWidth: 1.5)
        )
    }
}

// Mouton qui évolue selon le niveau (1 = bébé agneau, 10 = mouton doré majestueux)
struct CuteSheepView: View {
    var level: Int = 1

    // Propriétés visuelles selon le niveau
    private var bodySize: CGFloat {
        switch level {
        case 1:     return 32   // tout petit bébé
        case 2:     return 40
        case 3:     return 48
        case 4:     return 54
        case 5:     return 60
        case 6:     return 66
        case 7:     return 70
        case 8:     return 74
        case 9:     return 78
        default:    return 84   // majestueux
        }
    }

    private var headSize: CGFloat  { bodySize * 0.38 }
    private var legHeight: CGFloat { max(10, bodySize * 0.22) }
    private var legWidth: CGFloat  { max(5, bodySize * 0.10) }

    // Couleur du corps : blanc → ivoire → doré selon le niveau
    private var woolColor: Color {
        switch level {
        case 1, 2: return Color.white.opacity(0.9)
        case 3, 4: return Color(hex: "#f8f8f0")
        case 5, 6: return Color(hex: "#f5f0e0")
        case 7, 8: return Color(hex: "#f0e8c0")
        case 9:    return Color(hex: "#eedfa0")
        default:   return Color(hex: "#ffd700")  // doré niveau 10
        }
    }

    private var skinColor: Color { Color(hex: "#e8d0b0") }

    // Accessoire selon le niveau
    @ViewBuilder
    private var accessory: some View {
        if level >= 10 {
            // Couronne dorée
            Image(systemName: "crown.fill")
                .font(.system(size: bodySize * 0.3))
                .foregroundColor(Color(hex: "#FFD700"))
                .offset(x: bodySize * 0.38, y: -bodySize * 0.55)
        } else if level >= 7 {
            // Étoile
            Image(systemName: "star.fill")
                .font(.system(size: bodySize * 0.22))
                .foregroundColor(Color(hex: "#FFD700"))
                .offset(x: bodySize * 0.38, y: -bodySize * 0.52)
        } else if level >= 4 {
            // Petite fleur
            Image(systemName: "sparkle")
                .font(.system(size: bodySize * 0.18))
                .foregroundColor(Color.amenaPrimary.opacity(0.8))
                .offset(x: bodySize * 0.36, y: -bodySize * 0.5)
        }
    }

    var body: some View {
        ZStack {
            // Corps (toison)
            Image(systemName: "cloud.fill")
                .font(.system(size: bodySize))
                .foregroundColor(woolColor)
                .shadow(color: level >= 9 ? Color(hex: "#FFD700").opacity(0.5) : .clear,
                        radius: 8)

            // Tête
            Circle()
                .fill(skinColor)
                .frame(width: headSize, height: headSize)
                .offset(x: bodySize * 0.43, y: -bodySize * 0.14)

            // Oeil
            Circle()
                .fill(Color(hex: "#333333"))
                .frame(width: max(3, headSize * 0.18), height: max(3, headSize * 0.18))
                .offset(x: bodySize * 0.37, y: -bodySize * 0.18)

            // Oreille
            Ellipse()
                .fill(Color(hex: "#d4b896"))
                .frame(width: headSize * 0.45, height: headSize * 0.3)
                .offset(x: bodySize * 0.52, y: -bodySize * 0.28)

            // Accessoire selon niveau
            accessory

            // Pattes (apparaissent à partir du niveau 2)
            if level >= 2 {
                HStack(spacing: legWidth * 1.2) {
                    ForEach(0..<(level >= 4 ? 4 : 2), id: \.self) { _ in
                        Capsule()
                            .fill(skinColor)
                            .frame(width: legWidth, height: legHeight)
                    }
                }
                .offset(y: bodySize * 0.48)
            }
        }
        .frame(width: bodySize * 1.8, height: bodySize * 1.4)
    }
}

// Label de niveau affiché sous le mouton
struct SheepLevelLabel: View {
    let level: Int
    private var labelText: String {
        switch level {
        case 1:  return "newborn lamb"
        case 2:  return "tiny lamb"
        case 3:  return "young sheep"
        case 4:  return "small sheep"
        case 5:  return "growing sheep"
        case 6:  return "adult sheep"
        case 7:  return "wise sheep"
        case 8:  return "elder sheep"
        case 9:  return "sacred sheep"
        default: return "divine sheep"
        }
    }
    var body: some View {
        Text(labelText)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
    }
}

#Preview {
    MascotView(sheepName: .constant("Nour"), onNext: {})
}
