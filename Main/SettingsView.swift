// Écran paramètres : accessible depuis l'engrenage sur l'accueil
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName = "Friend"
    @AppStorage("sheepName") private var sheepName = "Nour"
    @AppStorage("onboardingCompleted") private var onboardingCompleted = true

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                List {
                    // Profil
                    Section("Profile") {
                        HStack {
                            Text("Name")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            TextField("Your name", text: $userName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.amenaTextSecondary)
                                // @AppStorage se synchronise automatiquement avec UserDefaults
                        }
                        HStack {
                            Text("Companion's name")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            TextField("Sheep name", text: $sheepName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                    }

                    // À propos
                    Section("About") {
                        HStack {
                            Text("Version")
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        Button {
                            // Ouvre les paramètres de notification iOS
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("Notification settings")
                                    .foregroundColor(Color.amenaText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.amenaTextSecondary)
                            }
                        }
                    }

                    // Zone danger
                    Section {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Text("Reset onboarding")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.amenaPrimary)
                        .fontWeight(.semibold)
                }
            }
            .alert("Reset onboarding?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    onboardingCompleted = false
                    dismiss()
                }
            } message: {
                Text("This will restart the app from the beginning.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
