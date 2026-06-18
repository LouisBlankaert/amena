// IntroSlidesView : 3 slides swipeables d'introduction
// Navigation avec bouton circulaire orange → en bas à droite
// Indicateur de slide en haut (3 points, actif = pill orange)

import SwiftUI

struct IntroSlidesView: View {
    let onNext: () -> Void

    // @State = variable locale qui, quand elle change, refait l'affichage
    @State private var currentSlide = 0

    // Les données de chaque slide
    private let slides: [IntroSlide] = [
        IntroSlide(
            highlightedWord: "God.",
            beforeHighlight: "social media addiction is taking you away from ",
            afterHighlight: "",
            imageName: "slide1_illustration"
        ),
        IntroSlide(
            highlightedWord: "amena",
            beforeHighlight: "",
            afterHighlight: " can help you choose God first daily.",
            imageName: "slide2_illustration"
        ),
        IntroSlide(
            highlightedWord: "simple.",
            beforeHighlight: "it's ",
            afterHighlight: " once a day, we block your apps",
            imageName: "slide3_illustration"
        )
    ]

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
                    // Lien "signed in via web?" en bas à gauche
                    Button("signed in via web? sign in") {
                        // Pas de compte dans le MVP
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color.amenaPrimary)
                    .padding(.leading, 24)

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
        VStack(spacing: 32) {
            // Illustration (image depuis Assets ou placeholder SF Symbol)
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.amenaOrangePale)
                    .frame(height: 340)
                // SF Symbol comme placeholder jusqu'à avoir les vraies illustrations
                Image(systemName: "figure.stand")
                    .font(.system(size: 80))
                    .foregroundColor(Color.amenaPrimary.opacity(0.6))
            }
            .padding(.horizontal, 24)

            // Titre avec mot mis en valeur en orange
            // Text concatenation avec + pour mélanger les styles
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

            Spacer()
        }
        .padding(.top, 16)
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
