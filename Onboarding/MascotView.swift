// Écran 10 : mascotte mouton
// Carte "trading card" avec nom, niveau, barre FAITH, verset

import SwiftUI
import AVKit

struct MascotView: View {
    @Binding var sheepName: String
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private let verse = "\"I am the good shepherd; I know my sheep and my sheep know me.\" — John 10:14"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 9, totalSteps: 9)
                    .padding(.top, 60)

                ScrollView {
                    VStack(spacing: 28) {
                        // Accroche au-dessus des cartes
                        VStack(spacing: 6) {
                            Text(t("break the chains.", "brisez les chaînes."))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color.amenaText)
                            Text(t("pray daily. evolve your sheep.", "priez chaque jour. faites évoluer votre mouton."))
                                .font(.system(size: 14))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Mouton lv1 — vidéo en boucle, triste, enchaîné au téléphone
                        ZStack(alignment: .bottom) {
                            if let url = Bundle.main.url(forResource: "sheep_lv1", withExtension: "mp4") {
                                LoopingVideoView(url: url)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                Image("sheep_lv1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            LinearGradient(
                                colors: [.clear, Color(hex: "#1a1a2e").opacity(0.85)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            // Label lv1 en bas à droite (même style que lv5)
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("lv 1")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.amenaPrimary)
                                        .cornerRadius(6)
                                }
                                .padding(12)
                            }
                            Text(t("your companion is chained to the phone...", "ton compagnon est enchaîné au téléphone..."))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.bottom, 14)
                        }
                        .frame(height: 200)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Champ de nom
                        VStack(alignment: .leading, spacing: 10) {
                            Text(t("your sheep's name", "le nom de votre mouton"))
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
                    Text(t("let's go →", "c'est parti →"))
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// Carte trading card — vidéo lv5 en plein fond, infos en bas
struct SheepTradingCard: View {
    let name: String
    let verse: String

    private let faithPercent = 0.15

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fond bleu profond
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color(hex: "#1a1a4e"), Color(hex: "#2d2d7e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            // Vidéo lv5 en plein fond (montre l'évolution possible)
            if let url = Bundle.main.url(forResource: "sheep_lv5", withExtension: "mp4") {
                LoopingVideoView(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Image("sheep_lv5")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            // Gradient bas pour lisibilité du texte
            LinearGradient(
                colors: [.clear, Color(hex: "#1a1a4e").opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Infos en bas
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("lv 5")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.amenaPrimary)
                        .cornerRadius(6)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.amenaPrimary)
                            .frame(width: geo.size.width * faithPercent, height: 5)
                    }
                }
                .frame(height: 5)

                Text(verse)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.amenaPrimary.opacity(0.4), lineWidth: 1.5)
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
