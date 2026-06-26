// Vue Journal : historique des prières et grille 90 jours complète
// Accessible via une tab bar depuis HomeView (future v2) ou navigation

import SwiftUI

struct JournalView: View {
    @State private var prayers: [PrayerEntry] = []
    @State private var displayedCount = 10
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var visiblePrayers: [PrayerEntry] { Array(prayers.prefix(displayedCount)) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Grille 30 jours
                        FullNinetyDayGrid(prayedCount: prayers.count)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Titre historique
                        HStack {
                            Text(t("Your Prayers", "Vos prières"))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text(t("\(prayers.count) total", "\(prayers.count) au total"))
                                .font(.system(size: 14))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        .padding(.horizontal, 24)

                        if prayers.isEmpty {
                            EmptyJournalView()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(visiblePrayers) { prayer in
                                    JournalPrayerCard(prayer: prayer)
                                        .padding(.horizontal, 24)
                                }
                            }

                            // Bouton "voir plus" si il reste des prières
                            if displayedCount < prayers.count {
                                Button {
                                    displayedCount = min(displayedCount + 10, prayers.count)
                                } label: {
                                    Text(t("load more (\(prayers.count - displayedCount) remaining)", "voir plus (\(prayers.count - displayedCount) restantes)"))
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.amenaPrimary)
                                        .padding(.vertical, 12)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(t("Journal", "Journal"))
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear(perform: loadPrayers)
    }

    private func loadPrayers() {
        if let data = UserDefaults.standard.data(forKey: "prayerJournal"),
           let decoded = try? JSONDecoder().decode([PrayerEntry].self, from: data) {
            // Limite à 90 entrées max — supprime les plus anciennes
            prayers = Array(decoded.prefix(90))
            if decoded.count > 90 {
                if let encoded = try? JSONEncoder().encode(prayers) {
                    UserDefaults.standard.set(encoded, forKey: "prayerJournal")
                }
            }
        }
    }
}

// Modèle d'une entrée de prière dans le journal
struct PrayerEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date

    // Extrait les premiers mots comme résumé
    var preview: String {
        let words = text.split(separator: " ").prefix(15)
        return words.joined(separator: " ") + (text.split(separator: " ").count > 15 ? "..." : "")
    }

    // Extrait la référence biblique — dernière ligne commençant par "— "
    var biblicalReference: String? {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.last(where: { $0.hasPrefix("—") || $0.hasPrefix("–") })
    }

    // Thème = heure de la prière convertie en label lisible
    var timeLabel: String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<12: return t("Morning Prayer", "Prière du matin")
        case 12..<17: return t("Afternoon Prayer", "Prière de l'après-midi")
        default: return t("Evening Prayer", "Prière du soir")
        }
    }
}

// Grille complète 90 jours avec légende
struct FullNinetyDayGrid: View {
    let prayedCount: Int
    @AppStorage("prayedDays") private var prayedDaysData: Data = Data()
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var prayedDays: Set<Int> {
        (try? JSONDecoder().decode(Set<Int>.self, from: prayedDaysData)) ?? []
    }

    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 9)

    init(prayedCount: Int) {
        self.prayedCount = prayedCount
    }

    var body: some View {
        let percent = min(Double(prayedDays.count) / 30.0, 1.0)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t("30 Day Journey", "Parcours 30 jours"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.amenaText)
                Spacer()
                Text(t("\(Int(percent * 100))% Complete", "\(Int(percent * 100))% Terminé"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.amenaPrimary)
            }

            // Barre de progression globale
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.amenaUnselectedBackground)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.amenaPrimary)
                        .frame(width: geo.size.width * percent, height: 8)
                }
            }
            .frame(height: 8)

            // Grille 90 cases
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<30, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(prayedDays.contains(day) ? Color.amenaPrimary : Color.amenaUnselectedBackground)
                        .frame(height: 20)
                }
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
    }
}

// Carte d'une prière dans le journal
struct JournalPrayerCard: View {
    let prayer: PrayerEntry

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // En-tête : thème + date
            HStack {
                Text(prayer.timeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.amenaPrimary)
                    .cornerRadius(8)
                Spacer()
                Text(dateFormatter.string(from: prayer.date))
                    .font(.system(size: 12))
                    .foregroundColor(Color.amenaTextSecondary)
            }

            // Aperçu du texte
            Text(prayer.preview)
                .font(.system(size: 15))
                .foregroundColor(Color.amenaText)
                .lineSpacing(4)

            // Référence biblique si disponible
            if let ref = prayer.biblicalReference {
                Text(ref)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(Color.amenaPrimary)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.amenaPrimary.opacity(0.15), lineWidth: 1)
        )
    }
}

// Vue vide quand aucune prière n'a été faite
struct EmptyJournalView: View {
    @AppStorage("prayerLanguage") private var lang: String = "English"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.amenaPrimary.opacity(0.4))
            Text(t("Your prayer journey starts here", "Votre parcours de prière commence ici"))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.amenaText)
            Text(t("Your daily prayers will appear here.\nStart praying to fill your journal!", "Vos prières quotidiennes apparaîtront ici.\nCommencez à prier pour remplir votre journal !"))
                .font(.system(size: 14))
                .foregroundColor(Color.amenaTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    JournalView()
}
