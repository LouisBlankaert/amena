// Écran 1 de la Partie 2 : saisie du prénom
// Affiche une grille 90 jours en aperçu avec le nom de l'utilisateur

import SwiftUI

struct UserNameView: View {
    @Binding var userName: String
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Barre de progression (étape 1 sur 9 questions)
                OnboardingProgressBar(currentStep: 1, totalSteps: 9)
                    .padding(.top, 60)

                ScrollView {
                    VStack(spacing: 32) {
                        // Titre avec "new" en orange
                        (Text(t("ready to build a habit that actually ", "prêt à construire une habitude qui vous "))
                            .foregroundColor(Color.amenaText)
                         + Text(t("changes you?", "change vraiment ?"))
                            .foregroundColor(Color.amenaPrimary)
                            .fontWeight(.bold))
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                        // Aperçu grille 90 jours
                        NinetyDayGridPreview(userName: userName)
                            .padding(.horizontal, 24)

                        // Question + champ de saisie
                        VStack(alignment: .leading, spacing: 12) {
                            Text(t("what should we call you?", "comment vous appelez-vous ?"))
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.amenaText)

                            TextField(t("enter your name", "entrez votre prénom"), text: $userName)
                                .font(.system(size: 17))
                                .padding(16)
                                .background(Color.amenaSecondaryBackground)
                                .cornerRadius(12)
                                .autocorrectionDisabled()
                                // Majuscule sur la première lettre
                                .textInputAutocapitalization(.words)
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 120)
                    }
                }

                // Bouton "continue" fixé en bas
                Button {
                    UserDefaults.standard.set(userName, forKey: "userName")
                    onNext()
                } label: {
                    Text(t("continue", "continuer"))
                        .amenaPrimaryButton()
                }
                // Désactivé si le nom est vide
                .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                .padding(.bottom, 48)
            }
        }
    }
}

// Aperçu visuel : grille 90 cases (9 colonnes × 10 rangées)
struct NinetyDayGridPreview: View {
    let userName: String

    // Colonnes : 9 cases de taille égale avec espacement
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 9)

    var body: some View {
        VStack(spacing: 8) {
            // En-tête de la carte
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("30 day prayer journey", "parcours prière 30 jours"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    Text(t("0% Complete", "0% Terminé"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date(), style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                    Text(userName.isEmpty ? t("Your name", "Votre prénom") : userName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.amenaPrimary)
                }
            }

            // Grille 90 cases
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<30, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.amenaUnselectedBackground)
                        .frame(height: 16)
                }
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
    }
}

#Preview {
    UserNameView(userName: .constant("Louis"), onNext: {})
}
