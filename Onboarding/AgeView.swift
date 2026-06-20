// Écran 2 : sélection de la tranche d'âge
// 5 boutons sélectionnables, un seul à la fois (style "radio button")

import SwiftUI

struct AgeView: View {
    @Binding var selectedAge: String
    let onNext: () -> Void

    // Les 5 tranches d'âge disponibles
    private let ageRanges = ["14-24", "25-34", "35-44", "45-54", "55+"]

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 2, totalSteps: 9)
                    .padding(.top, 60)

                VStack(spacing: 32) {
                    Text("how old are you?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)

                    // Boutons de sélection d'âge
                    VStack(spacing: 12) {
                        ForEach(ageRanges, id: \.self) { range in
                            AgeOptionButton(
                                label: range,
                                isSelected: selectedAge == range
                            ) {
                                selectedAge = range
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }

                Button {
                    UserDefaults.standard.set(selectedAge, forKey: "userAge")
                    onNext()
                } label: {
                    Text("continue")
                        .amenaPrimaryButton()
                }
                .disabled(selectedAge.isEmpty)
                .opacity(selectedAge.isEmpty ? 0.5 : 1.0)
                .padding(.bottom, 48)
            }
        }
    }
}

// Bouton d'option d'âge : fond orange si sélectionné, gris sinon
struct AgeOptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    // Texte blanc si sélectionné, noir sinon
                    .foregroundColor(isSelected ? .white : Color.amenaText)
                Spacer()
                // Checkmark visible uniquement si sélectionné
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(isSelected ? Color.amenaPrimary : Color.amenaSecondaryBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.amenaPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain) // Évite le style par défaut de SwiftUI sur les boutons
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    AgeView(selectedAge: .constant("25-34"), onNext: {})
}
