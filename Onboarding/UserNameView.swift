// Écran 1 de la Partie 2 : saisie du prénom
// Affiche une grille 90 jours en aperçu avec le nom de l'utilisateur

import SwiftUI

struct UserNameView: View {
    @Binding var userName: String   // Binding = variable partagée avec le parent
    let onNext: () -> Void

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
                        (Text("ready to build a habit that actually ")
                            .foregroundColor(Color.amenaText)
                         + Text("changes you?")
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
                            Text("what should we call you?")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.amenaText)

                            // TextField = champ de texte SwiftUI
                            TextField("enter your name", text: $userName)
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
                    Text("continue")
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
                    Text("30 day prayer journey")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.amenaText)
                    Text("0% Complete")
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date(), style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(Color.amenaTextSecondary)
                    Text(userName.isEmpty ? "Your name" : userName)
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
