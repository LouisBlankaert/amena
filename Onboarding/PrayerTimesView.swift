// Écran 14 : configuration des heures de prière
// Liste 3 horaires par défaut modifiables, toggle ON/OFF, bouton "+ add"

import SwiftUI

// Modèle d'une heure de prière
struct PrayerTimeItem: Identifiable {
    let id = UUID()
    var name: String       // "Morning Prayer", "Afternoon Prayer", etc.
    var time: Date
    var isEnabled: Bool
}

struct PrayerTimesView: View {
    let onNext: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    @State private var prayerTimes: [PrayerTimeItem] = [
        PrayerTimeItem(name: "Morning Prayer", time: makeTime(hour: 7, minute: 0), isEnabled: true),
        PrayerTimeItem(name: "Afternoon Prayer", time: makeTime(hour: 12, minute: 0), isEnabled: true),
        PrayerTimeItem(name: "Evening Prayer", time: makeTime(hour: 21, minute: 0), isEnabled: true)
    ]

    @State private var editingIndex: Int? = nil

    var body: some View {
        ZStack {
            Color.amenaBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // En-tête
                VStack(spacing: 8) {
                    Text(t("set your prayer times", "définissez vos heures de prière"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.amenaText)
                        .padding(.top, 60)

                    Text(t("your apps will lock at these times until you pray.", "vos apps se bloqueront à ces horaires jusqu'à ce que vous priiez."))
                        .font(.system(size: 15))
                        .foregroundColor(Color.amenaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 13))
                        Text(t("tap any time to edit it", "appuyez sur un horaire pour le modifier"))
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Color.amenaPrimary)
                }
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 12) {
                        // Liste des horaires
                        ForEach(Array(prayerTimes.enumerated()), id: \.element.id) { index, item in
                            PrayerTimeRow(
                                item: $prayerTimes[index],
                                isEditing: editingIndex == index,
                                onTap: {
                                    withAnimation {
                                        editingIndex = editingIndex == index ? nil : index
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 24)

                        // Bouton ajouter une heure
                        Button {
                            let newTime = makeTime(hour: 8, minute: 0)
                            prayerTimes.append(PrayerTimeItem(
                                name: "Prayer \(prayerTimes.count + 1)",
                                time: newTime,
                                isEnabled: true
                            ))
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(t("+ add prayer time", "+ ajouter une heure de prière"))
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.amenaPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.amenaSecondaryBackground)
                            .cornerRadius(14)
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }

                // Bouton "continue →"
                Button {
                    savePrayerTimes()
                    onNext()
                } label: {
                    Text(t("continue →", "continuer →"))
                        .amenaPrimaryButton()
                }
                .padding(.bottom, 48)
            }
        }
    }

    // Sauvegarde les horaires activés dans UserDefaults
    private func savePrayerTimes() {
        let enabledTimes = prayerTimes.filter(\.isEnabled).map(\.time)
        let timesData = try? JSONEncoder().encode(enabledTimes)
        UserDefaults.standard.set(timesData, forKey: "prayerTimes")
    }
}

// Ligne d'un horaire de prière
struct PrayerTimeRow: View {
    @Binding var item: PrayerTimeItem
    let isEditing: Bool
    let onTap: () -> Void
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Ligne principale
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.amenaText)
                    Text(t("every day", "chaque jour"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.amenaTextSecondary)
                }

                Spacer()

                // Heure affichée en orange si activé
                Text(timeFormatter.string(from: item.time))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(item.isEnabled ? Color.amenaPrimary : Color.amenaTextSecondary)

                // Toggle ON/OFF
                Toggle("", isOn: $item.isEnabled)
                    .tint(Color.amenaPrimary)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle()) // Toute la zone est tappable
            .onTapGesture(perform: onTap)

            // DatePicker affiché en bas de la ligne si on tape dessus
            if isEditing {
                DatePicker(
                    "Select time",
                    selection: $item.time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(14)
    }
}

// Helper pour créer une Date à une heure précise
private func makeTime(hour: Int, minute: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
}

#Preview {
    PrayerTimesView(onNext: {})
}
