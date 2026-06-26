// IntroSlidesView : 3 slides swipeables d'introduction
// Navigation avec bouton circulaire orange → en bas à droite
// Indicateur de slide en haut (3 points, actif = pill orange)

import SwiftUI

struct IntroSlidesView: View {
    let onNext: () -> Void

    @AppStorage("prayerLanguage") private var lang: String = "English"
    @State private var currentSlide = 0

    private var slides: [IntroSlide] {
        [
            IntroSlide(
                highlightedWord: t("God", "Dieu"),
                beforeHighlight: t("your screen is stealing the time you owe to ", "ton écran vole le temps que tu dois à "),
                afterHighlight: ".",
                imageName: "slide1_illustration"
            ),
            IntroSlide(
                highlightedWord: "amena",
                beforeHighlight: "",
                afterHighlight: t(" helps you put God before the scroll.", " t'aide à mettre Dieu avant le scroll."),
                imageName: "slide2_illustration"
            ),
            IntroSlide(
                highlightedWord: t("simple.", "simple."),
                beforeHighlight: t("the idea is ", "l'idée est "),
                afterHighlight: t(" pray first, then unlock your apps.", " prie d'abord, puis débloque tes apps."),
                imageName: "slide3_illustration"
            )
        ]
    }

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Indicateur de progression en haut (3 points)
                SlideIndicator(count: slides.count, current: currentSlide)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                // TabView = swipeable (comme des pages)
                // .page = style "pages" sans les onglets visibles
                TabView(selection: $currentSlide) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        SlideContentView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentSlide)
            }

            // Bouton circulaire orange → en bas à droite
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    // Bouton circulaire pour avancer
                    Button {
                        if currentSlide < slides.count - 1 {
                            withAnimation {
                                currentSlide += 1
                            }
                        } else {
                            onNext() // Dernière slide → passe à l'onboarding
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.amenaPrimary)
                                .frame(width: 64, height: 64)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// Données d'un slide
struct IntroSlide {
    let highlightedWord: String   // Mot en orange
    let beforeHighlight: String   // Texte avant le mot orange
    let afterHighlight: String    // Texte après le mot orange
    let imageName: String         // Nom de l'image dans Assets
}

// Contenu d'un slide (image + titre avec mot en orange)
struct SlideContentView: View {
    let slide: IntroSlide

    var body: some View {
        VStack(spacing: 0) {
            // Illustration pleine largeur, sans carte
            if UIImage(named: slide.imageName) != nil {
                Image(slide.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 80))
                        .foregroundColor(Color.amenaPrimary.opacity(0.5))
                    Text("illustration coming soon")
                        .font(.system(size: 12))
                        .foregroundColor(Color.amenaPrimary.opacity(0.4))
                }
                .frame(height: 300)
            }

            Spacer().frame(height: 32)

            // Titre avec mot mis en valeur en bleu
            (Text(slide.beforeHighlight)
                .foregroundColor(Color.amenaText)
             + Text(slide.highlightedWord)
                .foregroundColor(Color.amenaPrimary)
                .fontWeight(.bold)
             + Text(slide.afterHighlight)
                .foregroundColor(Color.amenaText))
            .font(.system(size: 28, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.bottom, 100)

            Spacer()
        }
        .padding(.top, 8)
    }
}

// Indicateur de slide : 3 points, l'actif devient une pill orange
struct SlideIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.amenaPrimary : Color.amenaUnselectedBackground)
                    // La pill active est plus large
                    .frame(width: index == current ? 24 : 8, height: 8)
                    .animation(.spring(), value: current)
            }
        }
    }
}

#Preview {
    IntroSlidesView(onNext: {})
}
