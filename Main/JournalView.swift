// Vue Journal : historique des prières et grille 90 jours complète
// Accessible via une tab bar depuis HomeView (future v2) ou navigation

import SwiftUI

struct JournalView: View {
    // Prières chargées depuis UserDefaults (SwiftData sera ajouté en étape 9)
    @State private var prayers: [PrayerEntry] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.amenaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Grille 90 jours
                        FullNinetyDayGrid(prayedCount: prayers.count)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Titre historique
                        HStack {
                            Text("Your Prayers")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color.amenaText)
                            Spacer()
                            Text("\(prayers.count) total")
                                .font(.system(size: 14))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        .padding(.horizontal, 24)

                        if prayers.isEmpty {
                            EmptyJournalView()
                        } else {
                            // Liste des prières
                            LazyVStack(spacing: 12) {
                                ForEach(prayers) { prayer in
                                    JournalPrayerCard(prayer: prayer)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear(perform: loadPrayers)
        .onReceive(NotificationCenter.default.publisher(for: .prayerCompleted)) { notification in
            if let text = notification.userInfo?["prayerText"] as? String,
               let date = notification.userInfo?["date"] as? Date {
                let entry = PrayerEntry(id: UUID(), text: text, date: date)
                prayers.insert(entry, at: 0)
                savePrayers()
            }
        }
    }

    // Charge les prières depuis UserDefaults
    private func loadPrayers() {
        if let data = UserDefaults.standard.data(forKey: "prayerJournal"),
           let decoded = try? JSONDecoder().decode([PrayerEntry].self, from: data) {
            prayers = decoded
        }
    }

    // Sauvegarde dans UserDefaults (SwiftData en étape 9)
    private func savePrayers() {
        if let encoded = try? JSONEncoder().encode(prayers) {
            UserDefaults.standard.set(encoded, forKey: "prayerJournal")
        }
        // Met aussi à jour les jours priés pour la grille
        updatePrayedDays()
    }

    private func updatePrayedDays() {
        let calendar = Calendar.current
        let prayedDayNumbers = prayers.map { prayer -> Int in
            let start = calendar.startOfDay(for: calendar.date(from: DateComponents(year: calendar.component(.year, from: Date()), month: 1, day: 1)) ?? Date())
            return calendar.dateComponents([.day], from: start, to: prayer.date).day ?? 0
        }
        if let encoded = try? JSONEncoder().encode(Set(prayedDayNumbers)) {
            UserDefaults.standard.set(encoded, forKey: "prayedDays")
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
}

// Grille complète 90 jours avec légende
struct FullNinetyDayGrid: View {
    let prayedCount: Int
    @AppStorage("prayedDays") private var prayedDaysData: Data = Data()

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
                Text("30 Day Journey")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.amenaText)
                Spacer()
                Text("\(Int(percent * 100))% Complete")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Prayer")
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

            Text(prayer.preview)
                .font(.system(size: 15))
                .foregroundColor(Color.amenaText)
                .lineSpacing(4)
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
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.amenaPrimary.opacity(0.4))
            Text("Your prayer journey starts here")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.amenaText)
            Text("Your daily prayers will appear here.\nStart praying to fill your journal!")
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
