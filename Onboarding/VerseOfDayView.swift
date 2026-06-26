// Écran 13 : verset du jour
// Fond dégradé bleu nuit → bleu ciel, carte blanche avec verset

import SwiftUI

struct VerseOfDayView: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var verses: [(text: String, reference: String)] {
        [
            (t("For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", "Car je connais les projets que j'ai formés sur vous, dit l'Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l'espérance."), t("Jeremiah 29:11", "Jérémie 29:11")),
            (t("Trust in the Lord with all your heart and lean not on your own understanding.", "Confie-toi en l'Éternel de tout ton cœur, et ne t'appuie pas sur ta sagesse."), t("Proverbs 3:5", "Proverbes 3:5")),
            (t("I can do all this through him who gives me strength.", "Je puis tout par celui qui me fortifie."), t("Philippians 4:13", "Philippiens 4:13")),
            (t("The Lord is my shepherd, I lack nothing.", "L'Éternel est mon berger : je ne manquerai de rien."), t("Psalm 23:1", "Psaume 23:1")),
            (t("Be still, and know that I am God.", "Arrêtez, et sachez que je suis Dieu."), t("Psalm 46:10", "Psaume 46:10")),
            (t("Come to me, all you who are weary and burdened, and I will give you rest.", "Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos."), t("Matthew 11:28", "Matthieu 11:28")),
            (t("For God so loved the world that he gave his one and only Son.", "Car Dieu a tant aimé le monde qu'il a donné son Fils unique."), t("John 3:16", "Jean 3:16")),
            (t("The Lord is my light and my salvation — whom shall I fear?", "L'Éternel est ma lumière et mon salut — de qui aurais-je crainte ?"), t("Psalm 27:1", "Psaume 27:1")),
            (t("But those who hope in the Lord will renew their strength.", "Mais ceux qui se confient en l'Éternel renouvellent leur force."), t("Isaiah 40:31", "Ésaïe 40:31")),
            (t("Do not be anxious about anything, but in every situation, by prayer and petition, present your requests to God.", "Ne vous inquiétez de rien, mais en toute chose faites connaître vos besoins à Dieu par des prières et des supplications."), t("Philippians 4:6", "Philippiens 4:6")),
            (t("Love the Lord your God with all your heart and with all your soul and with all your mind.", "Tu aimeras le Seigneur ton Dieu de tout ton cœur, de toute ton âme et de tout ton esprit."), t("Matthew 22:37", "Matthieu 22:37")),
            (t("For by grace you have been saved through faith.", "C'est par la grâce que vous êtes sauvés, par le moyen de la foi."), t("Ephesians 2:8", "Éphésiens 2:8")),
            (t("The name of the Lord is a fortified tower; the righteous run to it and are safe.", "Le nom de l'Éternel est une tour forte ; le juste s'y réfugie et se trouve en sécurité."), t("Proverbs 18:10", "Proverbes 18:10")),
            (t("I will praise you, Lord, with all my heart.", "Je te louerai, Seigneur, de tout mon cœur."), t("Psalm 9:1", "Psaume 9:1")),
            (t("Your word is a lamp for my feet, a light on my path.", "Ta parole est une lampe à mes pieds, et une lumière sur mon sentier."), t("Psalm 119:105", "Psaume 119:105")),
            (t("Let everything that has breath praise the Lord.", "Que tout ce qui respire loue l'Éternel !"), t("Psalm 150:6", "Psaume 150:6")),
            (t("And we know that in all things God works for the good of those who love him.", "Nous savons, du reste, que toutes choses concourent au bien de ceux qui aiment Dieu."), t("Romans 8:28", "Romains 8:28")),
            (t("Cast all your anxiety on him because he cares for you.", "Déchargez-vous sur lui de tous vos soucis, car lui-même prend soin de vous."), t("1 Peter 5:7", "1 Pierre 5:7")),
            (t("Seek first his kingdom and his righteousness, and all these things will be given to you.", "Cherchez premièrement le royaume et la justice de Dieu ; et toutes ces choses vous seront données par-dessus."), t("Matthew 6:33", "Matthieu 6:33")),
            (t("I am the way and the truth and the life.", "Je suis le chemin, la vérité, et la vie."), t("John 14:6", "Jean 14:6")),
            (t("Create in me a pure heart, O God.", "Crée en moi un cœur pur, ô Dieu !"), t("Psalm 51:10", "Psaume 51:10")),
            (t("The Lord bless you and keep you.", "Que l'Éternel te bénisse et te garde !"), t("Numbers 6:24", "Nombres 6:24")),
            (t("Rejoice in the Lord always. I will say it again: Rejoice!", "Réjouissez-vous toujours dans le Seigneur ! Je le répète : réjouissez-vous !"), t("Philippians 4:4", "Philippiens 4:4")),
            (t("He restores my soul.", "Il restaure mon âme."), t("Psalm 23:3", "Psaume 23:3")),
            (t("Jesus Christ is the same yesterday and today and forever.", "Jésus-Christ est le même hier, aujourd'hui, et éternellement."), t("Hebrews 13:8", "Hébreux 13:8")),
            (t("Ask and it will be given to you; seek and you will find.", "Demandez, et l'on vous donnera ; cherchez, et vous trouverez."), t("Matthew 7:7", "Matthieu 7:7")),
            (t("The peace of God, which transcends all understanding, will guard your hearts.", "La paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs."), t("Philippians 4:7", "Philippiens 4:7")),
            (t("Even though I walk through the darkest valley, I will fear no evil, for you are with me.", "Même si je marche dans la vallée de l'ombre de la mort, je ne crains aucun mal, car tu es avec moi."), t("Psalm 23:4", "Psaume 23:4")),
            (t("God is our refuge and strength, an ever-present help in trouble.", "Dieu est pour nous un refuge et un appui, un secours qui ne manque jamais dans la détresse."), t("Psalm 46:1", "Psaume 46:1")),
            (t("For nothing will be impossible with God.", "Car rien n'est impossible à Dieu."), t("Luke 1:37", "Luc 1:37")),
            (t("Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you.", "Fortifie-toi et prends courage ! Ne te trouble pas et ne t'effraie pas, car l'Éternel, ton Dieu, est avec toi."), t("Joshua 1:9", "Josué 1:9"))
        ]
    }

    private var todayVerse: (text: String, reference: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return verses[dayOfYear % verses.count]
    }

    var body: some View {
        ZStack {
            // Fond dégradé bleu nuit → bleu ciel
            LinearGradient(
                colors: [Color.amenaNightBlue, Color.amenaSkyBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Label "VERSE OF THE DAY" en small caps
                Text(t("VERSE OF THE DAY", "VERSET DU JOUR"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(2) // Espacement entre les lettres

                // Carte blanche avec le verset
                VStack(spacing: 16) {
                    Text(todayVerse.text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    Text(todayVerse.reference)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.amenaPrimary)

                    // Bouton partage centré sous la référence
                    Button {
                        shareVerse()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                            Text(t("share", "partager"))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color.amenaTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.amenaSecondaryBackground)
                        .cornerRadius(20)
                    }
                }
                .padding(28)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 24)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)

                Spacer()

                // Bouton blanc avec texte orange
                Button {
                    onNext()
                } label: {
                    Text(t("continue", "continuer"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.amenaPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func shareVerse() {
        let text = "\(todayVerse.text)\n— \(todayVerse.reference)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    VerseOfDayView(onNext: {})
}
