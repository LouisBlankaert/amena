import SwiftUI

struct LanguageView: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var prayerLanguage = "English"

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 56))
                        .foregroundColor(Color.amenaPrimary)
                    Text(t("choose your language", "choisissez votre langue"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .multilineTextAlignment(.center)
                    Text(t("prayers will be generated in this language", "les prières seront générées dans cette langue"))
                        .font(.system(size: 15))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                VStack(spacing: 16) {
                    LanguageButton(
                        flag: "EN",
                        language: "English",
                        isSelected: prayerLanguage == "English"
                    ) { prayerLanguage = "English" }

                    LanguageButton(
                        flag: "FR",
                        language: "Français",
                        isSelected: prayerLanguage == "French"
                    ) { prayerLanguage = "French" }
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: onNext) {
                    Text(t("continue", "continuer"))
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 48)
            }
        }
    }
}

struct LanguageButton: View {
    let flag: String
    let language: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 28))
                Text(language)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color.amenaText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
            .background(isSelected ? Color.amenaPrimary : Color.amenaSecondaryBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.amenaPrimary : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    LanguageView(onNext: {})
}
