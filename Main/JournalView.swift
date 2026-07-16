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
                        // Historique complet façon GitHub — ne se réinitialise jamais
                        PrayerContributionGrid(prayers: prayers)
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

// Historique de prière façon GitHub : une colonne par semaine, une case par jour,
// remplie si l'utilisateur a prié ce jour-là. Contrairement à FullNinetyDayGrid,
// ne se réinitialise jamais — basé directement sur les dates réelles du journal.
struct PrayerContributionGrid: View {
    let prayers: [PrayerEntry]
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private let weeksToShow = 12

    // Jours distincts où au moins une prière a été faite
    private var prayedDates: Set<Date> {
        Set(prayers.map { Calendar.current.startOfDay(for: $0.date) })
    }

    // Grille alignée sur les semaines (dimanche → samedi), la plus récente à droite
    private var weeks: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today) // 1 = dimanche
        guard let startOfThisWeek = calendar.date(byAdding: .day, value: -(todayWeekday - 1), to: today),
              let firstWeekStart = calendar.date(byAdding: .day, value: -7 * (weeksToShow - 1), to: startOfThisWeek) else {
            return []
        }

        return (0..<weeksToShow).map { w in
            (0..<7).compactMap { d in
                calendar.date(byAdding: .day, value: w * 7 + d, to: firstWeekStart)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t("Prayer History", "Historique de prière"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.amenaText)
                Spacer()
                Text(t("\(prayedDates.count) days prayed", "\(prayedDates.count) jours priés"))
                    .font(.system(size: 13))
                    .foregroundColor(Color.amenaTextSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(weeks.indices, id: \.self) { w in
                        VStack(spacing: 4) {
                            ForEach(weeks[w], id: \.self) { day in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(cellColor(for: day))
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.amenaSecondaryBackground)
        .cornerRadius(16)
    }

    private func cellColor(for day: Date) -> Color {
        // Jours futurs (fin de la semaine en cours) — case invisible
        guard day <= Calendar.current.startOfDay(for: Date()) else { return .clear }
        return prayedDates.contains(day) ? Color.amenaPrimary : Color.amenaUnselectedBackground
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
